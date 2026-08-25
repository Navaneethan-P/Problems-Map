/**
 * Issue workflow state machine.
 * All status transitions go through this module — never bypass it.
 * Business logic lives here, not in database triggers.
 */
import type { IssueStatus, IssuePriority, UserRole } from "@/types";
import {
  VALID_TRANSITIONS,
  TRANSITION_ROLE_REQUIREMENTS,
} from "@/types";

// ─────────────────────────────────────────────
// Role hierarchy for permission checks
// ─────────────────────────────────────────────
const ROLE_HIERARCHY: Record<UserRole, number> = {
  CITIZEN: 0,
  VERIFIER: 1,
  OFFICER: 2,
  MLA: 3,
  DISTRICT_ADMIN: 4,
  STATE_ADMIN: 5,
  SUPER_ADMIN: 6,
};

export function hasRoleAtLeast(userRole: UserRole, minimumRole: UserRole): boolean {
  return ROLE_HIERARCHY[userRole] >= ROLE_HIERARCHY[minimumRole];
}

// ─────────────────────────────────────────────
// Transition validation
// ─────────────────────────────────────────────

export interface TransitionValidationResult {
  valid: boolean;
  error?: string;
}

export function validateTransition(
  currentStatus: IssueStatus,
  newStatus: IssueStatus,
  actorRole: UserRole
): TransitionValidationResult {
  // Check if the transition is in the valid transitions map
  const allowedNext = VALID_TRANSITIONS[currentStatus];
  if (!allowedNext.includes(newStatus)) {
    return {
      valid: false,
      error: `Transition from ${currentStatus} to ${newStatus} is not permitted.`,
    };
  }

  // Check role requirement
  const transitionKey = `${currentStatus}->${newStatus}`;
  const requiredRole = TRANSITION_ROLE_REQUIREMENTS[transitionKey];
  if (requiredRole && !hasRoleAtLeast(actorRole, requiredRole)) {
    return {
      valid: false,
      error: `Your role (${actorRole}) is not permitted to perform this transition. Required: ${requiredRole}.`,
    };
  }

  return { valid: true };
}

// ─────────────────────────────────────────────
// Priority determination (deterministic rules engine)
// ─────────────────────────────────────────────

const EMERGENCY_CATEGORY_SLUGS = new Set([
  "drain-manhole",      // Open manhole
  "road-pothole",       // Dangerous pothole (emergency threshold set in UI)
  "drain-overflow",     // Overflowing sewage
  "flood",              // Flood
  "safety",             // Public safety
]);

const HIGH_PRIORITY_CATEGORY_SLUGS = new Set([
  "road-damage",
  "water-contamination",
  "water-no-supply",
  "electricity",
  "road-streetlight",
]);

export function determinePriority(categorySlug: string | null): IssuePriority {
  if (!categorySlug) return "NORMAL";
  if (EMERGENCY_CATEGORY_SLUGS.has(categorySlug)) return "EMERGENCY";
  if (HIGH_PRIORITY_CATEGORY_SLUGS.has(categorySlug)) return "HIGH";
  return "NORMAL";
}

// ─────────────────────────────────────────────
// Location confidence calculation
// Signals: GPS accuracy, capture delay, has capture timestamp
// This is a signal, NOT a guarantee of truthfulness.
// ─────────────────────────────────────────────

import type { LocationConfidence, LocationConfidenceResult } from "@/types";

export function calculateLocationConfidence(
  gpsAccuracy: number, // meters
  captureTimestamp: number | null, // Unix ms
  submissionTimestamp: number = Date.now()
): LocationConfidenceResult {
  let score = 100;
  const signals = {
    gpsAccuracy,
    captureDelay: captureTimestamp
      ? (submissionTimestamp - captureTimestamp) / 1000
      : -1,
    hasTimestamp: captureTimestamp !== null,
  };

  // GPS accuracy signal (lower = better)
  if (gpsAccuracy > 100) score -= 40;
  else if (gpsAccuracy > 50) score -= 20;
  else if (gpsAccuracy > 20) score -= 10;

  // Capture timestamp signal
  if (!signals.hasTimestamp) {
    score -= 20;
  } else {
    // Suspicious if submitted long after capture (>24h)
    if (signals.captureDelay > 86400) score -= 30;
    // Slightly suspicious if >1h old
    else if (signals.captureDelay > 3600) score -= 10;
    // Very fresh reports (< 5 min) get bonus
    else if (signals.captureDelay < 300) score += 5;
  }

  // Clamp 0–100
  score = Math.max(0, Math.min(100, score));

  let confidence: LocationConfidence;
  if (score >= 75) confidence = "HIGH_CONFIDENCE";
  else if (score >= 50) confidence = "MEDIUM_CONFIDENCE";
  else if (score >= 25) confidence = "LOW_CONFIDENCE";
  else confidence = "SUSPICIOUS";

  return { confidence, score, signals };
}

// ─────────────────────────────────────────────
// Community priority score (mirrors the SQL function)
// Used client-side for optimistic updates
// ─────────────────────────────────────────────

export function calculateCommunityPriorityScore(
  voteCount: number,
  priority: IssuePriority,
  createdAt: Date
): number {
  const ageDays =
    (Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
  const ageDecay = Math.exp(-0.0231 * ageDays);

  const priorityWeight =
    priority === "EMERGENCY" ? 3.0 : priority === "HIGH" ? 2.0 : 1.0;

  const score =
    Math.log(Math.max(voteCount, 0) + 1) * ageDecay * priorityWeight;

  return Math.round(score * 10000) / 10000;
}
