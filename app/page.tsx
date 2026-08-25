import { PublicMap } from "@/components/map/public-map";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { getCurrentUser } from "@/lib/auth";

export default async function Home() {
  const { user } = await getCurrentUser();

  return (
    <main className="flex h-screen flex-col bg-slate-50">
      {/* Header */}
      <header className="flex h-16 shrink-0 items-center justify-between border-b bg-white px-4 md:px-6 z-10 shadow-sm relative">
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
                <Link href="/register">Report an Issue</Link>
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
        <div className="demo-banner z-10 relative">
          DEMO ENVIRONMENT — ALL DATA IS APPROXIMATE OR FABRICATED FOR TESTING
        </div>
      )}

      {/* Main Map Area */}
      <div className="flex-1 relative">
        <PublicMap />
        
        {/* Map overlay controls could go here (search, filters, etc) */}
        <div className="absolute top-4 left-4 z-10 w-80 max-w-[calc(100vw-2rem)]">
          <div className="bg-white rounded-xl shadow-lg p-4 border">
            <h2 className="font-semibold text-lg mb-1">Civic Issues</h2>
            <p className="text-sm text-slate-500 mb-4">
              Explore reported problems in your area.
            </p>
            {/* Filters placeholder */}
            <div className="space-y-2">
              <div className="flex gap-2">
                <span className="w-3 h-3 rounded-full bg-emergency mt-1"></span>
                <span className="text-sm font-medium">Emergency</span>
              </div>
              <div className="flex gap-2">
                <span className="w-3 h-3 rounded-full bg-high mt-1"></span>
                <span className="text-sm font-medium">High Priority</span>
              </div>
              <div className="flex gap-2">
                <span className="w-3 h-3 rounded-full bg-normal mt-1"></span>
                <span className="text-sm font-medium">Normal</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
