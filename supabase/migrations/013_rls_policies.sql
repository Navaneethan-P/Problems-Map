-- Migration 013: Row Level Security Policies
-- RLS is ALWAYS ON. Never bypass with service role in normal request paths.
-- Every table that holds user or issue data has explicit policies.
-- The admin.ts client (service-role) is only for isolated trusted operations.
--
-- Security gate automated tests in tests/security/rls.test.ts verify:
--   ✓ Citizen A cannot read Citizen B's private data
--   ✓ Citizen A cannot modify Citizen B's issue
--   ✓ Citizen cannot access internal officer notes
--   ✓ Officer A cannot access unauthorized jurisdiction
--   ✓ Citizen cannot upload into another user's storage path
--   ✓ Citizen cannot change role through API

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

-- ═══════════════════════════════════════════════════════
-- GEOGRAPHY TABLES: Public read, admin write
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- DEPARTMENTS: Public read, admin write
-- ═══════════════════════════════════════════════════════
CREATE POLICY "departments_public_read" ON public.departments FOR SELECT USING (true);
CREATE POLICY "departments_admin_write" ON public.departments FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "routing_rules_officer_read" ON public.department_routing_rules FOR SELECT
  USING (public.has_role_at_least('OFFICER'));
CREATE POLICY "routing_rules_admin_write" ON public.department_routing_rules FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

-- ═══════════════════════════════════════════════════════
-- CATEGORIES & TAGS: Public read, admin write
-- ═══════════════════════════════════════════════════════
CREATE POLICY "categories_public_read" ON public.categories FOR SELECT USING (true);
CREATE POLICY "categories_admin_write" ON public.categories FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

CREATE POLICY "tags_public_read" ON public.tags FOR SELECT USING (true);
CREATE POLICY "tags_authenticated_insert" ON public.tags FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- ═══════════════════════════════════════════════════════
-- PROFILES: Own profile read/write; officers+ see limited public info
-- ═══════════════════════════════════════════════════════
CREATE POLICY "profiles_own_read" ON public.profiles FOR SELECT
  USING (id = auth.uid() OR public.has_role_at_least('OFFICER'));

CREATE POLICY "profiles_own_update" ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    -- Citizens cannot change their own role
    id = auth.uid()
    AND (
      public.has_role_at_least('SUPER_ADMIN')
      OR (role = (SELECT role FROM public.profiles WHERE id = profiles.id))
    )
  );

CREATE POLICY "profiles_admin_update" ON public.profiles FOR UPDATE
  USING (public.has_role_at_least('SUPER_ADMIN'));

-- ═══════════════════════════════════════════════════════
-- USER ROLE ASSIGNMENTS: Admin only
-- ═══════════════════════════════════════════════════════
CREATE POLICY "role_assignments_officer_read" ON public.user_role_assignments FOR SELECT
  USING (user_id = auth.uid() OR public.has_role_at_least('DISTRICT_ADMIN'));
CREATE POLICY "role_assignments_admin_write" ON public.user_role_assignments FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

-- ═══════════════════════════════════════════════════════
-- ISSUES: Core access control
-- ═══════════════════════════════════════════════════════

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
    AND priority = (SELECT priority FROM public.issues WHERE id = issues.id)
  );

-- Officers can update issues they own (workflow fields only — enforced by API layer too)
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

-- ═══════════════════════════════════════════════════════
-- ISSUE MEDIA
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- VOTES & FOLLOWERS
-- ═══════════════════════════════════════════════════════
CREATE POLICY "votes_public_read" ON public.issue_votes FOR SELECT USING (true);
CREATE POLICY "votes_own_write" ON public.issue_votes FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND auth.uid() IS NOT NULL);

CREATE POLICY "followers_public_read" ON public.issue_followers FOR SELECT USING (true);
CREATE POLICY "followers_own_write" ON public.issue_followers FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid() AND auth.uid() IS NOT NULL);

-- ═══════════════════════════════════════════════════════
-- ISSUE REPORTS (abuse)
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- ISSUE TAGS
-- ═══════════════════════════════════════════════════════
CREATE POLICY "issue_tags_public_read" ON public.issue_tags FOR SELECT USING (true);
CREATE POLICY "issue_tags_citizen_write" ON public.issue_tags FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- ═══════════════════════════════════════════════════════
-- STATUS HISTORY: Read-only for authorized parties
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- ASSIGNMENTS
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- RESPONSES: PUBLIC_RESPONSE visible to all; INTERNAL_NOTE only to officers+
-- This is RLS-level enforcement — never rely on UI hiding.
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- RESOLUTION EVIDENCE
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- DUPLICATES
-- ═══════════════════════════════════════════════════════
CREATE POLICY "duplicates_public_read" ON public.issue_duplicates FOR SELECT USING (true);
CREATE POLICY "duplicates_citizen_insert" ON public.issue_duplicates FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND linked_by = auth.uid()
  );
CREATE POLICY "duplicates_admin_delete" ON public.issue_duplicates FOR DELETE
  USING (public.has_role_at_least('OFFICER'));

-- ═══════════════════════════════════════════════════════
-- SLA RULES: Public read; admin write
-- ═══════════════════════════════════════════════════════
CREATE POLICY "sla_rules_officer_read" ON public.sla_rules FOR SELECT
  USING (public.has_role_at_least('OFFICER'));
CREATE POLICY "sla_rules_admin_write" ON public.sla_rules FOR ALL
  USING (public.has_role_at_least('DISTRICT_ADMIN'));

-- ═══════════════════════════════════════════════════════
-- AUDIT LOGS: Append-only, officers can read their entity's logs
-- ═══════════════════════════════════════════════════════
CREATE POLICY "audit_logs_officer_read" ON public.audit_logs FOR SELECT
  USING (
    actor_id = auth.uid()
    OR public.has_role_at_least('OFFICER')
  );

-- No UPDATE or DELETE allowed (triggers enforce this too)
-- INSERT is allowed by any authenticated server action (via service role in admin.ts)

-- ═══════════════════════════════════════════════════════
-- NOTIFICATIONS: Own notifications only
-- ═══════════════════════════════════════════════════════
CREATE POLICY "notifications_own_read" ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "notifications_own_update" ON public.notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "notification_prefs_own" ON public.notification_preferences FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
