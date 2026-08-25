-- Migration 003: Administrative Geography Tables
-- Supports the full hierarchy: Country → State → District → Taluk → Municipality → Ward → Constituency
--
-- IMPORTANT: geometry columns store official boundary polygons.
-- For demo/development, approximate bounding polygons are used and clearly labeled with is_demo_data = true.
-- Production deployments should import official survey datasets.

-- ─────────────────────────────────────────────
-- Countries
-- ─────────────────────────────────────────────
CREATE TABLE public.countries (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  iso_code        CHAR(2) NOT NULL UNIQUE,
  geometry        GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_countries_geometry ON public.countries USING GIST (geometry);

-- ─────────────────────────────────────────────
-- States / Provinces
-- ─────────────────────────────────────────────
CREATE TABLE public.states (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  country_id      UUID NOT NULL REFERENCES public.countries(id),
  name            TEXT NOT NULL,
  code            TEXT,
  geometry        GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_states_country ON public.states (country_id);
CREATE INDEX idx_states_geometry ON public.states USING GIST (geometry);

-- ─────────────────────────────────────────────
-- Districts
-- ─────────────────────────────────────────────
CREATE TABLE public.districts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  state_id        UUID NOT NULL REFERENCES public.states(id),
  name            TEXT NOT NULL,
  code            TEXT,
  geometry        GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_districts_state ON public.districts (state_id);
CREATE INDEX idx_districts_geometry ON public.districts USING GIST (geometry);

-- ─────────────────────────────────────────────
-- Taluks / Tehsils
-- ─────────────────────────────────────────────
CREATE TABLE public.taluks (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  district_id     UUID NOT NULL REFERENCES public.districts(id),
  name            TEXT NOT NULL,
  geometry        GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_taluks_district ON public.taluks (district_id);
CREATE INDEX idx_taluks_geometry ON public.taluks USING GIST (geometry);

-- ─────────────────────────────────────────────
-- Municipalities / Panchayats / Urban Local Bodies
-- ─────────────────────────────────────────────
CREATE TABLE public.municipalities (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  district_id     UUID NOT NULL REFERENCES public.districts(id),
  taluk_id        UUID REFERENCES public.taluks(id),
  name            TEXT NOT NULL,
  municipality_type TEXT, -- e.g., 'Corporation', 'Municipality', 'Panchayat'
  geometry        GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_municipalities_district ON public.municipalities (district_id);
CREATE INDEX idx_municipalities_geometry ON public.municipalities USING GIST (geometry);

-- ─────────────────────────────────────────────
-- Wards (sub-unit of municipalities)
-- ─────────────────────────────────────────────
CREATE TABLE public.wards (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  municipality_id UUID NOT NULL REFERENCES public.municipalities(id),
  name            TEXT NOT NULL,
  ward_number     TEXT,
  geometry        GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wards_municipality ON public.wards (municipality_id);
CREATE INDEX idx_wards_geometry ON public.wards USING GIST (geometry);

-- ─────────────────────────────────────────────
-- Constituencies (electoral; can cross ward/taluk lines)
-- ─────────────────────────────────────────────
CREATE TABLE public.constituencies (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  state_id            UUID NOT NULL REFERENCES public.states(id),
  district_id         UUID REFERENCES public.districts(id),
  name                TEXT NOT NULL,
  constituency_type   TEXT, -- 'Assembly', 'Parliamentary'
  geometry            GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data        BOOLEAN NOT NULL DEFAULT false,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_constituencies_state ON public.constituencies (state_id);
CREATE INDEX idx_constituencies_district ON public.constituencies (district_id);
CREATE INDEX idx_constituencies_geometry ON public.constituencies USING GIST (geometry);
