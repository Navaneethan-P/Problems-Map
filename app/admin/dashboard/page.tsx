import { getCurrentUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { AlertTriangle, Clock, Activity, CheckCircle } from "lucide-react";
import Link from "next/link";
import { formatDate } from "@/lib/utils";

export default async function AdminDashboard() {
  const { profile } = await getCurrentUser();
  const supabase = await createClient();

  // In a real app, these would be filtered by the officer's jurisdiction/department
  // For MVP, we'll fetch global stats or stats relevant to their role
  
  const { count: pendingCount } = await supabase
    .from("issues")
    .select("*", { count: 'exact', head: true })
    .in("status", ["SUBMITTED", "UNDER_REVIEW"]);

  const { count: emergencyCount } = await supabase
    .from("issues")
    .select("*", { count: 'exact', head: true })
    .eq("priority", "EMERGENCY")
    .not("status", "eq", "RESOLVED")
    .not("status", "eq", "REJECTED");

  const { count: actionRequiredCount } = await supabase
    .from("issues")
    .select("*", { count: 'exact', head: true })
    .in("status", ["VERIFIED", "ASSIGNED", "REOPENED"]);

  // Fetch some recent issues needing attention
  const { data: recentIssues } = await supabase
    .from("issues")
    .select(`
      id, 
      title, 
      status, 
      priority,
      created_at,
      vote_count
    `)
    .in("status", ["SUBMITTED", "UNDER_REVIEW", "VERIFIED", "ASSIGNED", "REOPENED"])
    .order("priority", { ascending: false }) // Postgres enum orders by definition, but in reality we might want a custom sort or use community_priority_score
    .order("created_at", { ascending: false })
    .limit(10);

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Official Dashboard</h1>
        <p className="text-slate-500 mt-2">Manage and resolve civic issues in your jurisdiction.</p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border-l-4 border-l-emergency">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Emergencies</CardTitle>
            <AlertTriangle className="h-4 w-4 text-emergency" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{emergencyCount || 0}</div>
            <p className="text-xs text-slate-500 mt-1">Requires immediate attention</p>
          </CardContent>
        </Card>
        
        <Card className="border-l-4 border-l-amber-500">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Review</CardTitle>
            <Clock className="h-4 w-4 text-amber-500" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{pendingCount || 0}</div>
            <p className="text-xs text-slate-500 mt-1">Newly submitted issues</p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-blue-500">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Action Required</CardTitle>
            <Activity className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{actionRequiredCount || 0}</div>
            <p className="text-xs text-slate-500 mt-1">Verified, waiting for assignment</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-8 md:grid-cols-3">
        <Card className="col-span-2">
          <CardHeader>
            <CardTitle>Priority Queue</CardTitle>
            <CardDescription>Issues requiring attention, sorted by priority.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentIssues?.map((issue) => (
                <div key={issue.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-slate-50">
                  <div className="space-y-1">
                    <Link href={`/admin/issues/${issue.id}`} className="font-medium hover:underline text-slate-900">
                      {issue.title}
                    </Link>
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                      <span>{formatDate(issue.created_at)}</span>
                      <span>•</span>
                      <span className={`font-semibold ${issue.priority === 'EMERGENCY' ? 'text-emergency' : issue.priority === 'HIGH' ? 'text-high' : 'text-normal'}`}>
                        {issue.priority}
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="text-sm font-medium text-slate-600 bg-slate-100 px-2 py-1 rounded">
                      {issue.status.replace(/_/g, ' ')}
                    </div>
                    <Link 
                      href={`/admin/issues/${issue.id}`}
                      className="text-sm text-brand-600 hover:text-brand-700 font-medium"
                    >
                      Manage
                    </Link>
                  </div>
                </div>
              ))}
              {(!recentIssues || recentIssues.length === 0) && (
                <div className="text-center py-8 text-slate-500">
                  <CheckCircle className="w-12 h-12 mx-auto mb-3 text-slate-300" />
                  <p>Queue is empty. Great job!</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <Link href="/admin/issues?status=SUBMITTED" className="flex items-center justify-between p-3 border rounded-lg hover:bg-slate-50">
              <span className="font-medium text-sm">Verify New Issues</span>
              <span className="bg-amber-100 text-amber-800 text-xs py-1 px-2 rounded-full font-bold">{pendingCount || 0}</span>
            </Link>
            <Link href="/admin/issues?status=VERIFIED" className="flex items-center justify-between p-3 border rounded-lg hover:bg-slate-50">
              <span className="font-medium text-sm">Assign Officers</span>
              <span className="bg-blue-100 text-blue-800 text-xs py-1 px-2 rounded-full font-bold">{actionRequiredCount || 0}</span>
            </Link>
            <Link href="/admin/issues?status=RESOLUTION_PENDING_VERIFICATION" className="flex items-center justify-between p-3 border rounded-lg hover:bg-slate-50">
              <span className="font-medium text-sm">Verify Resolutions</span>
              <span className="bg-emerald-100 text-emerald-800 text-xs py-1 px-2 rounded-full font-bold">Review</span>
            </Link>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
