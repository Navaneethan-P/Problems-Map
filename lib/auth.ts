import { createClient } from "@/lib/supabase/server";
import type { Profile, UserRole } from "@/types";

/**
 * Get the current authenticated user and their full profile from the database.
 * This should be used by Server Components or Server Actions.
 */
export async function getCurrentUser(): Promise<{
  user: any | null;
  profile: Profile | null;
  error: Error | null;
}> {
  try {
    const supabase = await createClient();

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return { user: null, profile: null, error: userError || new Error("No user") };
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return { user, profile: null, error: profileError || new Error("No profile") };
    }

    return { user, profile: profile as Profile, error: null };
  } catch (error) {
    return { user: null, profile: null, error: error as Error };
  }
}

/**
 * Check if the current user has at least the specified role.
 */
export async function requireRole(minimumRole: UserRole) {
  const { profile } = await getCurrentUser();
  if (!profile) return false;

  const ROLE_HIERARCHY: Record<UserRole, number> = {
    CITIZEN: 0,
    VERIFIER: 1,
    OFFICER: 2,
    MLA: 3,
    DISTRICT_ADMIN: 4,
    STATE_ADMIN: 5,
    SUPER_ADMIN: 6,
  };

  return ROLE_HIERARCHY[profile.role] >= ROLE_HIERARCHY[minimumRole];
}
