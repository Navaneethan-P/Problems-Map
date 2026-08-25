-- Migration 009: Workflow Tables
-- All business-logic state changes use explicit server functions (not triggers).
-- These tables record the results of those functions.

-- ─────────────────────────────────────────────
-- Issue Status History (append-only)
-- Every status transition is recorded here.
-- Never UPDATE or DELETE rows in this table.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Issue Assignments
-- Records who assigned what to whom, when, and with what deadline.
-- Multiple assignment rows can exist (routing corrections are preserved in history).
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Issue Responses (officer/admin communications)
-- PUBLIC_RESPONSE: visible to all who can view the issue
-- INTERNAL_NOTE: RLS enforces invisibility to citizens — NOT just hidden in UI
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Issue Resolution Evidence
-- Officers must submit structured evidence before resolution.
-- The resolution workflow requires at least one evidence record.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Issue Duplicates
-- Records the master-supporting relationship between issues.
-- V1: citizen manually links their report to an existing master.
-- The first report at a location is promoted to master by admin/officer.
-- ─────────────────────────────────────────────
CREATE TABLE public.issue_duplicates (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  master_issue_id UUID NOT NULL REFERENCES public.issues(id),
  child_issue_id  UUID NOT NULL REFERENCES public.issues(id),
  linked_by       UUID NOT NULL REFERENCES public.profiles(id),  -- who confirmed the link
  link_reason     TEXT,                                            -- why they linked it
  similarity_score NUMERIC(5, 4),                                 -- 0.0–1.0, from duplicate detector
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_duplicate_pair UNIQUE (master_issue_id, child_issue_id),
  CONSTRAINT no_self_duplicate CHECK (master_issue_id <> child_issue_id)
);

CREATE INDEX idx_duplicates_master ON public.issue_duplicates (master_issue_id);
CREATE INDEX idx_duplicates_child  ON public.issue_duplicates (child_issue_id);

-- ─────────────────────────────────────────────
-- SLA Rules (scaffolded for V1.5 — table exists but not enforced in V1)
-- ─────────────────────────────────────────────
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
