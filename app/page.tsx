import Link from "next/link";
import { Button } from "@/components/ui/button";
import { getCurrentUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { MapDashboard } from "@/components/map/map-dashboard";

export default async function Home() {
  const { user } = await getCurrentUser();
  const supabase = await createClient();
  
  // Fetch categories for the filter dropdown
  const { data: categories } = await supabase
    .from("categories")
    .select("id, name")
    .order("name");

  return (
    <main className="flex h-screen flex-col bg-slate-50">
      {/* Header */}
      <header className="flex h-16 shrink-0 items-center justify-between border-b bg-white px-4 md:px-6 z-20 shadow-sm relative">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-500 text-white font-bold">
            P
          </div>
          <span className="text-lg font-bold tracking-tight">Problems Map</span>
        </div>
        
        <nav className="flex items-center gap-4">
          {!user ? (
            <>
              <Link href="/login" className="text-sm font-medium hover:text-brand-600 transition-colors">
                Sign in
              </Link>
              <Button asChild>
                <Link href="/citizen/report">Report an Issue</Link>
              </Button>
            </>
          ) : (
            <Button asChild>
              <Link href="/citizen/dashboard">Go to Dashboard</Link>
            </Button>
          )}
        </nav>
      </header>

      {process.env.NEXT_PUBLIC_DEMO_MODE === "true" && (
        <div className="demo-banner z-20 relative">
          DEMO ENVIRONMENT — ALL DATA IS APPROXIMATE OR FABRICATED FOR TESTING
        </div>
      )}

      {/* Main Map Area */}
      <div className="flex-1 relative overflow-hidden">
        <MapDashboard categories={categories || []} />
      </div>
    </main>
  );
}
