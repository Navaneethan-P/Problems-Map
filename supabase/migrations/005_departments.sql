-- Migration 005: Departments and Routing Rules

-- ─────────────────────────────────────────────
-- Departments
-- These are organizational units that own issue resolution.
-- They are configurable — not hard-coded government entities.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Department Routing Rules
-- Maps (category + optional geography level) → department
-- Rules are evaluated in priority order.
-- Allows admin-configurable routing without code changes.
-- ─────────────────────────────────────────────
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
