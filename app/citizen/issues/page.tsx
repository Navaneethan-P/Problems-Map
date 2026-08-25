import { getCurrentUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatDate } from "@/lib/utils";
import { MapPin, Filter } from "lucide-react";
import type { IssueStatus } from "@/types";

export default async function CitizenIssuesPage({
  searchParams,
}: {
  searchParams: { status?: string; category?: string; sort?: string };
}) {
  const { profile } = await getCurrentUser();
  if (!profile) redirect("/login");

  const supabase = await createClient();

  let query = supabase
    .from("issues")
    .select("*, category:categories(name)")
    .eq("reporter_id", profile.id);

  if (searchParams.status && searchParams.status !== "ALL") {
    if (searchParams.status === "SOLVED") {
      query = query.eq("status", "RESOLVED");
    } else if (searchParams.status === "UNSOLVED") {
      query = query.neq("status", "RESOLVED");
    } else {
      query = query.eq("status", searchParams.status);
    }
  }

  // Handle sorting
  const sort = searchParams.sort || "newest";
  if (sort === "newest") {
    query = query.order("created_at", { ascending: false });
  } else if (sort === "oldest") {
    query = query.order("created_at", { ascending: true });
  } else if (sort === "votes") {
    query = query.order("vote_count", { ascending: false });
  } else {
    query = query.order("created_at", { ascending: false });
  }

  const { data: issues, error } = await query;

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">My Reports</h1>
          <p className="text-slate-500 mt-1">View and filter all your civic issue reports.</p>
        </div>
        <Link
          href="/citizen/report"
          className="bg-brand-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-brand-700 transition shrink-0 text-center"
        >
          + New Report
        </Link>
      </div>

      <Card>
        <CardHeader className="bg-slate-50 border-b pb-4">
          <div className="flex items-center gap-2">
            <Filter className="w-4 h-4 text-slate-500" />
            <CardTitle className="text-sm font-medium">Filters & Sorting</CardTitle>
          </div>
          <form className="flex flex-wrap gap-4 mt-4" method="GET">
            <select
              name="status"
              defaultValue={searchParams.status || "ALL"}
              className="text-sm border rounded-md px-3 py-2 bg-white"
            >
              <option value="ALL">All Statuses</option>
              <option value="UNSOLVED">Unsolved (Pending/InProgress)</option>
              <option value="SOLVED">Solved (Resolved)</option>
              <option value="DRAFT">Drafts</option>
            </select>

            <select
              name="sort"
              defaultValue={searchParams.sort || "newest"}
              className="text-sm border rounded-md px-3 py-2 bg-white"
            >
              <option value="newest">Newest First</option>
              <option value="oldest">Oldest First</option>
              <option value="votes">Most Voted</option>
            </select>

            <button type="submit" className="text-sm bg-slate-900 text-white px-4 py-2 rounded-md font-medium hover:bg-slate-800">
              Apply Filters
            </button>
          </form>
        </CardHeader>
        <CardContent className="p-0">
          {!issues || issues.length === 0 ? (
            <div className="text-center py-12">
              <MapPin className="w-12 h-12 text-slate-300 mx-auto mb-3" />
              <h3 className="text-lg font-medium text-slate-900">No reports found</h3>
              <p className="text-slate-500 mt-1">Try adjusting your filters or report a new issue.</p>
            </div>
          ) : (
            <div className="divide-y">
              {issues.map((issue) => (
                <div key={issue.id} className="p-4 md:p-6 hover:bg-slate-50 transition flex flex-col md:flex-row gap-4 justify-between">
                  <div className="space-y-1">
                    <div className="flex items-center gap-3">
                      <span className={`status-badge status-badge--${
                        issue.status === 'RESOLVED' ? 'resolved' :
                        ['EMERGENCY'].includes(issue.priority) ? 'emergency' :
                        ['HIGH'].includes(issue.priority) ? 'high' : 'normal'
                      }`}>
                        {issue.status.replace(/_/g, ' ')}
                      </span>
                      <span className="text-xs font-medium px-2 py-1 bg-slate-100 text-slate-600 rounded-md">
                        {issue.priority}
                      </span>
                    </div>
                    <h3 className="font-semibold text-lg text-slate-900 mt-2">{issue.title}</h3>
                    <p className="text-slate-600 text-sm line-clamp-2 max-w-2xl">{issue.description}</p>
                    <div className="flex items-center gap-3 text-xs text-slate-500 pt-2">
                      <span>{formatDate(issue.created_at)}</span>
                      <span>•</span>
                      <span>{(issue.category as any)?.name || 'Uncategorized'}</span>
                      <span>•</span>
                      <span>{issue.vote_count} votes</span>
                    </div>
                  </div>
                  <div className="flex items-center md:items-start shrink-0 pt-2 md:pt-0">
                    <Link
                      href={`/issues/${issue.id}`}
                      className="text-sm font-medium text-brand-600 border border-brand-200 bg-brand-50 hover:bg-brand-100 px-4 py-2 rounded-lg transition text-center whitespace-nowrap"
                    >
                      View Details
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
