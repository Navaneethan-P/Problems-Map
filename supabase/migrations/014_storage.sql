-- Migration 014: Storage Buckets and Storage RLS Policies
-- Supabase Storage bucket policies are separate from table RLS.
-- These policies are applied via the Supabase Storage API.
-- NOTE: Run these after creating buckets in the Supabase dashboard or via CLI.

-- ─────────────────────────────────────────────
-- Create Storage Buckets
-- ─────────────────────────────────────────────

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

-- ─────────────────────────────────────────────
-- Storage RLS Policies: issue-media bucket
-- Path structure: issues/{issueId}/{userId}/{filename}
-- ─────────────────────────────────────────────

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

-- ─────────────────────────────────────────────
-- Storage RLS Policies: resolution-evidence bucket
-- Path structure: resolution/{issueId}/{officerId}/{filename}
-- ─────────────────────────────────────────────

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

-- ─────────────────────────────────────────────
-- Storage RLS Policies: avatars bucket
-- Path structure: avatars/{userId}/{filename}
-- ─────────────────────────────────────────────

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
