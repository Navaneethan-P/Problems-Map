import { z } from "zod";

// ─────────────────────────────────────────────
// Auth schemas
// ─────────────────────────────────────────────

export const LoginSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export const RegisterSchema = z
  .object({
    full_name: z
      .string()
      .min(2, "Name must be at least 2 characters")
      .max(100, "Name is too long"),
    email: z.string().email("Please enter a valid email address"),
    password: z
      .string()
      .min(8, "Password must be at least 8 characters")
      .regex(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
        "Password must include uppercase, lowercase, and a number"
      ),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

export const ResetPasswordSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
});

export const UpdatePasswordSchema = z
  .object({
    password: z
      .string()
      .min(8, "Password must be at least 8 characters")
      .regex(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
        "Password must include uppercase, lowercase, and a number"
      ),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

// ─────────────────────────────────────────────
// Issue creation schema
// ─────────────────────────────────────────────

export const CreateIssueSchema = z.object({
  title: z
    .string()
    .min(5, "Title must be at least 5 characters")
    .max(200, "Title must be 200 characters or less"),
  description: z
    .string()
    .min(10, "Description must be at least 10 characters")
    .max(5000, "Description must be 5000 characters or less"),
  category_id: z.string().uuid("Please select a valid category"),
  latitude: z
    .number()
    .min(-90)
    .max(90, "Invalid latitude"),
  longitude: z
    .number()
    .min(-180)
    .max(180, "Invalid longitude"),
  gps_accuracy: z
    .number()
    .min(0)
    .max(10000, "GPS accuracy signal out of range"),
  capture_timestamp: z.string().datetime().optional(),
  tags: z.array(z.string().max(50)).max(10, "Maximum 10 tags").optional(),
  media_ids: z
    .array(z.string().uuid())
    .max(6, "Maximum 6 media files")
    .optional(),
  parent_issue_id: z.string().uuid().optional().nullable(),
});

export const UpdateIssueDraftSchema = z.object({
  title: z
    .string()
    .min(5)
    .max(200)
    .optional(),
  description: z.string().min(10).max(5000).optional(),
  category_id: z.string().uuid().optional(),
  tags: z.array(z.string().max(50)).max(10).optional(),
});

// ─────────────────────────────────────────────
// Status change schema (used by API route handler)
// ─────────────────────────────────────────────

export const StatusChangeSchema = z.object({
  new_status: z.enum([
    "DRAFT",
    "SUBMITTED",
    "UNDER_REVIEW",
    "VERIFIED",
    "ASSIGNED",
    "ACKNOWLEDGED",
    "IN_PROGRESS",
    "RESOLUTION_SUBMITTED",
    "RESOLUTION_PENDING_VERIFICATION",
    "RESOLVED",
    "REOPENED",
    "REJECTED",
    "DUPLICATE",
    "OUT_OF_SCOPE",
  ]),
  reason: z.string().max(1000).optional(),
  version_number: z.number().int().min(1, "Version number required for concurrency check"),
  rejection_reason: z
    .enum([
      "SPAM",
      "FALSE_REPORT",
      "INSUFFICIENT_EVIDENCE",
      "DUPLICATE",
      "WRONG_DEPARTMENT",
      "PRIVATE_PROPERTY",
      "OUTSIDE_JURISDICTION",
      "OTHER",
    ])
    .optional(),
  rejection_note: z.string().max(1000).optional(),
});

// ─────────────────────────────────────────────
// Assignment schema
// ─────────────────────────────────────────────

export const AssignmentSchema = z.object({
  department_id: z.string().uuid("Please select a valid department"),
  officer_id: z.string().uuid().optional().nullable(),
  assignment_notes: z.string().max(1000).optional(),
  deadline: z.string().datetime().optional().nullable(),
});

// ─────────────────────────────────────────────
// Response schema (officer public/internal note)
// ─────────────────────────────────────────────

export const IssueResponseSchema = z.object({
  content: z
    .string()
    .min(1, "Response cannot be empty")
    .max(10000, "Response is too long"),
  visibility: z.enum(["PUBLIC_RESPONSE", "INTERNAL_NOTE"]),
});

// ─────────────────────────────────────────────
// Resolution evidence schema
// ─────────────────────────────────────────────

export const ResolutionEvidenceSchema = z.object({
  work_description: z
    .string()
    .min(10, "Please describe the work completed")
    .max(5000),
  field_report: z.string().max(5000).optional(),
  before_media_path: z.string().optional().nullable(),
  after_media_path: z.string().optional().nullable(),
  document_path: z.string().optional().nullable(),
  resolution_latitude: z.number().min(-90).max(90).optional().nullable(),
  resolution_longitude: z.number().min(-180).max(180).optional().nullable(),
});

// ─────────────────────────────────────────────
// Reopen schema
// ─────────────────────────────────────────────

export const ReopenSchema = z.object({
  reason: z
    .string()
    .min(10, "Please explain why this issue needs to be reopened")
    .max(1000),
  version_number: z.number().int().min(1),
});

// ─────────────────────────────────────────────
// Abuse report schema
// ─────────────────────────────────────────────

export const AbuseReportSchema = z.object({
  reason: z.enum([
    "SPAM",
    "MISLEADING",
    "ABUSIVE",
    "ILLEGAL_CONTENT",
    "PRIVACY_VIOLATION",
    "DUPLICATE",
    "FALSE_INFORMATION",
    "OTHER",
  ]),
  explanation: z.string().max(1000).optional(),
});

// ─────────────────────────────────────────────
// Profile update schema
// ─────────────────────────────────────────────

export const ProfileSchema = z.object({
  full_name: z
    .string()
    .min(2, "Name must be at least 2 characters")
    .max(100)
    .optional(),
  phone: z
    .string()
    .regex(/^\+?[0-9\s\-().]{7,20}$/, "Invalid phone number")
    .optional()
    .nullable(),
  avatar_url: z.string().url().optional().nullable(),
});

// ─────────────────────────────────────────────
// Duplicate link schema
// ─────────────────────────────────────────────

export const DuplicateLinkSchema = z.object({
  master_issue_id: z.string().uuid("Invalid master issue ID"),
  link_reason: z.string().max(500).optional(),
  similarity_score: z.number().min(0).max(1).optional(),
});

// ─────────────────────────────────────────────
// Search / filter schema
// ─────────────────────────────────────────────

export const SearchParamsSchema = z.object({
  q: z.string().max(200).optional(),
  status: z.string().optional(),
  priority: z.string().optional(),
  category_id: z.string().uuid().optional(),
  district_id: z.string().uuid().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const MapQuerySchema = z.object({
  west: z.coerce.number().min(-180).max(180),
  south: z.coerce.number().min(-90).max(90),
  east: z.coerce.number().min(-180).max(180),
  north: z.coerce.number().min(-90).max(90),
  status: z.string().optional(),
  priority: z.string().optional(),
  category_id: z.string().uuid().optional(),
  department_id: z.string().uuid().optional(),
});

// ─────────────────────────────────────────────
// Inferred types
// ─────────────────────────────────────────────

export type LoginInput = z.infer<typeof LoginSchema>;
export type RegisterInput = z.infer<typeof RegisterSchema>;
export type CreateIssueInput = z.infer<typeof CreateIssueSchema>;
export type StatusChangeInput = z.infer<typeof StatusChangeSchema>;
export type AssignmentInput = z.infer<typeof AssignmentSchema>;
export type IssueResponseInput = z.infer<typeof IssueResponseSchema>;
export type ResolutionEvidenceInput = z.infer<typeof ResolutionEvidenceSchema>;
export type ReopenInput = z.infer<typeof ReopenSchema>;
export type ProfileInput = z.infer<typeof ProfileSchema>;
