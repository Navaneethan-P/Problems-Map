SET search_path = public, extensions, auth;
-- Migration 001: Extensions
-- Enable required PostgreSQL extensions for Problems Map

-- PostGIS: spatial data types, functions, and operators
CREATE EXTENSION IF NOT EXISTS postgis;

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Trigram similarity for duplicate text matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Accent-insensitive text search
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Full-text search configuration using unaccent
CREATE TEXT SEARCH CONFIGURATION public.english_unaccent (COPY = pg_catalog.english);
ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
  ALTER MAPPING FOR hword, hword_part, word WITH unaccent, english_stem;
-- Migration 002: All PostgreSQL Enums for Problems Map
-- These enums are referenced by tables defined in subsequent migrations.

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue lifecycle status
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.issue_status AS ENUM (
  'DRAFT',
  'SUBMITTED',
  'UNDER_REVIEW',
  'VERIFIED',
  'ASSIGNED',
  'ACKNOWLEDGED',
  'IN_PROGRESS',
  'RESOLUTION_SUBMITTED',
  'RESOLUTION_PENDING_VERIFICATION',
  'RESOLVED',
  'REOPENED',
  'REJECTED',
  'DUPLICATE',
  'OUT_OF_SCOPE'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue priority
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.issue_priority AS ENUM (
  'EMERGENCY',
  'HIGH',
  'NORMAL'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- User roles
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.user_role AS ENUM (
  'CITIZEN',
  'VERIFIER',
  'OFFICER',
  'MLA',
  'DISTRICT_ADMIN',
  'STATE_ADMIN',
  'SUPER_ADMIN'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Media source: was evidence captured live or uploaded later?
-- This is a signal, NOT a proof of authenticity.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.media_source AS ENUM (
  'CAPTURED_DURING_REPORT',  -- camera opened inside app during report
  'UPLOADED'                  -- chosen from device gallery
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Note/response visibility
-- RLS enforces this â€” never rely on client-side hiding
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.note_visibility AS ENUM (
  'PUBLIC_RESPONSE',
  'INTERNAL_NOTE'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- GPS / location confidence
-- Reflects quality of location signal, NOT truthfulness of report.
-- "HIGH_CONFIDENCE" means GPS was accurate, not that the report is genuine.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.location_confidence AS ENUM (
  'HIGH_CONFIDENCE',
  'MEDIUM_CONFIDENCE',
  'LOW_CONFIDENCE',
  'SUSPICIOUS'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- How was the issue verified?
-- Multiple methods can apply to a single issue.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.verification_method AS ENUM (
  'AUTOMATED',   -- system-level checks (location, timing)
  'COMMUNITY',   -- sufficient community prioritization / corroboration
  'OFFICER',     -- field officer visited / confirmed
  'ADMIN',       -- administrator verified
  'MIXED'        -- combination of above methods
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue verification status (separate from location confidence)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.verification_status AS ENUM (
  'PENDING',
  'VERIFIED',
  'REJECTED',
  'NEEDS_REVIEW'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue source: how did this issue enter the system?
-- SYSTEM_GENERATED excluded from V1 (conservative master-issue creation)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.issue_source AS ENUM (
  'CITIZEN',      -- standard citizen app report
  'OFFICIAL',     -- created directly by government user
  'IMPORTED',     -- bulk import from external dataset
  'PARTNER_API'   -- future integrations
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Rejection reasons (structured, for audit value)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.rejection_reason AS ENUM (
  'SPAM',
  'FALSE_REPORT',
  'INSUFFICIENT_EVIDENCE',
  'DUPLICATE',
  'WRONG_DEPARTMENT',
  'PRIVATE_PROPERTY',
  'OUTSIDE_JURISDICTION',
  'OTHER'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SLA tracking (V1.5 â€” table scaffolded now, used later)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.sla_status AS ENUM (
  'ON_TRACK',
  'DUE_SOON',
  'OVERDUE',
  'COMPLETED_WITHIN_SLA',
  'COMPLETED_AFTER_SLA'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Data classification for privacy-aware access control
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.data_classification AS ENUM (
  'PUBLIC',
  'AUTHORIZED',
  'PRIVATE',
  'SENSITIVE'
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Account status
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.account_status AS ENUM (
  'ACTIVE',
  'SUSPENDED',
  'DEACTIVATED',
  'PENDING_VERIFICATION'
);
-- Migration 003: Administrative Geography Tables
-- Supports the full hierarchy: Country â†’ State â†’ District â†’ Taluk â†’ Municipality â†’ Ward â†’ Constituency
--
-- IMPORTANT: geometry columns store official boundary polygons.
-- For demo/development, approximate bounding polygons are used and clearly labeled with is_demo_data = true.
-- Production deployments should import official survey datasets.

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Countries
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.countries (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  iso_code        CHAR(2) NOT NULL UNIQUE,
  geometry        GEOGRAPHY(MULTIPOLYGON, 4326),
  is_demo_data    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_countries_geometry ON public.countries USING GIST (geometry);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- States / Provinces
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Districts
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Taluks / Tehsils
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Municipalities / Panchayats / Urban Local Bodies
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Wards (sub-unit of municipalities)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Constituencies (electoral; can cross ward/taluk lines)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
-- Migration 004: Profiles, Roles, and RBAC
-- Profiles are automatically created on auth.users insert via trigger.
-- Roles use both the simple user_role enum on profiles (fast lookup)
-- and a relational user_roles table (for multi-role / jurisdiction-scoped assignment).

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Profiles
-- Extends auth.users â€” never duplicate auth data here
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name           TEXT,
  avatar_url          TEXT,
  phone               TEXT,
  role                public.user_role NOT NULL DEFAULT 'CITIZEN',
  account_status      public.account_status NOT NULL DEFAULT 'ACTIVE',
  -- reputation_score deferred to V1.5
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Profiles are never publicly visible beyond what the app explicitly selects.
-- RLS policy in migration 013 controls access.
CREATE INDEX idx_profiles_role ON public.profiles (role);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Jurisdiction-scoped role assignments
-- Allows an OFFICER to be scoped to a specific department+district,
-- or an MLA to be scoped to a constituency.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.user_role_assignments (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role                public.user_role NOT NULL,
  -- Geographic scope (all nullable â€” null means no restriction at that level)
  country_id          UUID REFERENCES public.countries(id),
  state_id            UUID REFERENCES public.states(id),
  district_id         UUID REFERENCES public.districts(id),
  municipality_id     UUID REFERENCES public.municipalities(id),
  constituency_id     UUID REFERENCES public.constituencies(id),
  -- Departmental scope
  department_id       UUID, -- FK added after departments table in migration 005
  -- Assignment metadata
  assigned_by         UUID REFERENCES public.profiles(id),
  assigned_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at          TIMESTAMPTZ,
  is_active           BOOLEAN NOT NULL DEFAULT true,
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_role_assignments_user ON public.user_role_assignments (user_id);
CREATE INDEX idx_user_role_assignments_department ON public.user_role_assignments (department_id);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Auto-create profile when a user registers via Supabase Auth
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    'CITIZEN'
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Helper: get the authenticated user's role (used in RLS policies)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Helper: check if current user has minimum role level
-- Role hierarchy: CITIZEN < VERIFIER < OFFICER < MLA < DISTRICT_ADMIN < STATE_ADMIN < SUPER_ADMIN
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.has_role_at_least(minimum_role public.user_role)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_role public.user_role;
  role_hierarchy TEXT[] := ARRAY[
    'CITIZEN', 'VERIFIER', 'OFFICER', 'MLA',
    'DISTRICT_ADMIN', 'STATE_ADMIN', 'SUPER_ADMIN'
  ];
  current_idx INT;
  minimum_idx INT;
BEGIN
  SELECT role INTO current_role FROM public.profiles WHERE id = auth.uid();
  IF current_role IS NULL THEN RETURN false; END IF;

  SELECT array_position(role_hierarchy, current_role::text) INTO current_idx;
  SELECT array_position(role_hierarchy, minimum_role::text) INTO minimum_idx;

  RETURN current_idx >= minimum_idx;
END;
$$;
-- Migration 005: Departments and Routing Rules

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Departments
-- These are organizational units that own issue resolution.
-- They are configurable â€” not hard-coded government entities.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.departments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  description     TEXT,
  short_code      TEXT UNIQUE,          -- e.g., 'PWD', 'ELEC', 'WATER'
  -- Geographic jurisdiction (all optional)
  country_id      UUID REFERENCES public.countries(id),
  state_id        UUID REFERENCES public.states(id),
  district_id     UUID REFERENCES public.districts(id),
  municipality_id UUID REFERENCES public.municipalities(id),
  -- Contact (stored for routing, not publicly displayed by default)
  contact_email   TEXT,
  contact_phone   TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_departments_state ON public.departments (state_id);
CREATE INDEX idx_departments_district ON public.departments (district_id);

-- Now we can add the FK from user_role_assignments.department_id
ALTER TABLE public.user_role_assignments
  ADD CONSTRAINT fk_ura_department
  FOREIGN KEY (department_id)
  REFERENCES public.departments(id);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Department Routing Rules
-- Maps (category + optional geography level) â†’ department
-- Rules are evaluated in priority order.
-- Allows admin-configurable routing without code changes.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.department_routing_rules (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department_id       UUID NOT NULL REFERENCES public.departments(id),
  -- Match conditions (all nullable = match any)
  category_id         UUID,             -- FK added after categories migration
  state_id            UUID REFERENCES public.states(id),
  district_id         UUID REFERENCES public.districts(id),
  municipality_id     UUID REFERENCES public.municipalities(id),
  -- Evaluation
  priority_order      INTEGER NOT NULL DEFAULT 100,  -- lower = evaluated first
  is_active           BOOLEAN NOT NULL DEFAULT true,
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_routing_rules_department ON public.department_routing_rules (department_id);
CREATE INDEX idx_routing_rules_category ON public.department_routing_rules (category_id);
CREATE INDEX idx_routing_rules_priority ON public.department_routing_rules (priority_order);
-- Migration 006: Categories and Tags

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Categories (hierarchical)
-- Issues are classified by category. Categories have optional parent.
-- This supports Road > Pothole, Road > Road Damage, etc.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Tags (hashtags, normalized)
-- Tag names are stored lowercase, no spaces, no special chars.
-- Prevents "RoadIssues", "roadissues", " road issues " being treated differently.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.tags (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL UNIQUE,    -- normalized: lowercase, trimmed
  display_name    TEXT NOT NULL,           -- original case for display
  use_count       INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tags_name ON public.tags (name);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue â†” Tag junction (added after issues table in migration 007)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- CREATE TABLE public.issue_tags ... (see migration 008)

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Tag normalization function
-- Called before inserting tags to prevent duplicate spellings
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.normalize_tag_name(raw_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN lower(regexp_replace(trim(raw_name), '[^a-z0-9]', '', 'g'));
END;
$$;
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

  -- â”€â”€â”€ Reporter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  reporter_id           UUID NOT NULL REFERENCES public.profiles(id),
  issue_source          public.issue_source NOT NULL DEFAULT 'CITIZEN',

  -- â”€â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  title                 TEXT NOT NULL CHECK (char_length(title) BETWEEN 5 AND 200),
  description           TEXT NOT NULL CHECK (char_length(description) BETWEEN 10 AND 5000),
  category_id           UUID REFERENCES public.categories(id),

  -- â”€â”€â”€ Status & Priority â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  status                public.issue_status NOT NULL DEFAULT 'DRAFT',
  priority              public.issue_priority NOT NULL DEFAULT 'NORMAL',

  -- â”€â”€â”€ Location (PostGIS) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  -- location is the authoritative spatial point
  location              GEOGRAPHY(POINT, 4326),
  latitude              DOUBLE PRECISION NOT NULL,
  longitude             DOUBLE PRECISION NOT NULL,
  gps_accuracy          DOUBLE PRECISION,            -- meters, from browser GPS API
  location_confidence   public.location_confidence,  -- calculated signal, not a guarantee
  capture_timestamp     TIMESTAMPTZ,                 -- when GPS was captured on device

  -- â”€â”€â”€ Admin Geography (auto-populated via point-in-polygon) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  country_id            UUID REFERENCES public.countries(id),
  state_id              UUID REFERENCES public.states(id),
  district_id           UUID REFERENCES public.districts(id),
  taluk_id              UUID REFERENCES public.taluks(id),
  municipality_id       UUID REFERENCES public.municipalities(id),
  ward_id               UUID REFERENCES public.wards(id),
  constituency_id       UUID REFERENCES public.constituencies(id),

  -- â”€â”€â”€ Department Ownership â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  -- Distinction per correction #11:
  suggested_department_id    UUID REFERENCES public.departments(id),  -- routing engine output
  responsible_department_id  UUID REFERENCES public.departments(id),  -- admin-confirmed
  suggested_officer_id       UUID REFERENCES public.profiles(id),
  assigned_officer_id        UUID REFERENCES public.profiles(id),
  jurisdiction_id            UUID,                                     -- geographic scope FK (flexible)

  -- â”€â”€â”€ Verification â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  verification_status   public.verification_status NOT NULL DEFAULT 'PENDING',
  verification_method   public.verification_method,
  verified_at           TIMESTAMPTZ,
  verified_by           UUID REFERENCES public.profiles(id),

  -- â”€â”€â”€ Rejection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  rejection_reason      public.rejection_reason,
  rejection_note        TEXT,
  rejected_at           TIMESTAMPTZ,
  rejected_by           UUID REFERENCES public.profiles(id),

  -- â”€â”€â”€ Master Issue Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  parent_issue_id       UUID REFERENCES public.issues(id),  -- this is a supporting report of a master
  is_master             BOOLEAN NOT NULL DEFAULT false,       -- is this the canonical master issue?
  -- supporting_count intentionally removed; calculate via COUNT(parent_issue_id) to avoid drift

  -- â”€â”€â”€ Community Signal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  vote_count            INTEGER NOT NULL DEFAULT 0,           -- denormalized for fast sorting
  community_priority_score NUMERIC(10, 4) NOT NULL DEFAULT 0, -- weighted composite score

  -- â”€â”€â”€ Workflow Timestamps â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  submitted_at          TIMESTAMPTZ,
  acknowledged_at       TIMESTAMPTZ,
  in_progress_at        TIMESTAMPTZ,
  resolution_submitted_at TIMESTAMPTZ,
  resolved_at           TIMESTAMPTZ,
  reopened_at           TIMESTAMPTZ,                          -- correction #4
  reopen_count          INTEGER NOT NULL DEFAULT 0,           -- correction #4

  -- â”€â”€â”€ Concurrency â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  version_number        INTEGER NOT NULL DEFAULT 1,           -- correction #14: optimistic concurrency

  -- â”€â”€â”€ Privacy / Data classification â”€â”€â”€â”€â”€â”€â”€
  data_classification   public.data_classification NOT NULL DEFAULT 'PUBLIC',

  -- â”€â”€â”€ Timestamps â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- â”€â”€â”€ Soft delete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  deleted_at            TIMESTAMPTZ,                          -- soft delete; never hard delete issues
  deleted_by            UUID REFERENCES public.profiles(id)
);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Indexes â€” only where query patterns justify them
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
-- Migration 008: Issue Media, Votes, Followers, Abuse Reports, Tags Junction

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Media
-- References Supabase Storage paths (not raw file data in Postgres)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_media (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id        UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  uploader_id     UUID NOT NULL REFERENCES public.profiles(id),

  -- Storage reference
  storage_path    TEXT NOT NULL,          -- e.g., issues/{issueId}/original/{filename}
  storage_bucket  TEXT NOT NULL DEFAULT 'issue-media',
  public_url      TEXT,                   -- cached CDN URL
  thumbnail_url   TEXT,                   -- cached thumbnail URL

  -- Media metadata
  media_type      TEXT NOT NULL,          -- 'image' | 'video'
  mime_type       TEXT NOT NULL,          -- 'image/webp', 'video/mp4', etc.
  file_size_bytes BIGINT,
  width_px        INTEGER,
  height_px       INTEGER,
  duration_secs   INTEGER,                -- for video only
  original_filename TEXT,

  -- Provenance signal (not a guarantee)
  media_source    public.media_source NOT NULL DEFAULT 'UPLOADED',
  captured_at     TIMESTAMPTZ,            -- EXIF capture time if available

  -- Ordering
  sort_order      INTEGER NOT NULL DEFAULT 0,

  -- For resolution evidence (see issue_resolution_evidence for structured version)
  is_resolution_evidence BOOLEAN NOT NULL DEFAULT false,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_issue_media_issue ON public.issue_media (issue_id);
CREATE INDEX idx_issue_media_uploader ON public.issue_media (uploader_id);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Votes (Prioritize)
-- One vote per citizen per issue.
-- Labeled "Prioritize" in UI â€” not "Like".
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_votes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_issue_votes UNIQUE (issue_id, user_id)
);

CREATE INDEX idx_issue_votes_issue ON public.issue_votes (issue_id);
CREATE INDEX idx_issue_votes_user  ON public.issue_votes (user_id);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Followers
-- Citizens can follow issues to receive status update notifications.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_followers (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_issue_followers UNIQUE (issue_id, user_id)
);

CREATE INDEX idx_issue_followers_issue ON public.issue_followers (issue_id);
CREATE INDEX idx_issue_followers_user  ON public.issue_followers (user_id);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Abuse Reports (flag for moderation)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.abuse_reason AS ENUM (
  'SPAM',
  'MISLEADING',
  'ABUSIVE',
  'ILLEGAL_CONTENT',
  'PRIVACY_VIOLATION',
  'DUPLICATE',
  'FALSE_INFORMATION',
  'OTHER'
);

CREATE TABLE public.issue_reports (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id        UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  reporter_id     UUID NOT NULL REFERENCES public.profiles(id),
  reason          public.abuse_reason NOT NULL,
  explanation     TEXT,
  resolved        BOOLEAN NOT NULL DEFAULT false,
  resolved_by     UUID REFERENCES public.profiles(id),
  resolved_at     TIMESTAMPTZ,
  resolution_note TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_issue_reports_issue    ON public.issue_reports (issue_id);
CREATE INDEX idx_issue_reports_pending  ON public.issue_reports (resolved) WHERE resolved = false;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue â†” Tag junction
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_tags (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  tag_id      UUID NOT NULL REFERENCES public.tags(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_issue_tags UNIQUE (issue_id, tag_id)
);

CREATE INDEX idx_issue_tags_issue ON public.issue_tags (issue_id);
CREATE INDEX idx_issue_tags_tag   ON public.issue_tags (tag_id);
-- Migration 009: Workflow Tables
-- All business-logic state changes use explicit server functions (not triggers).
-- These tables record the results of those functions.

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Status History (append-only)
-- Every status transition is recorded here.
-- Never UPDATE or DELETE rows in this table.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_status_history (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id        UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  from_status     public.issue_status,          -- NULL for initial DRAFT creation
  to_status       public.issue_status NOT NULL,
  changed_by      UUID NOT NULL REFERENCES public.profiles(id),
  reason          TEXT,                          -- required for sensitive transitions
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_status_history_issue   ON public.issue_status_history (issue_id);
CREATE INDEX idx_status_history_created ON public.issue_status_history (created_at DESC);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Assignments
-- Records who assigned what to whom, when, and with what deadline.
-- Multiple assignment rows can exist (routing corrections are preserved in history).
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_assignments (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id              UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  department_id         UUID NOT NULL REFERENCES public.departments(id),
  officer_id            UUID REFERENCES public.profiles(id),
  assigned_by           UUID NOT NULL REFERENCES public.profiles(id),
  assignment_notes      TEXT,
  deadline              TIMESTAMPTZ,
  is_active             BOOLEAN NOT NULL DEFAULT true,  -- false = superseded by newer assignment
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_assignments_issue      ON public.issue_assignments (issue_id);
CREATE INDEX idx_assignments_department ON public.issue_assignments (department_id);
CREATE INDEX idx_assignments_officer    ON public.issue_assignments (officer_id);
CREATE INDEX idx_assignments_active     ON public.issue_assignments (issue_id) WHERE is_active = true;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Responses (officer/admin communications)
-- PUBLIC_RESPONSE: visible to all who can view the issue
-- INTERNAL_NOTE: RLS enforces invisibility to citizens â€” NOT just hidden in UI
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_responses (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id        UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  author_id       UUID NOT NULL REFERENCES public.profiles(id),
  department_id   UUID REFERENCES public.departments(id),  -- which dept posted this
  visibility      public.note_visibility NOT NULL DEFAULT 'PUBLIC_RESPONSE',
  content         TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 10000),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_responses_issue      ON public.issue_responses (issue_id);
CREATE INDEX idx_responses_visibility ON public.issue_responses (issue_id, visibility);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Resolution Evidence
-- Officers must submit structured evidence before resolution.
-- The resolution workflow requires at least one evidence record.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_resolution_evidence (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id            UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  submitted_by        UUID NOT NULL REFERENCES public.profiles(id),
  department_id       UUID REFERENCES public.departments(id),

  -- Evidence content
  work_description    TEXT NOT NULL CHECK (char_length(work_description) BETWEEN 10 AND 5000),
  field_report        TEXT,

  -- Before/after media references (Supabase Storage paths)
  before_media_path   TEXT,
  after_media_path    TEXT,
  document_path       TEXT,              -- official documents, completion reports

  -- Location where resolution work was done (optional)
  resolution_latitude  DOUBLE PRECISION,
  resolution_longitude DOUBLE PRECISION,
  resolution_location  GEOGRAPHY(POINT, 4326),

  -- Verification
  verified_by         UUID REFERENCES public.profiles(id),
  verified_at         TIMESTAMPTZ,
  verification_notes  TEXT,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_resolution_evidence_issue ON public.issue_resolution_evidence (issue_id);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Issue Duplicates
-- Records the master-supporting relationship between issues.
-- V1: citizen manually links their report to an existing master.
-- The first report at a location is promoted to master by admin/officer.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.issue_duplicates (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  master_issue_id UUID NOT NULL REFERENCES public.issues(id),
  child_issue_id  UUID NOT NULL REFERENCES public.issues(id),
  linked_by       UUID NOT NULL REFERENCES public.profiles(id),  -- who confirmed the link
  link_reason     TEXT,                                            -- why they linked it
  similarity_score NUMERIC(5, 4),                                 -- 0.0â€“1.0, from duplicate detector
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_duplicate_pair UNIQUE (master_issue_id, child_issue_id),
  CONSTRAINT no_self_duplicate CHECK (master_issue_id <> child_issue_id)
);

CREATE INDEX idx_duplicates_master ON public.issue_duplicates (master_issue_id);
CREATE INDEX idx_duplicates_child  ON public.issue_duplicates (child_issue_id);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SLA Rules (scaffolded for V1.5 â€” table exists but not enforced in V1)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.sla_rules (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department_id           UUID REFERENCES public.departments(id),
  category_id             UUID REFERENCES public.categories(id),
  priority                public.issue_priority,
  acknowledgement_hours   INTEGER NOT NULL DEFAULT 24,
  resolution_hours        INTEGER NOT NULL DEFAULT 168,  -- 7 days
  is_active               BOOLEAN NOT NULL DEFAULT true,
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sla_rules_department ON public.sla_rules (department_id);
CREATE INDEX idx_sla_rules_priority   ON public.sla_rules (priority);
-- Migration 010: Audit Logs and Notifications

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Audit Logs (append-only â€” no UPDATE, no DELETE)
-- Every significant action in the system is logged here.
-- The RLS policy MUST prevent any user from modifying these rows.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.audit_logs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Who did it
  actor_id        UUID REFERENCES public.profiles(id),    -- NULL for system actions
  actor_role      public.user_role,                        -- snapshot at time of action
  -- What was affected
  entity_type     TEXT NOT NULL,                           -- 'issue', 'assignment', 'profile', etc.
  entity_id       UUID NOT NULL,
  -- What happened
  action          TEXT NOT NULL,                           -- 'STATUS_CHANGED', 'ASSIGNED', 'REJECTED', etc.
  old_value       JSONB,                                   -- previous state (redact PII if needed)
  new_value       JSONB,                                   -- new state
  -- Why
  reason          TEXT,
  -- Extra context
  metadata        JSONB,                                   -- IP, device fingerprint signals, etc.
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prevent anyone (including service role) from updating/deleting audit logs.
-- This is enforced both here and in RLS.
CREATE INDEX idx_audit_entity        ON public.audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_actor         ON public.audit_logs (actor_id);
CREATE INDEX idx_audit_action        ON public.audit_logs (action);
CREATE INDEX idx_audit_created       ON public.audit_logs (created_at DESC);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Notifications
-- In-app notifications. Architecture supports future push/email/SMS.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TYPE public.notification_type AS ENUM (
  'ISSUE_SUBMITTED',
  'ISSUE_VERIFIED',
  'DUPLICATE_DETECTED',
  'ISSUE_ASSIGNED',
  'ISSUE_ACKNOWLEDGED',
  'ISSUE_IN_PROGRESS',
  'OFFICIAL_RESPONSE',
  'STATUS_CHANGED',
  'RESOLUTION_SUBMITTED',
  'RESOLUTION_VERIFIED',
  'ISSUE_RESOLVED',
  'ISSUE_REOPENED',
  'ISSUE_REJECTED',
  'MODERATION_ACTION',
  'SYSTEM'
);

CREATE TABLE public.notifications (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type            public.notification_type NOT NULL,
  title           TEXT NOT NULL,
  message         TEXT NOT NULL,
  -- Associated entity
  issue_id        UUID REFERENCES public.issues(id) ON DELETE SET NULL,
  entity_type     TEXT,
  entity_id       UUID,
  -- State
  is_read         BOOLEAN NOT NULL DEFAULT false,
  read_at         TIMESTAMPTZ,
  -- Future delivery channels (scaffolded)
  push_sent       BOOLEAN NOT NULL DEFAULT false,
  email_sent      BOOLEAN NOT NULL DEFAULT false,
  sms_sent        BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user    ON public.notifications (user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_issue   ON public.notifications (issue_id);
CREATE INDEX idx_notifications_unread  ON public.notifications (user_id) WHERE is_read = false;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Notification Preferences (per user)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE public.notification_preferences (
  user_id             UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- In-app
  in_app_enabled      BOOLEAN NOT NULL DEFAULT true,
  -- Future channels
  email_enabled       BOOLEAN NOT NULL DEFAULT false,
  push_enabled        BOOLEAN NOT NULL DEFAULT false,
  sms_enabled         BOOLEAN NOT NULL DEFAULT false,
  -- Per-event overrides (JSON map of notification_type â†’ boolean)
  overrides           JSONB NOT NULL DEFAULT '{}',
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Migration 011: Database Functions for GIS, Duplicate Detection, and Routing
-- These are SQL functions called from server Route Handlers.
-- Business logic lives in the application layer; these functions are query helpers.

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Bounding-box query for map viewport
-- Used by: GET /api/issues/map?bbox=west,south,east,north
-- Returns lightweight issue markers (not full records)
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    AND ST_Intersects(
      i.location,
      ST_MakeEnvelope(west, south, east, north, 4326)::geography
    )
    AND (p_status IS NULL OR i.status = ANY(p_status))
    AND (p_priority IS NULL OR i.priority = ANY(p_priority))
    AND (p_category_id IS NULL OR i.category_id = p_category_id)
    AND (p_department_id IS NULL OR i.responsible_department_id = p_department_id)
  ORDER BY i.community_priority_score DESC, i.created_at DESC
  LIMIT p_limit;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Nearby issues by radius
-- Used by: GET /api/issues/nearby?lat=&lng=&radius=
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Duplicate candidate finder
-- Called when a new issue is submitted to find possible duplicates.
-- Returns candidates ordered by combined score (distance + text similarity + category match).
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Auto-classify geography from GPS coordinate
-- Returns the administrative hierarchy for a lat/lng point.
-- Uses point-in-polygon against all geography tables.
-- For demo data, approximate polygons are used (labeled is_demo_data=true).
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    WHERE ST_Intersects(v_point, geometry)
    LIMIT 1;

  SELECT id INTO v_state_id
    FROM public.states
    WHERE ST_Intersects(v_point, geometry)
    LIMIT 1;

  SELECT id INTO v_district_id
    FROM public.districts
    WHERE ST_Intersects(v_point, geometry)
    LIMIT 1;

  SELECT id INTO v_taluk_id
    FROM public.taluks
    WHERE ST_Intersects(v_point, geometry)
    LIMIT 1;

  SELECT id INTO v_municipality_id
    FROM public.municipalities
    WHERE ST_Intersects(v_point, geometry)
    LIMIT 1;

  SELECT id INTO v_ward_id
    FROM public.wards
    WHERE ST_Intersects(v_point, geometry)
    LIMIT 1;

  SELECT id INTO v_constituency_id
    FROM public.constituencies
    WHERE ST_Intersects(v_point, geometry)
    LIMIT 1;

  RETURN QUERY SELECT
    v_country_id, v_state_id, v_district_id,
    v_taluk_id, v_municipality_id, v_ward_id, v_constituency_id;
END;
$$;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Department routing
-- Given a category and optional geography, find the best matching department.
-- Routing rules are ordered by priority_order (lower = first evaluated).
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Community priority score calculation
-- Formula: log(votes + 1) * age_decay * priority_weight
-- Configurable: adjust weights via constants below.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  age_decay := EXP(-0.0231 * age_days);  -- ln(2)/30 â‰ˆ 0.0231

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

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Full-text search
-- Used by: GET /api/issues/search?q=...
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
-- Migration 012: Triggers
-- Only simple invariant triggers. Business logic stays in application layer.
-- See: lib/workflow/*.ts for changeIssueStatus(), assignIssue(), etc.

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- updated_at auto-update trigger function
-- Applied to all tables that have an updated_at column.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Apply to all relevant tables
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_departments_updated_at
  BEFORE UPDATE ON public.departments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_routing_rules_updated_at
  BEFORE UPDATE ON public.department_routing_rules
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_issues_updated_at
  BEFORE UPDATE ON public.issues
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_assignments_updated_at
  BEFORE UPDATE ON public.issue_assignments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_responses_updated_at
  BEFORE UPDATE ON public.issue_responses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_sla_rules_updated_at
  BEFORE UPDATE ON public.sla_rules
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_user_role_assignments_updated_at
  BEFORE UPDATE ON public.user_role_assignments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_notification_prefs_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Prevent any modification of audit_logs rows
-- The audit trail must be immutable once written.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.prevent_audit_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'Audit logs are immutable and cannot be modified or deleted.';
END;
$$;

CREATE TRIGGER trg_audit_logs_no_update
  BEFORE UPDATE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_modification();

CREATE TRIGGER trg_audit_logs_no_delete
  BEFORE DELETE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_modification();

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Prevent modification of status history rows
-- Status history is also append-only.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.prevent_history_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'Status history is immutable and cannot be modified or deleted.';
END;
$$;

CREATE TRIGGER trg_status_history_no_update
  BEFORE UPDATE ON public.issue_status_history
  FOR EACH ROW EXECUTE FUNCTION public.prevent_history_modification();

CREATE TRIGGER trg_status_history_no_delete
  BEFORE DELETE ON public.issue_status_history
  FOR EACH ROW EXECUTE FUNCTION public.prevent_history_modification();
-- Migration 013: Row Level Security Policies
-- RLS is ALWAYS ON. Never bypass with service role in normal request paths.
-- Every table that holds user or issue data has explicit policies.
-- The admin.ts client (service-role) is only for isolated trusted operations.
--
-- Security gate automated tests in tests/security/rls.test.ts verify:
--   âœ“ Citizen A cannot read Citizen B's private data
--   âœ“ Citizen A cannot modify Citizen B's issue
--   âœ“ Citizen cannot access internal officer notes
--   âœ“ Officer A cannot access unauthorized jurisdiction
--   âœ“ Citizen cannot upload into another user's storage path
--   âœ“ Citizen cannot change role through API

-- Enable RLS on all tables
ALTER TABLE public.profiles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_role_assignments    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.countries                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.states                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.districts                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.taluks                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.municipalities           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wards                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.constituencies           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.department_routing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issues                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_media              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_votes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_followers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_reports            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_tags               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_status_history     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_assignments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_responses          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_resolution_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issue_duplicates         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sla_rules                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- GEOGRAPHY TABLES: Public read, admin write
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "geography_public_read" ON public.countries FOR SELECT USING (true);
CREATE POLICY "geography_admin_write" ON public.countries FOR ALL
  USING (public.has_role_at_least('STATE_ADMIN'));

CREATE POLICY "states_public_read" ON public.states FOR SELECT USING (true);
CREATE POLICY "states_admin_write" ON public.states FOR ALL
  USING (public.has_role_at_least('STATE_ADMIN'));

CREATE POLICY "districts_public_read" ON public.districts FOR SELECT USING (true);
CREATE POLICY "districts_admin_write" ON public.districts FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "taluks_public_read" ON public.taluks FOR SELECT USING (true);
CREATE POLICY "taluks_admin_write" ON public.taluks FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "municipalities_public_read" ON public.municipalities FOR SELECT USING (true);
CREATE POLICY "municipalities_admin_write" ON public.municipalities FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "wards_public_read" ON public.wards FOR SELECT USING (true);
CREATE POLICY "wards_admin_write" ON public.wards FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "constituencies_public_read" ON public.constituencies FOR SELECT USING (true);
CREATE POLICY "constituencies_admin_write" ON public.constituencies FOR ALL
  USING (public.has_role_at_least('STATE_ADMIN'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- DEPARTMENTS: Public read, admin write
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "departments_public_read" ON public.departments FOR SELECT USING (true);
CREATE POLICY "departments_admin_write" ON public.departments FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "routing_rules_officer_read" ON public.department_routing_rules FOR SELECT
  USING (public.has_role_at_least('OFFICER'));
CREATE POLICY "routing_rules_admin_write" ON public.department_routing_rules FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- CATEGORIES & TAGS: Public read, admin write
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "categories_public_read" ON public.categories FOR SELECT USING (true);
CREATE POLICY "categories_admin_write" ON public.categories FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "tags_public_read" ON public.tags FOR SELECT USING (true);
CREATE POLICY "tags_authenticated_insert" ON public.tags FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- PROFILES: Own profile read/write; officers+ see limited public info
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "profiles_own_read" ON public.profiles FOR SELECT
  USING (id = auth.uid() OR public.has_role_at_least('OFFICER'));

CREATE POLICY "profiles_own_update" ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    -- Citizens cannot change their own role
    id = auth.uid()
    AND (
      public.has_role_at_least('SUPER_ADMIN')
      OR (OLD.role = NEW.role)  -- role field unchanged
    )
  );

CREATE POLICY "profiles_admin_update" ON public.profiles FOR UPDATE
  USING (public.has_role_at_least('SUPER_ADMIN'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- USER ROLE ASSIGNMENTS: Admin only
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "role_assignments_officer_read" ON public.user_role_assignments FOR SELECT
  USING (user_id = auth.uid() OR public.has_role_at_least('DISTRICT_ADMIN'));
CREATE POLICY "role_assignments_admin_write" ON public.user_role_assignments FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ISSUES: Core access control
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- Public can read non-draft, non-deleted, PUBLIC issues
CREATE POLICY "issues_public_read" ON public.issues FOR SELECT
  USING (
    deleted_at IS NULL
    AND status <> 'DRAFT'
    AND data_classification = 'PUBLIC'
  );

-- Citizens can read their own drafts
CREATE POLICY "issues_own_draft_read" ON public.issues FOR SELECT
  USING (reporter_id = auth.uid());

-- Officers can read issues in their department/jurisdiction
CREATE POLICY "issues_officer_read" ON public.issues FOR SELECT
  USING (
    public.has_role_at_least('OFFICER')
    AND (
      responsible_department_id IN (
        SELECT department_id FROM public.user_role_assignments
        WHERE user_id = auth.uid() AND is_active = true
      )
      OR suggested_department_id IN (
        SELECT department_id FROM public.user_role_assignments
        WHERE user_id = auth.uid() AND is_active = true
      )
      OR assigned_officer_id = auth.uid()
    )
  );

-- State/Super admins can read all issues
CREATE POLICY "issues_admin_read" ON public.issues FOR SELECT
  USING (public.has_role_at_least('STATE_ADMIN'));

-- Citizens can create their own issues
CREATE POLICY "issues_citizen_insert" ON public.issues FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND reporter_id = auth.uid()
  );

-- Citizens can update their own DRAFT issues only
CREATE POLICY "issues_own_draft_update" ON public.issues FOR UPDATE
  USING (
    reporter_id = auth.uid()
    AND status = 'DRAFT'
  )
  WITH CHECK (
    reporter_id = auth.uid()
    -- Citizens cannot change these sensitive fields
    AND status IN ('DRAFT', 'SUBMITTED')
    AND priority = OLD.priority  -- citizens cannot set their own priority
  );

-- Officers can update issues they own (workflow fields only â€” enforced by API layer too)
CREATE POLICY "issues_officer_update" ON public.issues FOR UPDATE
  USING (
    public.has_role_at_least('OFFICER')
    AND (
      assigned_officer_id = auth.uid()
      OR responsible_department_id IN (
        SELECT department_id FROM public.user_role_assignments
        WHERE user_id = auth.uid() AND is_active = true
      )
    )
  );

-- Admins can update any issue
CREATE POLICY "issues_admin_update" ON public.issues FOR UPDATE
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ISSUE MEDIA
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "issue_media_public_read" ON public.issue_media FOR SELECT
  USING (
    NOT is_resolution_evidence
    AND issue_id IN (
      SELECT id FROM public.issues
      WHERE deleted_at IS NULL AND status <> 'DRAFT' AND data_classification = 'PUBLIC'
    )
  );

CREATE POLICY "issue_media_resolution_officer_read" ON public.issue_media FOR SELECT
  USING (
    is_resolution_evidence
    AND public.has_role_at_least('VERIFIER')
  );

CREATE POLICY "issue_media_own_read" ON public.issue_media FOR SELECT
  USING (uploader_id = auth.uid());

CREATE POLICY "issue_media_citizen_insert" ON public.issue_media FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND uploader_id = auth.uid()
  );

CREATE POLICY "issue_media_officer_insert" ON public.issue_media FOR INSERT
  WITH CHECK (
    public.has_role_at_least('OFFICER')
    AND uploader_id = auth.uid()
  );

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- VOTES & FOLLOWERS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "votes_public_read" ON public.issue_votes FOR SELECT USING (true);
CREATE POLICY "votes_own_write" ON public.issue_votes FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND auth.uid() IS NOT NULL);

CREATE POLICY "followers_public_read" ON public.issue_followers FOR SELECT USING (true);
CREATE POLICY "followers_own_write" ON public.issue_followers FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND auth.uid() IS NOT NULL);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ISSUE REPORTS (abuse)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "abuse_reports_moderator_read" ON public.issue_reports FOR SELECT
  USING (
    reporter_id = auth.uid()
    OR public.has_role_at_least('VERIFIER')
  );

CREATE POLICY "abuse_reports_citizen_insert" ON public.issue_reports FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND reporter_id = auth.uid()
  );

CREATE POLICY "abuse_reports_moderator_update" ON public.issue_reports FOR UPDATE
  USING (public.has_role_at_least('VERIFIER'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ISSUE TAGS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "issue_tags_public_read" ON public.issue_tags FOR SELECT USING (true);
CREATE POLICY "issue_tags_citizen_write" ON public.issue_tags FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- STATUS HISTORY: Read-only for authorized parties
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "status_history_public_read" ON public.issue_status_history FOR SELECT
  USING (
    issue_id IN (
      SELECT id FROM public.issues
      WHERE deleted_at IS NULL AND status <> 'DRAFT' AND data_classification = 'PUBLIC'
    )
    OR issue_id IN (SELECT id FROM public.issues WHERE reporter_id = auth.uid())
    OR public.has_role_at_least('OFFICER')
  );

CREATE POLICY "status_history_no_insert_direct" ON public.issue_status_history FOR INSERT
  WITH CHECK (public.has_role_at_least('OFFICER'));  -- API layer functions handle this

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ASSIGNMENTS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "assignments_officer_read" ON public.issue_assignments FOR SELECT
  USING (
    officer_id = auth.uid()
    OR department_id IN (
      SELECT department_id FROM public.user_role_assignments
      WHERE user_id = auth.uid() AND is_active = true
    )
    OR public.has_role_at_least('DISTRICT_ADMIN')
  );

CREATE POLICY "assignments_admin_write" ON public.issue_assignments FOR ALL
  USING (public.has_role_at_least('OFFICER'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- RESPONSES: PUBLIC_RESPONSE visible to all; INTERNAL_NOTE only to officers+
-- This is RLS-level enforcement â€” never rely on UI hiding.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "responses_public_read" ON public.issue_responses FOR SELECT
  USING (
    visibility = 'PUBLIC_RESPONSE'
    AND issue_id IN (
      SELECT id FROM public.issues WHERE deleted_at IS NULL AND status <> 'DRAFT'
    )
  );

CREATE POLICY "responses_internal_officer_read" ON public.issue_responses FOR SELECT
  USING (
    visibility = 'INTERNAL_NOTE'
    AND public.has_role_at_least('OFFICER')
  );

CREATE POLICY "responses_own_read" ON public.issue_responses FOR SELECT
  USING (author_id = auth.uid());

CREATE POLICY "responses_officer_insert" ON public.issue_responses FOR INSERT
  WITH CHECK (
    public.has_role_at_least('OFFICER')
    AND author_id = auth.uid()
  );

CREATE POLICY "responses_own_update" ON public.issue_responses FOR UPDATE
  USING (
    author_id = auth.uid()
    AND public.has_role_at_least('OFFICER')
  );

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- RESOLUTION EVIDENCE
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "resolution_evidence_public_read" ON public.issue_resolution_evidence FOR SELECT
  USING (
    verified_at IS NOT NULL  -- only show verified evidence publicly
    AND issue_id IN (
      SELECT id FROM public.issues WHERE status = 'RESOLVED'
    )
  );

CREATE POLICY "resolution_evidence_officer_read" ON public.issue_resolution_evidence FOR SELECT
  USING (public.has_role_at_least('OFFICER'));

CREATE POLICY "resolution_evidence_officer_insert" ON public.issue_resolution_evidence FOR INSERT
  WITH CHECK (
    public.has_role_at_least('OFFICER')
    AND submitted_by = auth.uid()
  );

CREATE POLICY "resolution_evidence_verifier_update" ON public.issue_resolution_evidence FOR UPDATE
  USING (public.has_role_at_least('VERIFIER'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- DUPLICATES
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "duplicates_public_read" ON public.issue_duplicates FOR SELECT USING (true);
CREATE POLICY "duplicates_citizen_insert" ON public.issue_duplicates FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND linked_by = auth.uid()
  );
CREATE POLICY "duplicates_admin_delete" ON public.issue_duplicates FOR DELETE
  USING (public.has_role_at_least('OFFICER'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- SLA RULES: Public read; admin write
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "sla_rules_officer_read" ON public.sla_rules FOR SELECT
  USING (public.has_role_at_least('OFFICER'));
CREATE POLICY "sla_rules_admin_write" ON public.sla_rules FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- AUDIT LOGS: Append-only, officers can read their entity's logs
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "audit_logs_officer_read" ON public.audit_logs FOR SELECT
  USING (
    actor_id = auth.uid()
    OR public.has_role_at_least('OFFICER')
  );

-- No UPDATE or DELETE allowed (triggers enforce this too)
-- INSERT is allowed by any authenticated server action (via service role in admin.ts)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- NOTIFICATIONS: Own notifications only
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "notifications_own_read" ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "notifications_own_update" ON public.notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "notification_prefs_own" ON public.notification_preferences FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
-- Migration 014: Storage Buckets and Storage RLS Policies
-- Supabase Storage bucket policies are separate from table RLS.
-- These policies are applied via the Supabase Storage API.
-- NOTE: Run these after creating buckets in the Supabase dashboard or via CLI.

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Create Storage Buckets
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Issue media (citizen-uploaded evidence photos/videos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'issue-media',
  'issue-media',
  true,  -- Public CDN access for approved issue media
  52428800,  -- 50MB per file
  ARRAY[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif',
    'video/mp4', 'video/webm', 'video/quicktime'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- Resolution evidence (officer-uploaded resolution proof)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'resolution-evidence',
  'resolution-evidence',
  false,  -- Not public by default; served via signed URLs
  104857600,  -- 100MB (official docs may be large)
  ARRAY[
    'image/jpeg', 'image/png', 'image/webp',
    'video/mp4', 'video/webm',
    'application/pdf'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- User avatars
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,  -- Public CDN for avatars
  5242880,  -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Storage RLS Policies: issue-media bucket
-- Path structure: issues/{issueId}/{userId}/{filename}
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Anyone can read issue media (public bucket, but policy adds extra control)
CREATE POLICY "issue_media_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'issue-media');

-- Authenticated users can upload to their own path only
CREATE POLICY "issue_media_authenticated_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'issue-media'
    AND auth.uid() IS NOT NULL
    -- Enforce path: issues/{issueId}/{userId}/{filename}
    -- User can only upload under their own user ID segment
    AND (storage.foldername(name))[3] = auth.uid()::text
  );

-- Users can delete their own uploads
CREATE POLICY "issue_media_own_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'issue-media'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[3] = auth.uid()::text
  );

-- Admins can delete any issue media
CREATE POLICY "issue_media_admin_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'issue-media'
    AND public.has_role_at_least('DISTRICT_ADMIN')
  );

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Storage RLS Policies: resolution-evidence bucket
-- Path structure: resolution/{issueId}/{officerId}/{filename}
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Officers and above can read resolution evidence
CREATE POLICY "resolution_evidence_officer_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'resolution-evidence'
    AND public.has_role_at_least('VERIFIER')
  );

-- Issue reporter can read resolution evidence for their own issues (signed URL via API)
-- (Implemented via API layer, not storage policy directly)

-- Officers can upload resolution evidence to their own path
CREATE POLICY "resolution_evidence_officer_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'resolution-evidence'
    AND public.has_role_at_least('OFFICER')
    AND (storage.foldername(name))[3] = auth.uid()::text
  );

-- Officers can delete their own resolution evidence
CREATE POLICY "resolution_evidence_officer_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'resolution-evidence'
    AND public.has_role_at_least('OFFICER')
    AND (storage.foldername(name))[3] = auth.uid()::text
  );

-- Admins can manage all resolution evidence
CREATE POLICY "resolution_evidence_admin_all"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'resolution-evidence'
    AND public.has_role_at_least('DISTRICT_ADMIN')
  );

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Storage RLS Policies: avatars bucket
-- Path structure: avatars/{userId}/{filename}
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Anyone can read avatars
CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Users can upload/update their own avatar only
CREATE POLICY "avatars_own_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_own_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_own_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
