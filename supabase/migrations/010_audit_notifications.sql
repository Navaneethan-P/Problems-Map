-- Migration 010: Audit Logs and Notifications

-- ─────────────────────────────────────────────
-- Audit Logs (append-only — no UPDATE, no DELETE)
-- Every significant action in the system is logged here.
-- The RLS policy MUST prevent any user from modifying these rows.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Notifications
-- In-app notifications. Architecture supports future push/email/SMS.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Notification Preferences (per user)
-- ─────────────────────────────────────────────
CREATE TABLE public.notification_preferences (
  user_id             UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- In-app
  in_app_enabled      BOOLEAN NOT NULL DEFAULT true,
  -- Future channels
  email_enabled       BOOLEAN NOT NULL DEFAULT false,
  push_enabled        BOOLEAN NOT NULL DEFAULT false,
  sms_enabled         BOOLEAN NOT NULL DEFAULT false,
  -- Per-event overrides (JSON map of notification_type → boolean)
  overrides           JSONB NOT NULL DEFAULT '{}',
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
