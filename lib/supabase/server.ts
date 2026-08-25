/**
 * Server-side Supabase client (SSR).
 * Operates as the AUTHENTICATED USER — RLS remains active.
 * Use this for all normal server operations (Route Handlers, Server Components).
 *
 * This is NOT the admin/service-role client.
 * For privileged operations, use lib/supabase/admin.ts explicitly.
 */
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "@/types/database";

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // setAll called from a Server Component — safe to ignore
            // The middleware will handle session refresh
          }
        },
      },
    }
  );
}
