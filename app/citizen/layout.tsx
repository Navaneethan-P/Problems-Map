import { redirect } from "next/navigation";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { MapPin, Plus, User, FileText, LogOut } from "lucide-react";
import { logout } from "../(auth)/actions";

export default async function CitizenLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, profile } = await getCurrentUser();

  if (!user || !profile) {
    redirect("/login");
  }

  // If role is officer/admin, they can still see citizen view but might want admin view
  const isAdminOrOfficer = ["VERIFIER", "OFFICER", "MLA", "DISTRICT_ADMIN", "STATE_ADMIN", "SUPER_ADMIN"].includes(profile.role);

  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r bg-white hidden md:flex flex-col">
        <div className="p-4 border-b">
          <Link href="/" className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-500 text-white font-bold">
              P
            </div>
            <span className="text-lg font-bold tracking-tight">Problems Map</span>
          </Link>
        </div>

        <div className="p-4">
          <Button asChild className="w-full justify-start" size="lg">
            <Link href="/report">
              <Plus className="mr-2 h-5 w-5" />
              Report Issue
            </Link>
          </Button>
        </div>

        <nav className="flex-1 space-y-1 p-4">
          <Link
            href="/citizen/dashboard"
            className="flex items-center gap-3 rounded-lg px-3 py-2 text-slate-700 hover:bg-slate-100 font-medium"
          >
            <MapPin className="h-5 w-5 text-slate-400" />
            My Dashboard
          </Link>
          <Link
            href="/citizen/issues"
            className="flex items-center gap-3 rounded-lg px-3 py-2 text-slate-700 hover:bg-slate-100 font-medium"
          >
            <FileText className="h-5 w-5 text-slate-400" />
            My Reports
          </Link>
          <Link
            href="/citizen/profile"
            className="flex items-center gap-3 rounded-lg px-3 py-2 text-slate-700 hover:bg-slate-100 font-medium"
          >
            <User className="h-5 w-5 text-slate-400" />
            Profile
          </Link>
          
          {isAdminOrOfficer && (
            <Link
              href="/admin/dashboard"
              className="flex items-center gap-3 rounded-lg px-3 py-2 text-brand-700 bg-brand-50 hover:bg-brand-100 font-semibold mt-8 border border-brand-200"
            >
              Switch to Official Portal
            </Link>
          )}
        </nav>

        <div className="p-4 border-t">
          <form action={logout}>
            <Button variant="ghost" className="w-full justify-start text-slate-600 hover:text-slate-900">
              <LogOut className="mr-2 h-5 w-5" />
              Sign out
            </Button>
          </form>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Mobile Header */}
        <header className="md:hidden flex h-14 shrink-0 items-center justify-between border-b bg-white px-4">
          <Link href="/" className="flex items-center gap-2">
            <div className="flex h-6 w-6 items-center justify-center rounded bg-brand-500 text-white font-bold text-xs">
              P
            </div>
            <span className="font-bold">Problems Map</span>
          </Link>
          <form action={logout}>
            <Button variant="ghost" size="icon">
              <LogOut className="h-5 w-5" />
            </Button>
          </form>
        </header>

        <div className="flex-1 overflow-auto p-4 md:p-6 lg:p-8">
          {children}
        </div>
        
        {/* Mobile bottom nav */}
        <div className="md:hidden flex border-t bg-white h-16 shrink-0 justify-around items-center px-2">
          <Link href="/citizen/dashboard" className="flex flex-col items-center p-2 text-brand-600">
            <MapPin className="h-5 w-5" />
            <span className="text-[10px] font-medium mt-1">Dashboard</span>
          </Link>
          <Link href="/report" className="flex flex-col items-center p-2 text-slate-500">
            <div className="bg-brand-500 text-white p-2 rounded-full -mt-6 border-4 border-white shadow-sm">
              <Plus className="h-6 w-6" />
            </div>
            <span className="text-[10px] font-medium mt-1">Report</span>
          </Link>
          <Link href="/citizen/profile" className="flex flex-col items-center p-2 text-slate-500">
            <User className="h-5 w-5" />
            <span className="text-[10px] font-medium mt-1">Profile</span>
          </Link>
        </div>
      </main>
    </div>
  );
}
