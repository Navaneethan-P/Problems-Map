-- Migration 008: Issue Media, Votes, Followers, Abuse Reports, Tags Junction

-- ─────────────────────────────────────────────
-- Issue Media
-- References Supabase Storage paths (not raw file data in Postgres)
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Issue Votes (Prioritize)
-- One vote per citizen per issue.
-- Labeled "Prioritize" in UI — not "Like".
-- ─────────────────────────────────────────────
CREATE TABLE public.issue_votes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_issue_votes UNIQUE (issue_id, user_id)
);

CREATE INDEX idx_issue_votes_issue ON public.issue_votes (issue_id);
CREATE INDEX idx_issue_votes_user  ON public.issue_votes (user_id);

-- ─────────────────────────────────────────────
-- Issue Followers
-- Citizens can follow issues to receive status update notifications.
-- ─────────────────────────────────────────────
CREATE TABLE public.issue_followers (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_issue_followers UNIQUE (issue_id, user_id)
);

CREATE INDEX idx_issue_followers_issue ON public.issue_followers (issue_id);
CREATE INDEX idx_issue_followers_user  ON public.issue_followers (user_id);

-- ─────────────────────────────────────────────
-- Issue Abuse Reports (flag for moderation)
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Issue ↔ Tag junction
-- ─────────────────────────────────────────────
CREATE TABLE public.issue_tags (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES public.issues(id) ON DELETE CASCADE,
  tag_id      UUID NOT NULL REFERENCES public.tags(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_issue_tags UNIQUE (issue_id, tag_id)
);

CREATE INDEX idx_issue_tags_issue ON public.issue_tags (issue_id);
CREATE INDEX idx_issue_tags_tag   ON public.issue_tags (tag_id);
