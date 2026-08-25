-- Migration 006: Categories and Tags

-- ─────────────────────────────────────────────
-- Categories (hierarchical)
-- Issues are classified by category. Categories have optional parent.
-- This supports Road > Pothole, Road > Road Damage, etc.
-- ─────────────────────────────────────────────
CREATE TABLE public.categories (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id       UUID REFERENCES public.categories(id),
  name            TEXT NOT NULL,
  slug            TEXT NOT NULL UNIQUE,    -- URL-safe identifier, e.g., 'road-pothole'
  description     TEXT,
  icon            TEXT,                    -- icon name from lucide or emoji
  sort_order      INTEGER NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_parent ON public.categories (parent_id);
CREATE INDEX idx_categories_slug ON public.categories (slug);

-- Now add the FK from department_routing_rules.category_id
ALTER TABLE public.department_routing_rules
  ADD CONSTRAINT fk_routing_category
  FOREIGN KEY (category_id)
  REFERENCES public.categories(id);

-- ─────────────────────────────────────────────
-- Tags (hashtags, normalized)
-- Tag names are stored lowercase, no spaces, no special chars.
-- Prevents "RoadIssues", "roadissues", " road issues " being treated differently.
-- ─────────────────────────────────────────────
CREATE TABLE public.tags (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL UNIQUE,    -- normalized: lowercase, trimmed
  display_name    TEXT NOT NULL,           -- original case for display
  use_count       INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tags_name ON public.tags (name);

-- ─────────────────────────────────────────────
-- Issue ↔ Tag junction (added after issues table in migration 007)
-- ─────────────────────────────────────────────
-- CREATE TABLE public.issue_tags ... (see migration 008)

-- ─────────────────────────────────────────────
-- Tag normalization function
-- Called before inserting tags to prevent duplicate spellings
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.normalize_tag_name(raw_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN lower(regexp_replace(trim(raw_name), '[^a-z0-9]', '', 'g'));
END;
$$;
