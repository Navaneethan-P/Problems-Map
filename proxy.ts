import { NextResponse, type NextRequest } from "next/server";
import { createMiddlewareClient } from "@/lib/supabase/middleware";

// Routes that require authentication
const PROTECTED_PREFIXES = ["/citizen", "/admin"];

// Routes only accessible when NOT authenticated
const AUTH_ONLY_ROUTES = ["/login", "/register"];

export default async function proxy(request: NextRequest) {
  const response = NextResponse.next({
    request: { headers: request.headers },
  });

  const supabase = createMiddlewareClient(request, response);

  // Refresh the session — this is the primary job of middleware
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const pathname = request.nextUrl.pathname;

  // Redirect authenticated users away from auth pages
  if (user && AUTH_ONLY_ROUTES.some((r) => pathname.startsWith(r))) {
    return NextResponse.redirect(new URL("/citizen/dashboard", request.url));
  }

  // Redirect unauthenticated users away from protected routes
  if (!user && PROTECTED_PREFIXES.some((p) => pathname.startsWith(p))) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirectTo", pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Admin route: require OFFICER or higher (enforced again server-side per route)
  if (user && pathname.startsWith("/admin")) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    const adminRoles = [
      "VERIFIER",
      "OFFICER",
      "MLA",
      "DISTRICT_ADMIN",
      "STATE_ADMIN",
      "SUPER_ADMIN",
    ];

    if (!profile || !adminRoles.includes(profile.role)) {
      return NextResponse.redirect(new URL("/citizen/dashboard", request.url));
    }
  }

  return response;
}

export const config = {
  matcher: [
    // Skip static files, images, favicon
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
