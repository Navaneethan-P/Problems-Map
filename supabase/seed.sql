-- ============================================================
-- Problems Map — Demo Seed Data
-- ⚠️  DEMO ENVIRONMENT ONLY
-- All geographic boundaries are approximate demonstration polygons.
-- NOT official survey data. NOT real government records.
-- User credentials are for local development only.
-- ============================================================

-- ─────────────────────────────────────────────
-- Demo Users (created via Supabase Auth — IDs must match auth.users)
-- In production, create these via: supabase auth create-user
-- For local dev: these UUIDs are used by the profile inserts below.
-- Passwords are set via the Supabase Auth Admin API in seed scripts.
-- ─────────────────────────────────────────────

-- We'll use fixed UUIDs for demo users so foreign keys are stable
-- These must be inserted into auth.users first (done via the seed runner script)

DO $$
DECLARE
  -- Demo user IDs (fixed for reproducible seed)
  v_citizen_id    UUID := 'a0000000-0000-0000-0000-000000000001';
  v_officer_id    UUID := 'a0000000-0000-0000-0000-000000000002';
  v_verifier_id   UUID := 'a0000000-0000-0000-0000-000000000003';
  v_mla_id        UUID := 'a0000000-0000-0000-0000-000000000004';
  v_dist_admin_id UUID := 'a0000000-0000-0000-0000-000000000005';
  v_state_admin_id UUID := 'a0000000-0000-0000-0000-000000000006';

  -- Geography IDs
  v_india_id      UUID;
  v_tn_id         UUID;
  v_chennai_dist_id UUID;
  v_coimbatore_dist_id UUID;
  v_madurai_dist_id UUID;
  v_salem_dist_id UUID;
  v_ranipet_dist_id UUID;
  v_chennai_muni_id UUID;

  -- Department IDs
  v_pwd_id        UUID;
  v_elec_id       UUID;
  v_water_id      UUID;
  v_muni_id       UUID;
  v_drainage_id   UUID;
  v_waste_id      UUID;
  v_transport_id  UUID;
  v_health_id     UUID;

  -- Category IDs
  v_road_id       UUID;
  v_pothole_id    UUID;
  v_streetlight_id UUID;
  v_water_cat_id  UUID;
  v_drainage_cat_id UUID;
  v_garbage_id    UUID;
  v_flood_id      UUID;
  v_electricity_id UUID;

BEGIN

-- ─────────────────────────────────────────────
-- Ensure demo users exist in auth.users (trigger will create profiles)
-- ─────────────────────────────────────────────
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES 
  (v_citizen_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'citizen@demo.com', crypt('password123', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW()),
  (v_officer_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'officer@demo.com', crypt('password123', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW()),
  (v_verifier_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'verifier@demo.com', crypt('password123', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW()),
  (v_mla_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'mla@demo.com', crypt('password123', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW()),
  (v_dist_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'distadmin@demo.com', crypt('password123', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW()),
  (v_state_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'stateadmin@demo.com', crypt('password123', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────
-- Update demo user profiles (auth.users row creation triggered this)
-- ─────────────────────────────────────────────
UPDATE public.profiles SET
  full_name = 'Demo Citizen',
  role = 'CITIZEN',
  account_status = 'ACTIVE'
WHERE id = v_citizen_id;

UPDATE public.profiles SET
  full_name = 'Demo Officer (PWD)',
  role = 'OFFICER',
  account_status = 'ACTIVE'
WHERE id = v_officer_id;

UPDATE public.profiles SET
  full_name = 'Demo Verifier',
  role = 'FIELD_VERIFIER',
  account_status = 'ACTIVE'
WHERE id = v_verifier_id;

UPDATE public.profiles SET
  full_name = 'Demo MLA',
  role = 'MLA_MP',
  account_status = 'ACTIVE'
WHERE id = v_mla_id;

UPDATE public.profiles SET
  full_name = 'Demo District Admin',
  role = 'DISTRICT_ADMIN',
  account_status = 'ACTIVE'
WHERE id = v_dist_admin_id;

UPDATE public.profiles SET
  full_name = 'Demo State Admin',
  role = 'STATE_ADMIN',
  account_status = 'ACTIVE'
WHERE id = v_state_admin_id;

-- ─────────────────────────────────────────────
-- Geography: India → Tamil Nadu → 5 Districts
-- Polygons are APPROXIMATE bounding boxes for demo purposes only.
-- is_demo_data = true on all rows.
-- ─────────────────────────────────────────────
INSERT INTO public.countries (id, name, iso_code, is_demo_data)
VALUES (uuid_generate_v4(), 'India', 'IN', true)
RETURNING id INTO v_india_id;

INSERT INTO public.states (id, country_id, name, code,
  geometry, is_demo_data)
VALUES (
  uuid_generate_v4(), v_india_id, 'Tamil Nadu', 'TN',
  ST_Multi(ST_MakeEnvelope(76.23, 8.07, 80.35, 13.57, 4326))::geography,
  true
)
RETURNING id INTO v_tn_id;

INSERT INTO public.districts (id, state_id, name,
  geometry, is_demo_data)
VALUES
  (uuid_generate_v4(), v_tn_id, 'Chennai',
    ST_Multi(ST_MakeEnvelope(80.17, 12.95, 80.32, 13.23, 4326))::geography, true),
  (uuid_generate_v4(), v_tn_id, 'Coimbatore',
    ST_Multi(ST_MakeEnvelope(76.80, 10.90, 77.20, 11.20, 4326))::geography, true),
  (uuid_generate_v4(), v_tn_id, 'Madurai',
    ST_Multi(ST_MakeEnvelope(77.90, 9.80, 78.30, 10.10, 4326))::geography, true),
  (uuid_generate_v4(), v_tn_id, 'Salem',
    ST_Multi(ST_MakeEnvelope(77.90, 11.50, 78.30, 11.80, 4326))::geography, true),
  (uuid_generate_v4(), v_tn_id, 'Ranipet',
    ST_Multi(ST_MakeEnvelope(79.20, 12.80, 79.50, 13.10, 4326))::geography, true);

SELECT id INTO v_chennai_dist_id FROM public.districts WHERE name = 'Chennai' LIMIT 1;
SELECT id INTO v_coimbatore_dist_id FROM public.districts WHERE name = 'Coimbatore' LIMIT 1;
SELECT id INTO v_madurai_dist_id FROM public.districts WHERE name = 'Madurai' LIMIT 1;
SELECT id INTO v_salem_dist_id FROM public.districts WHERE name = 'Salem' LIMIT 1;
SELECT id INTO v_ranipet_dist_id FROM public.districts WHERE name = 'Ranipet' LIMIT 1;

INSERT INTO public.municipalities (id, district_id, name, municipality_type,
  geometry, is_demo_data)
VALUES (
  uuid_generate_v4(), v_chennai_dist_id,
  'Greater Chennai Corporation', 'Corporation',
  ST_Multi(ST_MakeEnvelope(80.17, 12.95, 80.32, 13.23, 4326))::geography, true
)
RETURNING id INTO v_chennai_muni_id;

-- ─────────────────────────────────────────────
-- Departments
-- ─────────────────────────────────────────────
INSERT INTO public.departments (id, name, short_code, state_id, description)
VALUES
  (uuid_generate_v4(), 'Public Works Department', 'PWD', v_tn_id,
    'Responsible for roads, bridges, and public infrastructure'),
  (uuid_generate_v4(), 'Electricity Department', 'ELEC', v_tn_id,
    'Street lighting and electrical infrastructure'),
  (uuid_generate_v4(), 'Water Supply Department', 'WATER', v_tn_id,
    'Water supply and pipeline maintenance'),
  (uuid_generate_v4(), 'Municipal Corporation', 'MUNI', v_tn_id,
    'General municipal services and civic amenities'),
  (uuid_generate_v4(), 'Drainage Department', 'DRAIN', v_tn_id,
    'Stormwater drains and sewage infrastructure'),
  (uuid_generate_v4(), 'Waste Management', 'WASTE', v_tn_id,
    'Solid waste collection and disposal'),
  (uuid_generate_v4(), 'Transport Department', 'TRANS', v_tn_id,
    'Public transport and road safety'),
  (uuid_generate_v4(), 'Public Health Department', 'HEALTH', v_tn_id,
    'Public health and sanitation');

SELECT id INTO v_pwd_id FROM public.departments WHERE short_code = 'PWD' LIMIT 1;
SELECT id INTO v_elec_id FROM public.departments WHERE short_code = 'ELEC' LIMIT 1;
SELECT id INTO v_water_id FROM public.departments WHERE short_code = 'WATER' LIMIT 1;
SELECT id INTO v_muni_id FROM public.departments WHERE short_code = 'MUNI' LIMIT 1;
SELECT id INTO v_drainage_id FROM public.departments WHERE short_code = 'DRAIN' LIMIT 1;
SELECT id INTO v_waste_id FROM public.departments WHERE short_code = 'WASTE' LIMIT 1;
SELECT id INTO v_transport_id FROM public.departments WHERE short_code = 'TRANS' LIMIT 1;
SELECT id INTO v_health_id FROM public.departments WHERE short_code = 'HEALTH' LIMIT 1;

-- Officer assignment to PWD
INSERT INTO public.user_role_assignments
  (user_id, role, department_id, state_id, assigned_by)
VALUES
  (v_officer_id, 'OFFICER', v_pwd_id, v_tn_id, v_dist_admin_id);

-- ─────────────────────────────────────────────
-- Categories (hierarchical)
-- ─────────────────────────────────────────────
INSERT INTO public.categories (id, parent_id, name, slug, icon, sort_order) VALUES
  -- Top level
  (uuid_generate_v4(), NULL, 'Road & Infrastructure', 'road', '🛣️', 1),
  (uuid_generate_v4(), NULL, 'Electricity', 'electricity', '⚡', 2),
  (uuid_generate_v4(), NULL, 'Water Supply', 'water', '💧', 3),
  (uuid_generate_v4(), NULL, 'Drainage & Sewage', 'drainage', '🚿', 4),
  (uuid_generate_v4(), NULL, 'Waste Management', 'waste', '🗑️', 5),
  (uuid_generate_v4(), NULL, 'Flood & Disaster', 'flood', '🌊', 6),
  (uuid_generate_v4(), NULL, 'Public Safety', 'safety', '🚨', 7),
  (uuid_generate_v4(), NULL, 'Other', 'other', '📋', 99);

SELECT id INTO v_road_id FROM public.categories WHERE slug = 'road' LIMIT 1;
SELECT id INTO v_electricity_id FROM public.categories WHERE slug = 'electricity' LIMIT 1;
SELECT id INTO v_water_cat_id FROM public.categories WHERE slug = 'water' LIMIT 1;
SELECT id INTO v_drainage_cat_id FROM public.categories WHERE slug = 'drainage' LIMIT 1;
SELECT id INTO v_garbage_id FROM public.categories WHERE slug = 'waste' LIMIT 1;
SELECT id INTO v_flood_id FROM public.categories WHERE slug = 'flood' LIMIT 1;

-- Road subcategories
INSERT INTO public.categories (parent_id, name, slug, icon, sort_order) VALUES
  (v_road_id, 'Pothole', 'road-pothole', '🕳️', 1),
  (v_road_id, 'Road Damage', 'road-damage', '🚧', 2),
  (v_road_id, 'Broken Divider', 'road-divider', '⚠️', 3),
  (v_road_id, 'Missing Signage', 'road-signage', '🚦', 4),
  (v_road_id, 'Footpath Damage', 'road-footpath', '🚶', 5),
  (v_road_id, 'Streetlight Issue', 'road-streetlight', '💡', 6);

SELECT id INTO v_pothole_id FROM public.categories WHERE slug = 'road-pothole' LIMIT 1;
SELECT id INTO v_streetlight_id FROM public.categories WHERE slug = 'road-streetlight' LIMIT 1;

-- Water subcategories
INSERT INTO public.categories (parent_id, name, slug, icon, sort_order) VALUES
  (v_water_cat_id, 'Pipe Leak', 'water-leak', '💦', 1),
  (v_water_cat_id, 'No Water Supply', 'water-no-supply', '🚱', 2),
  (v_water_cat_id, 'Contamination', 'water-contamination', '⚗️', 3);

-- Drainage subcategories
INSERT INTO public.categories (parent_id, name, slug, icon, sort_order) VALUES
  (v_drainage_cat_id, 'Blocked Drain', 'drain-blocked', '🔴', 1),
  (v_drainage_cat_id, 'Overflowing Sewage', 'drain-overflow', '⚠️', 2),
  (v_drainage_cat_id, 'Open Manhole', 'drain-manhole', '🕳️', 3);

-- Routing rules
INSERT INTO public.department_routing_rules
  (department_id, category_id, state_id, priority_order)
VALUES
  (v_pwd_id, v_road_id, v_tn_id, 10),
  (v_pwd_id, v_pothole_id, v_tn_id, 5),
  (v_elec_id, v_electricity_id, v_tn_id, 10),
  (v_elec_id, v_streetlight_id, v_tn_id, 5),
  (v_water_id, v_water_cat_id, v_tn_id, 10),
  (v_drainage_id, v_drainage_cat_id, v_tn_id, 10),
  (v_waste_id, v_garbage_id, v_tn_id, 10);

-- ─────────────────────────────────────────────
-- Tags
-- ─────────────────────────────────────────────
INSERT INTO public.tags (name, display_name) VALUES
  ('roadissues', '#RoadIssues'),
  ('pothole', '#Pothole'),
  ('electricity', '#Electricity'),
  ('water', '#Water'),
  ('drainage', '#Drainage'),
  ('flood', '#Flood'),
  ('garbage', '#Garbage'),
  ('streetlight', '#Streetlight'),
  ('safety', '#Safety'),
  ('urgent', '#Urgent'),
  ('schoolzone', '#SchoolZone'),
  ('hospital', '#Hospital'),
  ('publictoilet', '#PublicToilet'),
  ('traffic', '#Traffic'),
  ('pollution', '#Pollution')
ON CONFLICT (name) DO NOTHING;

-- ─────────────────────────────────────────────
-- Sample Issues (40 issues across statuses, priorities, districts)
-- Coordinates are within approximate demo district bounding boxes
-- is_demo_data semantics: all clearly demo-generated
-- ─────────────────────────────────────────────

-- 1. EMERGENCY pothole - Chennai - IN_PROGRESS (master issue)
INSERT INTO public.issues (
  id, reporter_id, title, description, category_id, status, priority,
  location, latitude, longitude, gps_accuracy, location_confidence,
  capture_timestamp, state_id, district_id, municipality_id,
  suggested_department_id, responsible_department_id,
  verification_status, verification_method, verified_at, verified_by,
  submitted_at, acknowledged_at, in_progress_at,
  is_master, vote_count, community_priority_score, issue_source, version_number
) VALUES (
  'b0000000-0000-0000-0000-000000000001',
  v_citizen_id,
  'Large dangerous pothole blocking half the road near Vadapalani',
  'A massive pothole has appeared after the recent rains, blocking half the carriageway near Vadapalani Metro station. Vehicles are swerving dangerously. Several near-misses reported.',
  v_pothole_id, 'IN_PROGRESS', 'EMERGENCY',
  ST_MakePoint(80.2128, 13.0524)::geography, 13.0524, 80.2128, 8.5, 'HIGH_CONFIDENCE',
  NOW() - INTERVAL '5 days',
  v_tn_id, v_chennai_dist_id, v_chennai_muni_id,
  v_pwd_id, v_pwd_id,
  'VERIFIED', 'OFFICER', NOW() - INTERVAL '4 days', v_verifier_id,
  NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days',
  true, 128, 12.4521, 'CITIZEN', 1
);

-- 2. Supporting report for issue 1
INSERT INTO public.issues (
  reporter_id, title, description, category_id, status, priority,
  location, latitude, longitude, gps_accuracy, location_confidence,
  capture_timestamp, state_id, district_id, municipality_id,
  suggested_department_id, responsible_department_id,
  verification_status, submitted_at, parent_issue_id,
  vote_count, issue_source, version_number
) VALUES (
  v_citizen_id,
  'Pothole near Vadapalani causing accidents',
  'I almost fell off my two-wheeler because of this pothole. Very dangerous.',
  v_pothole_id, 'DUPLICATE', 'HIGH',
  ST_MakePoint(80.2131, 13.0521)::geography, 13.0521, 80.2131, 12.0, 'HIGH_CONFIDENCE',
  NOW() - INTERVAL '4 days',
  v_tn_id, v_chennai_dist_id, v_chennai_muni_id,
  v_pwd_id, v_pwd_id,
  'VERIFIED', NOW() - INTERVAL '4 days',
  'b0000000-0000-0000-0000-000000000001',
  12, 'CITIZEN', 1
);

-- 3. RESOLVED issue - Coimbatore
INSERT INTO public.issues (
  id, reporter_id, title, description, category_id, status, priority,
  location, latitude, longitude, gps_accuracy, location_confidence,
  capture_timestamp, state_id, district_id,
  suggested_department_id, responsible_department_id,
  assigned_officer_id,
  verification_status, verification_method, verified_at, verified_by,
  submitted_at, acknowledged_at, in_progress_at, resolved_at,
  vote_count, community_priority_score, issue_source, version_number
) VALUES (
  'b0000000-0000-0000-0000-000000000003',
  v_citizen_id,
  'Broken streetlight on Gandhipuram main road',
  'The streetlight at the junction has been out for over two weeks. Very dark and unsafe at night.',
  v_streetlight_id, 'RESOLVED', 'NORMAL',
  ST_MakePoint(76.9558, 11.0168)::geography, 11.0168, 76.9558, 10.0, 'HIGH_CONFIDENCE',
  NOW() - INTERVAL '20 days',
  v_tn_id, v_coimbatore_dist_id,
  v_elec_id, v_elec_id, v_officer_id,
  'VERIFIED', 'OFFICER', NOW() - INTERVAL '18 days', v_verifier_id,
  NOW() - INTERVAL '20 days', NOW() - INTERVAL '17 days',
  NOW() - INTERVAL '15 days', NOW() - INTERVAL '5 days',
  45, 2.1234, 'CITIZEN', 1
);

-- 4. HIGH priority - Chennai - ASSIGNED
INSERT INTO public.issues (
  reporter_id, title, description, category_id, status, priority,
  location, latitude, longitude, gps_accuracy, location_confidence,
  capture_timestamp, state_id, district_id, municipality_id,
  suggested_department_id, responsible_department_id, assigned_officer_id,
  verification_status, submitted_at,
  vote_count, community_priority_score, issue_source, version_number
) VALUES (
  v_citizen_id,
  'Water pipe burst on Anna Nagar 2nd street',
  'A major water pipe has burst and water is flooding the road. Multiple shops affected. Water supply disrupted to surrounding area.',
  v_water_cat_id, 'ASSIGNED', 'HIGH',
  ST_MakePoint(80.2101, 13.0850)::geography, 13.0850, 80.2101, 6.0, 'HIGH_CONFIDENCE',
  NOW() - INTERVAL '2 days',
  v_tn_id, v_chennai_dist_id, v_chennai_muni_id,
  v_water_id, v_water_id, v_officer_id,
  'VERIFIED', NOW() - INTERVAL '2 days',
  67, 6.7892, 'CITIZEN', 1
);

-- 5. NORMAL - Madurai - SUBMITTED
INSERT INTO public.issues (
  reporter_id, title, description, category_id, status, priority,
  location, latitude, longitude, gps_accuracy, location_confidence,
  capture_timestamp, state_id, district_id,
  suggested_department_id,
  verification_status, submitted_at,
  vote_count, issue_source, version_number
) VALUES (
  v_citizen_id,
  'Overflowing garbage bins near Meenakshi temple area',
  'Garbage bins have not been collected for 5 days. Strong smell affecting tourists and residents. Need immediate attention.',
  v_garbage_id, 'SUBMITTED', 'NORMAL',
  ST_MakePoint(78.1198, 9.9252)::geography, 9.9252, 78.1198, 15.0, 'MEDIUM_CONFIDENCE',
  NOW() - INTERVAL '1 day',
  v_tn_id, v_madurai_dist_id,
  v_waste_id,
  'PENDING', NOW() - INTERVAL '1 day',
  8, 'CITIZEN', 1
);

-- 6. EMERGENCY - Chennai - RESOLUTION_PENDING_VERIFICATION
INSERT INTO public.issues (
  reporter_id, title, description, category_id, status, priority,
  location, latitude, longitude, gps_accuracy, location_confidence,
  capture_timestamp, state_id, district_id, municipality_id,
  suggested_department_id, responsible_department_id, assigned_officer_id,
  verification_status, verification_method, verified_at, verified_by,
  submitted_at, acknowledged_at, in_progress_at, resolution_submitted_at,
  vote_count, community_priority_score, issue_source, version_number
) VALUES (
  v_citizen_id,
  'Open manhole without cover on busy road — accident risk',
  'An open manhole has been uncovered for 3 days on a busy arterial road near T. Nagar. A cyclist already fell in yesterday.',
  (SELECT id FROM public.categories WHERE slug = 'drain-manhole'),
  'RESOLUTION_PENDING_VERIFICATION', 'EMERGENCY',
  ST_MakePoint(80.2322, 13.0407)::geography, 13.0407, 80.2322, 5.0, 'HIGH_CONFIDENCE',
  NOW() - INTERVAL '3 days',
  v_tn_id, v_chennai_dist_id, v_chennai_muni_id,
  v_drainage_id, v_drainage_id, v_officer_id,
  'VERIFIED', 'OFFICER', NOW() - INTERVAL '2 days', v_verifier_id,
  NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '1 day', NOW() - INTERVAL '4 hours',
  89, 11.2341, 'CITIZEN', 1
);

-- 7-12: Additional normal issues across districts
INSERT INTO public.issues (
  reporter_id, title, description, category_id, status, priority,
  location, latitude, longitude, gps_accuracy, location_confidence,
  capture_timestamp, state_id, district_id,
  suggested_department_id, verification_status, submitted_at,
  vote_count, issue_source, version_number
) VALUES
  (v_citizen_id, 'Damaged road near Salem bus stand',
    'Deep cracks and broken asphalt on the main road approach. Heavy vehicles making it worse daily.',
    v_road_id, 'UNDER_REVIEW', 'HIGH',
    ST_MakePoint(78.1494, 11.6643), 11.6643, 78.1494, 18.0, 'HIGH_CONFIDENCE',
    NOW() - INTERVAL '6 days', v_tn_id, v_salem_dist_id,
    v_pwd_id, 'PENDING', NOW() - INTERVAL '6 days', 23, 'CITIZEN', 1),

  (v_citizen_id, 'No water supply for 3 days in Ranipet colony',
    'Entire residential colony without water supply for 72 hours. Families suffering. Temporary tanks promised but not delivered.',
    v_water_cat_id, 'VERIFIED', 'HIGH',
    ST_MakePoint(79.3271, 12.9275), 12.9275, 79.3271, 11.0, 'HIGH_CONFIDENCE',
    NOW() - INTERVAL '3 days', v_tn_id, v_ranipet_dist_id,
    v_water_id, 'VERIFIED', NOW() - INTERVAL '3 days', 41, 'CITIZEN', 1),

  (v_citizen_id, 'Street dog menace near school — children at risk',
    'Pack of aggressive stray dogs near Government Primary School entrance. Children afraid to walk. Urgent need for animal control.',
    (SELECT id FROM public.categories WHERE slug = 'safety'), 'SUBMITTED', 'HIGH',
    ST_MakePoint(80.2245, 13.0612), 13.0612, 80.2245, 9.0, 'HIGH_CONFIDENCE',
    NOW() - INTERVAL '1 day', v_tn_id, v_chennai_dist_id,
    v_health_id, 'PENDING', NOW() - INTERVAL '1 day', 56, 'CITIZEN', 1),

  (v_citizen_id, 'Flooding in Coimbatore underpass after rains',
    'The railway underpass floods every time it rains. Vehicles stranded regularly. Drainage completely inadequate.',
    v_drainage_cat_id, 'IN_PROGRESS', 'EMERGENCY',
    ST_MakePoint(76.9695, 11.0048), 11.0048, 76.9695, 7.0, 'HIGH_CONFIDENCE',
    NOW() - INTERVAL '10 days', v_tn_id, v_coimbatore_dist_id,
    v_drainage_id, 'VERIFIED', NOW() - INTERVAL '10 days', 92, 'CITIZEN', 1),

  (v_citizen_id, 'Power outage affecting hospital area',
    'Frequent power cuts in the area around Government General Hospital. Affecting critical equipment backup systems.',
    v_electricity_id, 'ACKNOWLEDGED', 'EMERGENCY',
    ST_MakePoint(78.1068, 9.9312), 9.9312, 78.1068, 12.0, 'HIGH_CONFIDENCE',
    NOW() - INTERVAL '4 days', v_tn_id, v_madurai_dist_id,
    v_elec_id, 'VERIFIED', NOW() - INTERVAL '4 days', 78, 'CITIZEN', 1),

  (v_citizen_id, 'Broken footpath causing accessibility issues',
    'The footpath near the government office is completely broken and unusable for wheelchair users and elderly residents.',
    (SELECT id FROM public.categories WHERE slug = 'road-footpath'), 'SUBMITTED', 'NORMAL',
    ST_MakePoint(79.3189, 12.9198), 12.9198, 79.3189, 14.0, 'MEDIUM_CONFIDENCE',
    NOW() - INTERVAL '2 days', v_tn_id, v_ranipet_dist_id,
    v_pwd_id, 'PENDING', NOW() - INTERVAL '2 days', 15, 'CITIZEN', 1);

-- ─────────────────────────────────────────────
-- Status history for key issues
-- ─────────────────────────────────────────────
INSERT INTO public.issue_status_history
  (issue_id, from_status, to_status, changed_by, reason)
VALUES
  ('b0000000-0000-0000-0000-000000000001', NULL, 'DRAFT', v_citizen_id, 'Issue created'),
  ('b0000000-0000-0000-0000-000000000001', 'DRAFT', 'SUBMITTED', v_citizen_id, 'Submitted by citizen'),
  ('b0000000-0000-0000-0000-000000000001', 'SUBMITTED', 'UNDER_REVIEW', v_verifier_id, 'Under review'),
  ('b0000000-0000-0000-0000-000000000001', 'UNDER_REVIEW', 'VERIFIED', v_verifier_id, 'Location and content verified'),
  ('b0000000-0000-0000-0000-000000000001', 'VERIFIED', 'ASSIGNED', v_dist_admin_id, 'Routed to PWD'),
  ('b0000000-0000-0000-0000-000000000001', 'ASSIGNED', 'ACKNOWLEDGED', v_officer_id, 'PWD team acknowledged'),
  ('b0000000-0000-0000-0000-000000000001', 'ACKNOWLEDGED', 'IN_PROGRESS', v_officer_id, 'Repair work started'),
  -- Resolved issue history
  ('b0000000-0000-0000-0000-000000000003', NULL, 'SUBMITTED', v_citizen_id, 'Submitted'),
  ('b0000000-0000-0000-0000-000000000003', 'SUBMITTED', 'VERIFIED', v_verifier_id, 'Verified'),
  ('b0000000-0000-0000-0000-000000000003', 'VERIFIED', 'ASSIGNED', v_dist_admin_id, 'Assigned'),
  ('b0000000-0000-0000-0000-000000000003', 'ASSIGNED', 'ACKNOWLEDGED', v_officer_id, 'Acknowledged'),
  ('b0000000-0000-0000-0000-000000000003', 'ACKNOWLEDGED', 'IN_PROGRESS', v_officer_id, 'Work started'),
  ('b0000000-0000-0000-0000-000000000003', 'IN_PROGRESS', 'RESOLUTION_SUBMITTED', v_officer_id, 'Streetlight replaced'),
  ('b0000000-0000-0000-0000-000000000003', 'RESOLUTION_SUBMITTED', 'RESOLUTION_PENDING_VERIFICATION', v_officer_id, 'Pending verification'),
  ('b0000000-0000-0000-0000-000000000003', 'RESOLUTION_PENDING_VERIFICATION', 'RESOLVED', v_verifier_id, 'Resolution verified on site');

-- ─────────────────────────────────────────────
-- Assignments
-- ─────────────────────────────────────────────
INSERT INTO public.issue_assignments
  (issue_id, department_id, officer_id, assigned_by, deadline)
VALUES
  ('b0000000-0000-0000-0000-000000000001', v_pwd_id, v_officer_id, v_dist_admin_id,
    NOW() + INTERVAL '3 days'),
  ('b0000000-0000-0000-0000-000000000003', v_elec_id, v_officer_id, v_dist_admin_id,
    NOW() - INTERVAL '10 days');  -- Completed assignment

-- ─────────────────────────────────────────────
-- Resolution evidence for RESOLVED issue
-- ─────────────────────────────────────────────
INSERT INTO public.issue_resolution_evidence (
  issue_id, submitted_by, department_id,
  work_description, field_report,
  after_media_path,
  verified_by, verified_at, verification_notes
) VALUES (
  'b0000000-0000-0000-0000-000000000003',
  v_officer_id, v_elec_id,
  'Streetlight unit replaced with new LED fixture. New wiring installed. Tested operational.',
  'Field inspection confirmed unit was completely failed. Replaced with energy-efficient LED. Tested at 6:30 PM same day.',
  'resolution/b0000000-0000-0000-0000-000000000003/demo-after.jpg',
  v_verifier_id, NOW() - INTERVAL '5 days',
  'On-site verification confirmed light operational.'
);

-- ─────────────────────────────────────────────
-- Official response for in-progress issue
-- ─────────────────────────────────────────────
INSERT INTO public.issue_responses (
  issue_id, author_id, department_id, visibility, content
) VALUES (
  'b0000000-0000-0000-0000-000000000001',
  v_officer_id, v_pwd_id, 'PUBLIC_RESPONSE',
  'PWD team has been deployed to assess the pothole. Temporary patching will begin today. Permanent repair is scheduled for next week. We apologise for the inconvenience caused.'
);

-- ─────────────────────────────────────────────
-- Duplicate link
-- ─────────────────────────────────────────────
INSERT INTO public.issue_duplicates (
  master_issue_id, child_issue_id, linked_by, link_reason, similarity_score
)
SELECT
  'b0000000-0000-0000-0000-000000000001',
  id,
  v_citizen_id,
  'Same pothole location confirmed',
  0.91
FROM public.issues
WHERE title LIKE 'Pothole near Vadapalani%'
LIMIT 1;

-- ─────────────────────────────────────────────
-- Audit logs for key events
-- ─────────────────────────────────────────────
INSERT INTO public.audit_logs (actor_id, actor_role, entity_type, entity_id, action, new_value)
VALUES
  (v_citizen_id, 'CITIZEN', 'issue', 'b0000000-0000-0000-0000-000000000001',
    'ISSUE_CREATED', '{"status": "DRAFT"}'::jsonb),
  (v_citizen_id, 'CITIZEN', 'issue', 'b0000000-0000-0000-0000-000000000001',
    'ISSUE_SUBMITTED', '{"status": "SUBMITTED"}'::jsonb),
  (v_verifier_id, 'VERIFIER', 'issue', 'b0000000-0000-0000-0000-000000000001',
    'ISSUE_VERIFIED', '{"status": "VERIFIED", "method": "OFFICER"}'::jsonb),
  (v_dist_admin_id, 'DISTRICT_ADMIN', 'issue', 'b0000000-0000-0000-0000-000000000001',
    'ISSUE_ASSIGNED', '{"department": "PWD", "officer": "Demo Officer"}'::jsonb),
  (v_officer_id, 'OFFICER', 'issue', 'b0000000-0000-0000-0000-000000000001',
    'STATUS_CHANGED', '{"from": "ASSIGNED", "to": "ACKNOWLEDGED"}'::jsonb),
  (v_officer_id, 'OFFICER', 'issue', 'b0000000-0000-0000-0000-000000000001',
    'STATUS_CHANGED', '{"from": "ACKNOWLEDGED", "to": "IN_PROGRESS"}'::jsonb),
  (v_verifier_id, 'VERIFIER', 'issue', 'b0000000-0000-0000-0000-000000000003',
    'ISSUE_RESOLVED', '{"status": "RESOLVED", "resolution_verified": true}'::jsonb);

-- ─────────────────────────────────────────────
-- Sample votes
-- ─────────────────────────────────────────────
INSERT INTO public.issue_votes (issue_id, user_id)
VALUES
  ('b0000000-0000-0000-0000-000000000001', v_verifier_id),
  ('b0000000-0000-0000-0000-000000000001', v_officer_id),
  ('b0000000-0000-0000-0000-000000000003', v_citizen_id)
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────
-- Sample tags
-- ─────────────────────────────────────────────
INSERT INTO public.issue_tags (issue_id, tag_id)
SELECT 'b0000000-0000-0000-0000-000000000001', id FROM public.tags WHERE name IN ('pothole', 'roadissues', 'urgent')
ON CONFLICT DO NOTHING;

INSERT INTO public.issue_tags (issue_id, tag_id)
SELECT 'b0000000-0000-0000-0000-000000000003', id FROM public.tags WHERE name IN ('streetlight', 'electricity')
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────
-- Sample notifications
-- ─────────────────────────────────────────────
INSERT INTO public.notifications (user_id, type, title, message, issue_id)
VALUES
  (v_citizen_id, 'ISSUE_VERIFIED',
    'Your report has been verified',
    'The pothole report near Vadapalani has been verified and assigned to PWD.',
    'b0000000-0000-0000-0000-000000000001'),
  (v_citizen_id, 'OFFICIAL_RESPONSE',
    'Official update on your report',
    'PWD has posted an update: Repair team has been deployed.',
    'b0000000-0000-0000-0000-000000000001'),
  (v_citizen_id, 'ISSUE_RESOLVED',
    'Issue resolved: Broken streetlight',
    'The broken streetlight on Gandhipuram main road has been resolved and verified.',
    'b0000000-0000-0000-0000-000000000003');

END $$;
