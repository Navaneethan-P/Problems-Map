import { redirect } from "next/navigation";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { 
  MapPin, 
  LayoutDashboard, 
  ListTodo, 
  Users, 
  Settings,
  LogOut,
  ShieldCheck
} from "lucide-react";
import { logout } from "../(auth)/actions";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, profile } = await getCurrentUser();

  if (!user || !profile) {
    redirect("/login");
  }

  // Authorize official roles
  const validRoles = [
    "VERIFIER",
    "OFFICER",
    "MLA",
    "DISTRICT_ADMIN",
    "STATE_ADMIN",
    "SUPER_ADMIN"
  ];
  
  if (!validRoles.includes(profile.role)) {
    redirect("/citizen/dashboard");
  }

  return (
    <div className="flex h-screen bg-slate-100 overflow-hidden">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r bg-slate-900 text-slate-300 hidden md:flex flex-col">
        <div className="p-4 border-b border-slate-800">
          <Link href="/admin/dashboard" className="flex items-center gap-2 text-white">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-500 font-bold">
              P
            </div>
            <span className="text-lg font-bold tracking-tight">Official Portal</span>
          </Link>
        </div>

        <div className="p-4 border-b border-slate-800 bg-slate-950/50">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center text-white">
              <ShieldCheck className="w-5 h-5 text-brand-400" />
            </div>
            <div>
              <p className="text-sm font-medium text-white leading-tight">{profile.full_name}</p>
              <p className="text-xs text-brand-400 font-semibold">{profile.role.replace('_', ' ')}</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 space-y-1 p-4">
          <Link
            href="/admin/dashboard"
            className="flex items-center gap-3 rounded-lg px-3 py-2 hover:bg-slate-800 hover:text-white transition-colors"
          >
            <LayoutDashboard className="h-5 w-5" />
            Dashboard
          </Link>
          <Link
            href="/admin/issues"
            className="flex items-center gap-3 rounded-lg px-3 py-2 hover:bg-slate-800 hover:text-white transition-colors"
          >
            <ListTodo className="h-5 w-5" />
            Issue Queue
          </Link>
          
          {(profile.role.includes("ADMIN") || profile.role === "MLA") && (
            <>
              <Link
                href="/admin/team"
                className="flex items-center gap-3 rounded-lg px-3 py-2 hover:bg-slate-800 hover:text-white transition-colors"
              >
                <Users className="h-5 w-5" />
                Team & Users
              </Link>
              <Link
                href="/admin/settings"
                className="flex items-center gap-3 rounded-lg px-3 py-2 hover:bg-slate-800 hover:text-white transition-colors"
              >
                <Settings className="h-5 w-5" />
                Settings
              </Link>
            </>
          )}

          <div className="mt-8 pt-4 border-t border-slate-800">
            <Link
              href="/citizen/dashboard"
              className="flex items-center gap-3 rounded-lg px-3 py-2 text-slate-400 hover:bg-slate-800 hover:text-white transition-colors"
            >
              <MapPin className="h-5 w-5" />
              Switch to Citizen View
            </Link>
          </div>
        </nav>

        <div className="p-4 border-t border-slate-800">
          <form action={logout}>
            <Button variant="ghost" className="w-full justify-start text-slate-400 hover:text-white hover:bg-slate-800">
              <LogOut className="mr-2 h-5 w-5" />
              Sign out
            </Button>
          </form>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Mobile Header */}
        <header className="md:hidden flex h-14 shrink-0 items-center justify-between border-b bg-slate-900 text-white px-4">
          <Link href="/admin/dashboard" className="flex items-center gap-2">
            <ShieldCheck className="h-5 w-5 text-brand-400" />
            <span className="font-bold">Official Portal</span>
          </Link>
          <form action={logout}>
            <Button variant="ghost" size="icon" className="text-slate-300 hover:text-white">
              <LogOut className="h-5 w-5" />
            </Button>
          </form>
        </header>

        <div className="flex-1 overflow-auto p-4 md:p-6 lg:p-8">
          {children}
        </div>
        
        {/* Mobile bottom nav */}
        <div className="md:hidden flex border-t bg-slate-900 h-16 shrink-0 justify-around items-center px-2">
          <Link href="/admin/dashboard" className="flex flex-col items-center p-2 text-brand-400">
            <LayoutDashboard className="h-5 w-5" />
            <span className="text-[10px] font-medium mt-1">Dash</span>
          </Link>
          <Link href="/admin/issues" className="flex flex-col items-center p-2 text-slate-400">
            <ListTodo className="h-5 w-5" />
            <span className="text-[10px] font-medium mt-1">Queue</span>
          </Link>
          <Link href="/citizen/dashboard" className="flex flex-col items-center p-2 text-slate-400">
            <MapPin className="h-5 w-5" />
            <span className="text-[10px] font-medium mt-1">Citizen</span>
          </Link>
        </div>
      </main>
    </div>
  );
}
