/**
 * Admin (service-role) Supabase client.
 *
 * ⚠️  WARNING: This client BYPASSES Row Level Security.
 * Use ONLY for isolated, narrowly-defined trusted operations:
 *   - Creating auth users in seed/admin scripts
 *   - System-level maintenance operations
 *   - Trusted backend jobs that cannot operate as any user
 *
 * DO NOT use this client in normal request handlers.
 * DO NOT expose this client to any code that handles user input.
 * The service role key must NEVER be present in NEXT_PUBLIC_* variables.
 *
 * Every call site using this client must have a comment explaining WHY
 * service-role access is required for that specific operation.
 */
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/types/database";

let adminClient: ReturnType<typeof createClient<Database>> | null = null;

export function createAdminClient() {
  // Fail loudly if the service role key is missing rather than
  // silently falling back to an insecure default
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error(
      "SUPABASE_SERVICE_ROLE_KEY is not set. " +
        "This operation requires the service role client. " +
        "If this is a normal request, use the server client from lib/supabase/server.ts instead."
    );
  }

  // Singleton to avoid creating multiple connections
  if (!adminClient) {
    adminClient = createClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );
  }

  return adminClient;
}
