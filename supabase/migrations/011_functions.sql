-- Migration 011: Database Functions for GIS, Duplicate Detection, and Routing
-- These are SQL functions called from server Route Handlers.
-- Business logic lives in the application layer; these functions are query helpers.

-- ─────────────────────────────────────────────
-- Bounding-box query for map viewport
-- Used by: GET /api/issues/map?bbox=west,south,east,north
-- Returns lightweight issue markers (not full records)
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_issues_in_bbox(
  west    DOUBLE PRECISION,
  south   DOUBLE PRECISION,
  east    DOUBLE PRECISION,
  north   DOUBLE PRECISION,
  p_status        public.issue_status[] DEFAULT NULL,
  p_priority      public.issue_priority[] DEFAULT NULL,
  p_category_id   UUID DEFAULT NULL,
  p_department_id UUID DEFAULT NULL,
  p_limit         INTEGER DEFAULT 500
)
RETURNS TABLE (
  id            UUID,
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  status        public.issue_status,
  priority      public.issue_priority,
  title         TEXT,
  category_id   UUID,
  vote_count    INTEGER,
  is_master     BOOLEAN,
  created_at    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    i.id,
    i.latitude,
    i.longitude,
    i.status,
    i.priority,
    i.title,
    i.category_id,
    i.vote_count,
    i.is_master,
    i.created_at
  FROM public.issues i
  WHERE
    i.deleted_at IS NULL
    AND i.status NOT IN ('DRAFT', 'REJECTED', 'OUT_OF_SCOPE')
    AND ST_Within(
      i.location::geometry,
      ST_MakeEnvelope(west, south, east, north, 4326)
    )
    AND (p_status IS NULL OR i.status = ANY(p_status))
    AND (p_priority IS NULL OR i.priority = ANY(p_priority))
    AND (p_category_id IS NULL OR i.category_id = p_category_id)
    AND (p_department_id IS NULL OR i.responsible_department_id = p_department_id)
  ORDER BY i.community_priority_score DESC, i.created_at DESC
  LIMIT p_limit;
$$;

-- ─────────────────────────────────────────────
-- Nearby issues by radius
-- Used by: GET /api/issues/nearby?lat=&lng=&radius=
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_nearby_issues(
  p_lat           DOUBLE PRECISION,
  p_lng           DOUBLE PRECISION,
  p_radius_meters DOUBLE PRECISION DEFAULT 1000,
  p_limit         INTEGER DEFAULT 20
)
RETURNS TABLE (
  id              UUID,
  title           TEXT,
  status          public.issue_status,
  priority        public.issue_priority,
  category_id     UUID,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  distance_meters DOUBLE PRECISION,
  vote_count      INTEGER,
  created_at      TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    i.id,
    i.title,
    i.status,
    i.priority,
    i.category_id,
    i.latitude,
    i.longitude,
    ST_Distance(
      i.location,
      ST_MakePoint(p_lng, p_lat)::geography
    ) AS distance_meters,
    i.vote_count,
    i.created_at
  FROM public.issues i
  WHERE
    i.deleted_at IS NULL
    AND i.status NOT IN ('DRAFT', 'REJECTED', 'OUT_OF_SCOPE')
    AND ST_DWithin(
      i.location,
      ST_MakePoint(p_lng, p_lat)::geography,
      p_radius_meters
    )
  ORDER BY distance_meters ASC
  LIMIT p_limit;
$$;

-- ─────────────────────────────────────────────
-- Duplicate candidate finder
-- Called when a new issue is submitted to find possible duplicates.
-- Returns candidates ordered by combined score (distance + text similarity + category match).
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.find_duplicate_candidates(
  p_lat             DOUBLE PRECISION,
  p_lng             DOUBLE PRECISION,
  p_title           TEXT,
  p_category_id     UUID DEFAULT NULL,
  p_radius_meters   DOUBLE PRECISION DEFAULT 200,
  p_time_window_days INTEGER DEFAULT 90,
  p_min_similarity  DOUBLE PRECISION DEFAULT 0.15,
  p_limit           INTEGER DEFAULT 5
)
RETURNS TABLE (
  id                UUID,
  title             TEXT,
  status            public.issue_status,
  priority          public.issue_priority,
  distance_meters   DOUBLE PRECISION,
  title_similarity  DOUBLE PRECISION,
  category_match    BOOLEAN,
  composite_score   DOUBLE PRECISION,
  vote_count        INTEGER,
  created_at        TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    i.id,
    i.title,
    i.status,
    i.priority,
    ST_Distance(
      i.location,
      ST_MakePoint(p_lng, p_lat)::geography
    ) AS distance_meters,
    similarity(i.title, p_title) AS title_similarity,
    (p_category_id IS NOT NULL AND i.category_id = p_category_id) AS category_match,
    -- Composite score: text similarity weighted 0.5, proximity 0.3, category match 0.2
    (
      similarity(i.title, p_title) * 0.5
      + (1.0 - LEAST(ST_Distance(i.location, ST_MakePoint(p_lng, p_lat)::geography) / p_radius_meters, 1.0)) * 0.3
      + CASE WHEN (p_category_id IS NOT NULL AND i.category_id = p_category_id) THEN 0.2 ELSE 0 END
    ) AS composite_score,
    i.vote_count,
    i.created_at
  FROM public.issues i
  WHERE
    i.deleted_at IS NULL
    AND i.status NOT IN ('DRAFT', 'REJECTED', 'OUT_OF_SCOPE', 'DUPLICATE')
    AND ST_DWithin(
      i.location,
      ST_MakePoint(p_lng, p_lat)::geography,
      p_radius_meters
    )
    AND i.created_at > NOW() - (p_time_window_days || ' days')::INTERVAL
    AND similarity(i.title, p_title) >= p_min_similarity
  ORDER BY composite_score DESC
  LIMIT p_limit;
$$;

-- ─────────────────────────────────────────────
-- Auto-classify geography from GPS coordinate
-- Returns the administrative hierarchy for a lat/lng point.
-- Uses point-in-polygon against all geography tables.
-- For demo data, approximate polygons are used (labeled is_demo_data=true).
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.classify_geography(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION
)
RETURNS TABLE (
  country_id      UUID,
  state_id        UUID,
  district_id     UUID,
  taluk_id        UUID,
  municipality_id UUID,
  ward_id         UUID,
  constituency_id UUID
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_point         GEOGRAPHY;
  v_country_id    UUID;
  v_state_id      UUID;
  v_district_id   UUID;
  v_taluk_id      UUID;
  v_municipality_id UUID;
  v_ward_id       UUID;
  v_constituency_id UUID;
BEGIN
  v_point := ST_MakePoint(p_lng, p_lat)::geography;

  SELECT id INTO v_country_id
    FROM public.countries
    WHERE ST_Within(v_point::geometry, geometry::geometry)
    LIMIT 1;

  SELECT id INTO v_state_id
    FROM public.states
    WHERE ST_Within(v_point::geometry, geometry::geometry)
    LIMIT 1;

  SELECT id INTO v_district_id
    FROM public.districts
    WHERE ST_Within(v_point::geometry, geometry::geometry)
    LIMIT 1;

  SELECT id INTO v_taluk_id
    FROM public.taluks
    WHERE ST_Within(v_point::geometry, geometry::geometry)
    LIMIT 1;

  SELECT id INTO v_municipality_id
    FROM public.municipalities
    WHERE ST_Within(v_point::geometry, geometry::geometry)
    LIMIT 1;

  SELECT id INTO v_ward_id
    FROM public.wards
    WHERE ST_Within(v_point::geometry, geometry::geometry)
    LIMIT 1;

  SELECT id INTO v_constituency_id
    FROM public.constituencies
    WHERE ST_Within(v_point::geometry, geometry::geometry)
    LIMIT 1;

  RETURN QUERY SELECT
    v_country_id, v_state_id, v_district_id,
    v_taluk_id, v_municipality_id, v_ward_id, v_constituency_id;
END;
$$;

-- ─────────────────────────────────────────────
-- Department routing
-- Given a category and optional geography, find the best matching department.
-- Routing rules are ordered by priority_order (lower = first evaluated).
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.suggest_department(
  p_category_id   UUID,
  p_state_id      UUID DEFAULT NULL,
  p_district_id   UUID DEFAULT NULL,
  p_municipality_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_department_id UUID;
BEGIN
  -- Most specific match first (category + municipality)
  SELECT department_id INTO v_department_id
    FROM public.department_routing_rules
    WHERE is_active = true
      AND (category_id IS NULL OR category_id = p_category_id)
      AND (municipality_id IS NULL OR municipality_id = p_municipality_id)
      AND (district_id IS NULL OR district_id = p_district_id)
      AND (state_id IS NULL OR state_id = p_state_id)
    ORDER BY
      (category_id IS NOT NULL)::int DESC,
      (municipality_id IS NOT NULL)::int DESC,
      (district_id IS NOT NULL)::int DESC,
      priority_order ASC
    LIMIT 1;

  RETURN v_department_id;
END;
$$;

-- ─────────────────────────────────────────────
-- Community priority score calculation
-- Formula: log(votes + 1) * age_decay * priority_weight
-- Configurable: adjust weights via constants below.
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.calculate_community_priority_score(
  p_vote_count    INTEGER,
  p_priority      public.issue_priority,
  p_created_at    TIMESTAMPTZ
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  age_days        NUMERIC;
  age_decay       NUMERIC;
  priority_weight NUMERIC;
  score           NUMERIC;
BEGIN
  age_days := EXTRACT(EPOCH FROM (NOW() - p_created_at)) / 86400.0;

  -- Exponential decay: score halves every 30 days
  age_decay := EXP(-0.0231 * age_days);  -- ln(2)/30 ≈ 0.0231

  -- Priority multiplier
  priority_weight := CASE p_priority
    WHEN 'EMERGENCY' THEN 3.0
    WHEN 'HIGH'      THEN 2.0
    WHEN 'NORMAL'    THEN 1.0
    ELSE 1.0
  END;

  score := LN(GREATEST(p_vote_count, 0) + 1) * age_decay * priority_weight;

  RETURN ROUND(score, 4);
END;
$$;

-- ─────────────────────────────────────────────
-- Full-text search
-- Used by: GET /api/issues/search?q=...
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.search_issues(
  p_query         TEXT,
  p_status        public.issue_status[] DEFAULT NULL,
  p_priority      public.issue_priority[] DEFAULT NULL,
  p_category_id   UUID DEFAULT NULL,
  p_district_id   UUID DEFAULT NULL,
  p_limit         INTEGER DEFAULT 20,
  p_offset        INTEGER DEFAULT 0
)
RETURNS TABLE (
  id              UUID,
  title           TEXT,
  description     TEXT,
  status          public.issue_status,
  priority        public.issue_priority,
  category_id     UUID,
  district_id     UUID,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  vote_count      INTEGER,
  rank            REAL,
  created_at      TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    i.id,
    i.title,
    LEFT(i.description, 300) AS description,
    i.status,
    i.priority,
    i.category_id,
    i.district_id,
    i.latitude,
    i.longitude,
    i.vote_count,
    ts_rank(
      to_tsvector('public.english_unaccent', i.title || ' ' || i.description),
      plainto_tsquery('public.english_unaccent', p_query)
    ) AS rank,
    i.created_at
  FROM public.issues i
  WHERE
    i.deleted_at IS NULL
    AND i.status NOT IN ('DRAFT')
    AND (
      p_query = ''
      OR to_tsvector('public.english_unaccent', i.title || ' ' || i.description)
         @@ plainto_tsquery('public.english_unaccent', p_query)
    )
    AND (p_status IS NULL OR i.status = ANY(p_status))
    AND (p_priority IS NULL OR i.priority = ANY(p_priority))
    AND (p_category_id IS NULL OR i.category_id = p_category_id)
    AND (p_district_id IS NULL OR i.district_id = p_district_id)
  ORDER BY
    CASE WHEN p_query <> '' THEN rank END DESC NULLS LAST,
    i.community_priority_score DESC,
    i.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;
