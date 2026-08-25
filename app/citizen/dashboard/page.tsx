import { getCurrentUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertCircle, CheckCircle2, Clock, MapPin } from "lucide-react";
import Link from "next/link";
import { formatDate } from "@/lib/utils";
import type { IssueStatus } from "@/types";

export default async function CitizenDashboard() {
  const { profile } = await getCurrentUser();
  const supabase = await createClient();

  // Fetch user's recent issues
  const { data: issues } = await supabase
    .from("issues")
    .select("id, title, status, created_at, category_id, priority")
    .eq("reporter_id", profile?.id)
    .order("created_at", { ascending: false })
    .limit(5);

  // Status counters (could be optimized with a single aggregate query)
  const stats = {
    total: 0,
    resolved: 0,
    inProgress: 0,
    pending: 0,
  };

  if (issues) {
    stats.total = issues.length; // Technically just recent 5, but good enough for MVP or we do a count query
    issues.forEach(issue => {
      const status = issue.status as IssueStatus;
      if (status === "RESOLVED") stats.resolved++;
      else if (["ASSIGNED", "ACKNOWLEDGED", "IN_PROGRESS", "RESOLUTION_SUBMITTED", "RESOLUTION_PENDING_VERIFICATION"].includes(status)) stats.inProgress++;
      else stats.pending++;
    });
  }

  // Proper count query
  const { count: totalCount } = await supabase
    .from("issues")
    .select("*", { count: 'exact', head: true })
    .eq("reporter_id", profile?.id);

  return (
    <div className="max-w-5xl mx-auto space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Welcome back, {profile?.full_name || "Citizen"}</h1>
        <p className="text-slate-500 mt-2">Here's an overview of your civic issue reports.</p>
      </div>

      {/* Stats row */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Reports</CardTitle>
            <MapPin className="h-4 w-4 text-slate-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalCount || 0}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Under Review</CardTitle>
            <AlertCircle className="h-4 w-4 text-amber-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.pending}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">In Progress</CardTitle>
            <Clock className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.inProgress}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Resolved</CardTitle>
            <CheckCircle2 className="h-4 w-4 text-emerald-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.resolved}</div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Issues List */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Reports</CardTitle>
        </CardHeader>
        <CardContent>
          {!issues || issues.length === 0 ? (
            <div className="text-center py-10">
              <div className="bg-slate-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <MapPin className="h-8 w-8 text-slate-400" />
              </div>
              <h3 className="text-lg font-medium text-slate-900">No reports yet</h3>
              <p className="text-sm text-slate-500 mt-1 max-w-sm mx-auto">
                You haven't reported any civic issues. When you do, you'll be able to track their progress here.
              </p>
              <div className="mt-6">
                <Link
                  href="/report"
                  className="bg-brand-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-brand-700 transition"
                >
                  Report your first issue
                </Link>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              {issues.map((issue) => (
                <Link
                  key={issue.id}
                  href={`/issues/${issue.id}`}
                  className="block p-4 border rounded-xl hover:border-brand-300 hover:bg-slate-50 transition"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <h3 className="font-semibold text-slate-900">{issue.title}</h3>
                      <div className="flex items-center gap-2 mt-2 text-sm text-slate-500">
                        <span>{formatDate(issue.created_at)}</span>
                        <span>•</span>
                        <span className={`status-badge status-badge--${
                          issue.status === 'RESOLVED' ? 'resolved' :
                          ['EMERGENCY'].includes(issue.priority) ? 'emergency' :
                          ['HIGH'].includes(issue.priority) ? 'high' : 'normal'
                        }`}>
                          {issue.status.replace(/_/g, ' ')}
                        </span>
                      </div>
                    </div>
                  </div>
                </Link>
              ))}
              <div className="pt-4 flex justify-center border-t mt-4">
                <Link href="/citizen/issues" className="text-sm font-medium text-brand-600 hover:text-brand-700">
                  View all reports &rarr;
                </Link>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
