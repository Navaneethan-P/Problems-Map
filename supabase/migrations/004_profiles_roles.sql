-- Migration 004: Profiles, Roles, and RBAC
-- Profiles are automatically created on auth.users insert via trigger.
-- Roles use both the simple user_role enum on profiles (fast lookup)
-- and a relational user_roles table (for multi-role / jurisdiction-scoped assignment).

-- ─────────────────────────────────────────────
-- Profiles
-- Extends auth.users — never duplicate auth data here
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Jurisdiction-scoped role assignments
-- Allows an OFFICER to be scoped to a specific department+district,
-- or an MLA to be scoped to a constituency.
-- ─────────────────────────────────────────────
CREATE TABLE public.user_role_assignments (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role                public.user_role NOT NULL,
  -- Geographic scope (all nullable — null means no restriction at that level)
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

-- ─────────────────────────────────────────────
-- Auto-create profile when a user registers via Supabase Auth
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Helper: get the authenticated user's role (used in RLS policies)
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- ─────────────────────────────────────────────
-- Helper: check if current user has minimum role level
-- Role hierarchy: CITIZEN < VERIFIER < OFFICER < MLA < DISTRICT_ADMIN < STATE_ADMIN < SUPER_ADMIN
-- ─────────────────────────────────────────────
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
