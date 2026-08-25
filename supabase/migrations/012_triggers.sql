-- Migration 012: Triggers
-- Only simple invariant triggers. Business logic stays in application layer.
-- See: lib/workflow/*.ts for changeIssueStatus(), assignIssue(), etc.

-- ─────────────────────────────────────────────
-- updated_at auto-update trigger function
-- Applied to all tables that have an updated_at column.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Prevent any modification of audit_logs rows
-- The audit trail must be immutable once written.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Prevent modification of status history rows
-- Status history is also append-only.
-- ─────────────────────────────────────────────
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
