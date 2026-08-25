-- Migration 007: Core Issues Table
-- The central record of the platform. Every field has a documented purpose.
-- Corrections applied:
--   - location_confidence (not authenticity_score)
--   - verification_method (new enum)
--   - version_number for optimistic concurrency
--   - suggested vs responsible department/officer distinction
--   - reopened_at + reopen_count
--   - rejection_reason (structured enum)
--   - issue_source enum
--   - parent_issue_id + is_master for master-issue model
--   - supporting_count removed (calculated via COUNT to avoid counter gremlins)

CREATE TABLE public.issues (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- ─── Reporter ────────────────────────────
  reporter_id           UUID NOT NULL REFERENCES public.profiles(id),
  issue_source          public.issue_source NOT NULL DEFAULT 'CITIZEN',

  -- ─── Content ────────────────────────────
  title                 TEXT NOT NULL CHECK (char_length(title) BETWEEN 5 AND 200),
  description           TEXT NOT NULL CHECK (char_length(description) BETWEEN 10 AND 5000),
  category_id           UUID REFERENCES public.categories(id),

  -- ─── Status & Priority ──────────────────
  status                public.issue_status NOT NULL DEFAULT 'DRAFT',
  priority              public.issue_priority NOT NULL DEFAULT 'NORMAL',

  -- ─── Location (PostGIS) ─────────────────
  -- location is the authoritative spatial point
  location              GEOGRAPHY(POINT, 4326),
  latitude              DOUBLE PRECISION NOT NULL,
  longitude             DOUBLE PRECISION NOT NULL,
  gps_accuracy          DOUBLE PRECISION,            -- meters, from browser GPS API
  location_confidence   public.location_confidence,  -- calculated signal, not a guarantee
  capture_timestamp     TIMESTAMPTZ,                 -- when GPS was captured on device

  -- ─── Admin Geography (auto-populated via point-in-polygon) ──────────────────
  country_id            UUID REFERENCES public.countries(id),
  state_id              UUID REFERENCES public.states(id),
  district_id           UUID REFERENCES public.districts(id),
  taluk_id              UUID REFERENCES public.taluks(id),
  municipality_id       UUID REFERENCES public.municipalities(id),
  ward_id               UUID REFERENCES public.wards(id),
  constituency_id       UUID REFERENCES public.constituencies(id),

  -- ─── Department Ownership ───────────────
  -- Distinction per correction #11:
  suggested_department_id    UUID REFERENCES public.departments(id),  -- routing engine output
  responsible_department_id  UUID REFERENCES public.departments(id),  -- admin-confirmed
  suggested_officer_id       UUID REFERENCES public.profiles(id),
  assigned_officer_id        UUID REFERENCES public.profiles(id),
  jurisdiction_id            UUID,                                     -- geographic scope FK (flexible)

  -- ─── Verification ───────────────────────
  verification_status   public.verification_status NOT NULL DEFAULT 'PENDING',
  verification_method   public.verification_method,
  verified_at           TIMESTAMPTZ,
  verified_by           UUID REFERENCES public.profiles(id),

  -- ─── Rejection ──────────────────────────
  rejection_reason      public.rejection_reason,
  rejection_note        TEXT,
  rejected_at           TIMESTAMPTZ,
  rejected_by           UUID REFERENCES public.profiles(id),

  -- ─── Master Issue Model ──────────────────
  parent_issue_id       UUID REFERENCES public.issues(id),  -- this is a supporting report of a master
  is_master             BOOLEAN NOT NULL DEFAULT false,       -- is this the canonical master issue?
  -- supporting_count intentionally removed; calculate via COUNT(parent_issue_id) to avoid drift

  -- ─── Community Signal ───────────────────
  vote_count            INTEGER NOT NULL DEFAULT 0,           -- denormalized for fast sorting
  community_priority_score NUMERIC(10, 4) NOT NULL DEFAULT 0, -- weighted composite score

  -- ─── Workflow Timestamps ─────────────────
  submitted_at          TIMESTAMPTZ,
  acknowledged_at       TIMESTAMPTZ,
  in_progress_at        TIMESTAMPTZ,
  resolution_submitted_at TIMESTAMPTZ,
  resolved_at           TIMESTAMPTZ,
  reopened_at           TIMESTAMPTZ,                          -- correction #4
  reopen_count          INTEGER NOT NULL DEFAULT 0,           -- correction #4

  -- ─── Concurrency ────────────────────────
  version_number        INTEGER NOT NULL DEFAULT 1,           -- correction #14: optimistic concurrency

  -- ─── Privacy / Data classification ───────
  data_classification   public.data_classification NOT NULL DEFAULT 'PUBLIC',

  -- ─── Timestamps ─────────────────────────
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- ─── Soft delete ─────────────────────────
  deleted_at            TIMESTAMPTZ,                          -- soft delete; never hard delete issues
  deleted_by            UUID REFERENCES public.profiles(id)
);

-- ─────────────────────────────────────────────
-- Indexes — only where query patterns justify them
-- ─────────────────────────────────────────────

-- Primary spatial index
CREATE INDEX idx_issues_location         ON public.issues USING GIST (location);

-- Most common filter columns
CREATE INDEX idx_issues_status           ON public.issues (status);
CREATE INDEX idx_issues_priority         ON public.issues (priority);
CREATE INDEX idx_issues_category         ON public.issues (category_id);
CREATE INDEX idx_issues_reporter         ON public.issues (reporter_id);
CREATE INDEX idx_issues_department_resp  ON public.issues (responsible_department_id);
CREATE INDEX idx_issues_department_sugg  ON public.issues (suggested_department_id);
CREATE INDEX idx_issues_officer          ON public.issues (assigned_officer_id);
CREATE INDEX idx_issues_created          ON public.issues (created_at DESC);

-- Geography filters
CREATE INDEX idx_issues_state            ON public.issues (state_id);
CREATE INDEX idx_issues_district         ON public.issues (district_id);
CREATE INDEX idx_issues_municipality     ON public.issues (municipality_id);
CREATE INDEX idx_issues_ward             ON public.issues (ward_id);

-- Master issue lookups
CREATE INDEX idx_issues_parent           ON public.issues (parent_issue_id);
CREATE INDEX idx_issues_master           ON public.issues (is_master) WHERE is_master = true;

-- Soft delete filter (so live queries can easily exclude deleted)
CREATE INDEX idx_issues_not_deleted      ON public.issues (created_at DESC) WHERE deleted_at IS NULL;

-- Composite: status + district (common admin dashboard query)
CREATE INDEX idx_issues_status_district  ON public.issues (status, district_id);

-- Full-text search
CREATE INDEX idx_issues_fts ON public.issues
  USING GIN (to_tsvector('public.english_unaccent', title || ' ' || description));
