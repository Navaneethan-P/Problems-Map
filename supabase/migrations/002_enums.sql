-- Migration 002: All PostgreSQL Enums for Problems Map
-- These enums are referenced by tables defined in subsequent migrations.

-- ─────────────────────────────────────────────
-- Issue lifecycle status
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Issue priority
-- ─────────────────────────────────────────────
CREATE TYPE public.issue_priority AS ENUM (
  'EMERGENCY',
  'HIGH',
  'NORMAL'
);

-- ─────────────────────────────────────────────
-- User roles
-- ─────────────────────────────────────────────
CREATE TYPE public.user_role AS ENUM (
  'CITIZEN',
  'VERIFIER',
  'OFFICER',
  'MLA',
  'DISTRICT_ADMIN',
  'STATE_ADMIN',
  'SUPER_ADMIN'
);

-- ─────────────────────────────────────────────
-- Media source: was evidence captured live or uploaded later?
-- This is a signal, NOT a proof of authenticity.
-- ─────────────────────────────────────────────
CREATE TYPE public.media_source AS ENUM (
  'CAPTURED_DURING_REPORT',  -- camera opened inside app during report
  'UPLOADED'                  -- chosen from device gallery
);

-- ─────────────────────────────────────────────
-- Note/response visibility
-- RLS enforces this — never rely on client-side hiding
-- ─────────────────────────────────────────────
CREATE TYPE public.note_visibility AS ENUM (
  'PUBLIC_RESPONSE',
  'INTERNAL_NOTE'
);

-- ─────────────────────────────────────────────
-- GPS / location confidence
-- Reflects quality of location signal, NOT truthfulness of report.
-- "HIGH_CONFIDENCE" means GPS was accurate, not that the report is genuine.
-- ─────────────────────────────────────────────
CREATE TYPE public.location_confidence AS ENUM (
  'HIGH_CONFIDENCE',
  'MEDIUM_CONFIDENCE',
  'LOW_CONFIDENCE',
  'SUSPICIOUS'
);

-- ─────────────────────────────────────────────
-- How was the issue verified?
-- Multiple methods can apply to a single issue.
-- ─────────────────────────────────────────────
CREATE TYPE public.verification_method AS ENUM (
  'AUTOMATED',   -- system-level checks (location, timing)
  'COMMUNITY',   -- sufficient community prioritization / corroboration
  'OFFICER',     -- field officer visited / confirmed
  'ADMIN',       -- administrator verified
  'MIXED'        -- combination of above methods
);

-- ─────────────────────────────────────────────
-- Issue verification status (separate from location confidence)
-- ─────────────────────────────────────────────
CREATE TYPE public.verification_status AS ENUM (
  'PENDING',
  'VERIFIED',
  'REJECTED',
  'NEEDS_REVIEW'
);

-- ─────────────────────────────────────────────
-- Issue source: how did this issue enter the system?
-- SYSTEM_GENERATED excluded from V1 (conservative master-issue creation)
-- ─────────────────────────────────────────────
CREATE TYPE public.issue_source AS ENUM (
  'CITIZEN',      -- standard citizen app report
  'OFFICIAL',     -- created directly by government user
  'IMPORTED',     -- bulk import from external dataset
  'PARTNER_API'   -- future integrations
);

-- ─────────────────────────────────────────────
-- Rejection reasons (structured, for audit value)
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- SLA tracking (V1.5 — table scaffolded now, used later)
-- ─────────────────────────────────────────────
CREATE TYPE public.sla_status AS ENUM (
  'ON_TRACK',
  'DUE_SOON',
  'OVERDUE',
  'COMPLETED_WITHIN_SLA',
  'COMPLETED_AFTER_SLA'
);

-- ─────────────────────────────────────────────
-- Data classification for privacy-aware access control
-- ─────────────────────────────────────────────
CREATE TYPE public.data_classification AS ENUM (
  'PUBLIC',
  'AUTHORIZED',
  'PRIVATE',
  'SENSITIVE'
);

-- ─────────────────────────────────────────────
-- Account status
-- ─────────────────────────────────────────────
CREATE TYPE public.account_status AS ENUM (
  'ACTIVE',
  'SUSPENDED',
  'DEACTIVATED',
  'PENDING_VERIFICATION'
);
