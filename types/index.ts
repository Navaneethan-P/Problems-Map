/**
 * Application-level TypeScript types for Problems Map.
 * These extend the raw Supabase database types with domain-specific logic.
 */

// ─────────────────────────────────────────────
// Enums (mirror the PostgreSQL enums from migration 002)
// ─────────────────────────────────────────────

export type IssueStatus =
  | "DRAFT"
  | "SUBMITTED"
  | "UNDER_REVIEW"
  | "VERIFIED"
  | "ASSIGNED"
  | "ACKNOWLEDGED"
  | "IN_PROGRESS"
  | "RESOLUTION_SUBMITTED"
  | "RESOLUTION_PENDING_VERIFICATION"
  | "RESOLVED"
  | "REOPENED"
  | "REJECTED"
  | "DUPLICATE"
  | "OUT_OF_SCOPE";

export type IssuePriority = "EMERGENCY" | "HIGH" | "NORMAL";

export type UserRole =
  | "CITIZEN"
  | "VERIFIER"
  | "OFFICER"
  | "MLA"
  | "DISTRICT_ADMIN"
  | "STATE_ADMIN"
  | "SUPER_ADMIN";

export type MediaSource = "CAPTURED_DURING_REPORT" | "UPLOADED";

export type NoteVisibility = "PUBLIC_RESPONSE" | "INTERNAL_NOTE";

export type LocationConfidence =
  | "HIGH_CONFIDENCE"
  | "MEDIUM_CONFIDENCE"
  | "LOW_CONFIDENCE"
  | "SUSPICIOUS";

export type VerificationMethod =
  | "AUTOMATED"
  | "COMMUNITY"
  | "OFFICER"
  | "ADMIN"
  | "MIXED";

export type VerificationStatus =
  | "PENDING"
  | "VERIFIED"
  | "REJECTED"
  | "NEEDS_REVIEW";

export type IssueSource =
  | "CITIZEN"
  | "OFFICIAL"
  | "IMPORTED"
  | "PARTNER_API";

export type RejectionReason =
  | "SPAM"
  | "FALSE_REPORT"
  | "INSUFFICIENT_EVIDENCE"
  | "DUPLICATE"
  | "WRONG_DEPARTMENT"
  | "PRIVATE_PROPERTY"
  | "OUTSIDE_JURISDICTION"
  | "OTHER";

export type AbuseReason =
  | "SPAM"
  | "MISLEADING"
  | "ABUSIVE"
  | "ILLEGAL_CONTENT"
  | "PRIVACY_VIOLATION"
  | "DUPLICATE"
  | "FALSE_INFORMATION"
  | "OTHER";

export type AccountStatus =
  | "ACTIVE"
  | "SUSPENDED"
  | "DEACTIVATED"
  | "PENDING_VERIFICATION";

// ─────────────────────────────────────────────
// Status machine: valid transitions
// ─────────────────────────────────────────────

export const VALID_TRANSITIONS: Record<IssueStatus, IssueStatus[]> = {
  DRAFT: ["SUBMITTED"],
  SUBMITTED: ["UNDER_REVIEW", "REJECTED"],
  UNDER_REVIEW: ["VERIFIED", "REJECTED", "DUPLICATE"],
  VERIFIED: ["ASSIGNED"],
  ASSIGNED: ["ACKNOWLEDGED"],
  ACKNOWLEDGED: ["IN_PROGRESS"],
  IN_PROGRESS: ["RESOLUTION_SUBMITTED"],
  RESOLUTION_SUBMITTED: ["RESOLUTION_PENDING_VERIFICATION"],
  RESOLUTION_PENDING_VERIFICATION: ["RESOLVED", "IN_PROGRESS"],
  RESOLVED: ["REOPENED"],
  REOPENED: ["IN_PROGRESS"],
  REJECTED: [],
  DUPLICATE: [],
  OUT_OF_SCOPE: [],
};

// Minimum role required to trigger each transition
export const TRANSITION_ROLE_REQUIREMENTS: Record<
  string,
  UserRole
> = {
  "DRAFT->SUBMITTED": "CITIZEN",
  "SUBMITTED->UNDER_REVIEW": "VERIFIER",
  "SUBMITTED->REJECTED": "VERIFIER",
  "UNDER_REVIEW->VERIFIED": "VERIFIER",
  "UNDER_REVIEW->REJECTED": "VERIFIER",
  "UNDER_REVIEW->DUPLICATE": "VERIFIER",
  "VERIFIED->ASSIGNED": "OFFICER",
  "ASSIGNED->ACKNOWLEDGED": "OFFICER",
  "ACKNOWLEDGED->IN_PROGRESS": "OFFICER",
  "IN_PROGRESS->RESOLUTION_SUBMITTED": "OFFICER",
  "RESOLUTION_SUBMITTED->RESOLUTION_PENDING_VERIFICATION": "OFFICER",
  "RESOLUTION_PENDING_VERIFICATION->RESOLVED": "VERIFIER",
  "RESOLUTION_PENDING_VERIFICATION->IN_PROGRESS": "VERIFIER",
  "RESOLVED->REOPENED": "CITIZEN",
  "REOPENED->IN_PROGRESS": "OFFICER",
};

// ─────────────────────────────────────────────
// Domain types
// ─────────────────────────────────────────────

export interface Profile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  phone: string | null;
  role: UserRole;
  account_status: AccountStatus;
  created_at: string;
  updated_at: string;
}

export interface Department {
  id: string;
  name: string;
  description: string | null;
  short_code: string | null;
  state_id: string | null;
  district_id: string | null;
  is_active: boolean;
  created_at: string;
}

export interface Category {
  id: string;
  parent_id: string | null;
  name: string;
  slug: string;
  description: string | null;
  icon: string | null;
  sort_order: number;
  is_active: boolean;
  children?: Category[];
}

export interface Tag {
  id: string;
  name: string;
  display_name: string;
  use_count: number;
}

export interface Issue {
  id: string;
  reporter_id: string;
  issue_source: IssueSource;
  title: string;
  description: string;
  category_id: string | null;
  status: IssueStatus;
  priority: IssuePriority;
  // Location
  latitude: number;
  longitude: number;
  gps_accuracy: number | null;
  location_confidence: LocationConfidence | null;
  capture_timestamp: string | null;
  // Geography
  country_id: string | null;
  state_id: string | null;
  district_id: string | null;
  taluk_id: string | null;
  municipality_id: string | null;
  ward_id: string | null;
  constituency_id: string | null;
  // Ownership
  suggested_department_id: string | null;
  responsible_department_id: string | null;
  suggested_officer_id: string | null;
  assigned_officer_id: string | null;
  // Verification
  verification_status: VerificationStatus;
  verification_method: VerificationMethod | null;
  verified_at: string | null;
  verified_by: string | null;
  // Rejection
  rejection_reason: RejectionReason | null;
  rejection_note: string | null;
  // Master issue
  parent_issue_id: string | null;
  is_master: boolean;
  // Community
  vote_count: number;
  community_priority_score: number;
  // Timestamps
  submitted_at: string | null;
  acknowledged_at: string | null;
  in_progress_at: string | null;
  resolution_submitted_at: string | null;
  resolved_at: string | null;
  reopened_at: string | null;
  reopen_count: number;
  // Concurrency
  version_number: number;
  // Soft delete
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
}

// Lightweight issue for map markers
export interface IssueMapMarker {
  id: string;
  latitude: number;
  longitude: number;
  status: IssueStatus;
  priority: IssuePriority;
  title: string;
  category_id: string | null;
  vote_count: number;
  is_master: boolean;
  created_at: string;
}

// Issue with joined relations for detail view
export interface IssueDetail extends Issue {
  category?: Category;
  responsible_department?: Department;
  suggested_department?: Department;
  reporter?: Pick<Profile, "id" | "full_name" | "avatar_url">;
  assigned_officer?: Pick<Profile, "id" | "full_name" | "avatar_url">;
  media?: IssueMedia[];
  status_history?: IssueStatusHistory[];
  responses?: IssueResponse[];
  tags?: Tag[];
  supporting_count?: number; // COUNT(*) from parent_issue_id
}

export interface IssueMedia {
  id: string;
  issue_id: string;
  uploader_id: string;
  storage_path: string;
  public_url: string | null;
  thumbnail_url: string | null;
  media_type: "image" | "video";
  mime_type: string;
  file_size_bytes: number | null;
  width_px: number | null;
  height_px: number | null;
  duration_secs: number | null;
  media_source: MediaSource;
  captured_at: string | null;
  sort_order: number;
  is_resolution_evidence: boolean;
  created_at: string;
}

export interface IssueStatusHistory {
  id: string;
  issue_id: string;
  from_status: IssueStatus | null;
  to_status: IssueStatus;
  changed_by: string;
  reason: string | null;
  notes: string | null;
  created_at: string;
  actor?: Pick<Profile, "id" | "full_name" | "role">;
}

export interface IssueResponse {
  id: string;
  issue_id: string;
  author_id: string;
  department_id: string | null;
  visibility: NoteVisibility;
  content: string;
  created_at: string;
  updated_at: string;
  author?: Pick<Profile, "id" | "full_name" | "role">;
  department?: Pick<Department, "id" | "name" | "short_code">;
}

export interface IssueAssignment {
  id: string;
  issue_id: string;
  department_id: string;
  officer_id: string | null;
  assigned_by: string;
  assignment_notes: string | null;
  deadline: string | null;
  is_active: boolean;
  created_at: string;
  department?: Department;
  officer?: Pick<Profile, "id" | "full_name">;
}

export interface IssueResolutionEvidence {
  id: string;
  issue_id: string;
  submitted_by: string;
  department_id: string | null;
  work_description: string;
  field_report: string | null;
  before_media_path: string | null;
  after_media_path: string | null;
  document_path: string | null;
  resolution_latitude: number | null;
  resolution_longitude: number | null;
  verified_by: string | null;
  verified_at: string | null;
  verification_notes: string | null;
  created_at: string;
}

export interface AuditLog {
  id: string;
  actor_id: string | null;
  actor_role: UserRole | null;
  entity_type: string;
  entity_id: string;
  action: string;
  old_value: Record<string, unknown> | null;
  new_value: Record<string, unknown> | null;
  reason: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  type: string;
  title: string;
  message: string;
  issue_id: string | null;
  is_read: boolean;
  read_at: string | null;
  created_at: string;
}

// ─────────────────────────────────────────────
// API request/response types
// ─────────────────────────────────────────────

export interface ApiResponse<T> {
  data: T | null;
  error: string | null;
}

export interface PaginatedResponse<T> {
  data: T[];
  count: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

export interface MapQueryParams {
  west: number;
  south: number;
  east: number;
  north: number;
  status?: IssueStatus[];
  priority?: IssuePriority[];
  category_id?: string;
  department_id?: string;
}

export interface NearbyQueryParams {
  lat: number;
  lng: number;
  radius?: number; // meters, default 1000
  limit?: number;
}

export interface SearchQueryParams {
  q?: string;
  status?: IssueStatus | IssueStatus[];
  priority?: IssuePriority | IssuePriority[];
  category_id?: string;
  district_id?: string;
  page?: number;
  limit?: number;
}

// ─────────────────────────────────────────────
// Location types
// ─────────────────────────────────────────────

export interface GPSCoordinates {
  latitude: number;
  longitude: number;
  accuracy: number; // meters
  timestamp: number; // Unix ms
}

export interface LocationConfidenceResult {
  confidence: LocationConfidence;
  score: number; // 0–100
  signals: {
    gpsAccuracy: number;
    captureDelay: number; // seconds between GPS capture and submission
    hasTimestamp: boolean;
  };
}

// ─────────────────────────────────────────────
// Offline queue types (IndexedDB)
// ─────────────────────────────────────────────

export type OfflineQueueStatus =
  | "PENDING"
  | "UPLOADING"
  | "RETRYING"
  | "FAILED"
  | "SYNCED";

export interface OfflineIssueQueueItem {
  localId: string; // UUID generated on device
  capturedAt: number; // Unix ms
  status: OfflineQueueStatus;
  retryCount: number;
  lastError: string | null;
  draft: {
    title: string;
    description: string;
    categoryId: string | null;
    latitude: number;
    longitude: number;
    gpsAccuracy: number;
    captureTimestamp: number;
    tags: string[];
    mediaFiles: Array<{
      localPath: string;
      mimeType: string;
      mediaSource: MediaSource;
    }>;
  };
}
