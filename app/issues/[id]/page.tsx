import { getCurrentUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { formatDate } from "@/lib/utils";
import { MapPin, Clock, Camera, AlertCircle, Shield, MessageSquare } from "lucide-react";
import { ResolutionForm } from "@/components/issues/resolution-form";
import { VerificationForm } from "@/components/issues/verification-form";
import { IssueStatus } from "@/types";

export default async function IssueDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const issueId = (await params).id;
  const { profile } = await getCurrentUser();
  const supabase = await createClient();

  // Fetch issue details
  const { data: issue, error } = await supabase
    .from("issues")
    .select(`
      *,
      reporter:profiles!reporter_id(full_name, avatar_url),
      category:categories(name, icon),
      media:issue_media(*),
      history:issue_status_history(
        *,
        actor:profiles(full_name, role)
      ),
      responses:issue_responses(
        *,
        author:profiles(full_name, role)
      )
    `)
    .eq("id", issueId)
    .single();

  if (error || !issue) {
    notFound();
  }

  // Determine permissions
  const isReporter = profile?.id === issue.reporter_id;
  const isOfficial = profile && ["VERIFIER", "OFFICER", "MLA", "DISTRICT_ADMIN", "STATE_ADMIN", "SUPER_ADMIN"].includes(profile.role);
  
  // Need to use explicit type assertions for joined data from Supabase
  const category = issue.category as any;
  const reporter = issue.reporter as any;
  const media = (issue.media as any[]) || [];
  const responses = (issue.responses as any[]) || [];
  
  // Sort history newest first
  const history = ((issue.history as any[]) || []).sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  );

  return (
    <div className="min-h-screen bg-slate-50 pb-20">
      {/* Header */}
      <header className="bg-white border-b sticky top-0 z-20">
        <div className="max-w-5xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <span className={`status-badge status-badge--${
              issue.status === 'RESOLVED' ? 'resolved' :
              ['EMERGENCY'].includes(issue.priority) ? 'emergency' :
              ['HIGH'].includes(issue.priority) ? 'high' : 'normal'
            }`}>
              {issue.status.replace(/_/g, ' ')}
            </span>
            <span className="text-sm font-mono text-slate-500 hidden md:inline-block">
              ID: {issue.id.split('-')[0]}
            </span>
          </div>
          
          {isOfficial && (
            <div className="flex items-center gap-2">
               {/* Admin controls would be client components imported here */}
               <div className="bg-brand-50 border border-brand-200 text-brand-700 px-3 py-1.5 rounded-lg text-sm font-medium flex items-center gap-1">
                 <Shield className="w-4 h-4" /> Official Tools Available
               </div>
            </div>
          )}
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-4 py-8 grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column: Details */}
        <div className="lg:col-span-2 space-y-8">
          <div>
            <div className="flex items-center gap-2 text-brand-600 font-medium mb-2">
              <AlertCircle className="w-5 h-5" />
              {category?.name || "Uncategorized"}
            </div>
            <h1 className="text-3xl font-bold text-slate-900 mb-4">{issue.title}</h1>
            
            <div className="flex items-center gap-4 text-sm text-slate-500 mb-6">
              <div className="flex items-center gap-1">
                <Clock className="w-4 h-4" />
                {formatDate(issue.created_at)}
              </div>
              <div>•</div>
              <div className="flex items-center gap-1">
                Reported by {reporter?.full_name || "Anonymous Citizen"}
              </div>
            </div>

            <div className="prose prose-slate max-w-none bg-white p-6 rounded-xl border shadow-sm">
              <p className="whitespace-pre-wrap">{issue.description}</p>
            </div>
          </div>

          {/* Media Gallery */}
          {media.length > 0 && (
            <div>
              <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                <Camera className="w-5 h-5 text-slate-500" />
                Evidence
              </h3>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {media.map((item) => (
                  <div key={item.id} className="relative aspect-square rounded-xl overflow-hidden border bg-slate-100">
                    {item.media_type === "image" ? (
                      /* eslint-disable-next-line @next/next/no-img-element */
                      <img 
                        src={item.public_url} 
                        alt="Evidence" 
                        className="object-cover w-full h-full cursor-zoom-in"
                      />
                    ) : (
                      <video src={item.public_url} controls className="object-cover w-full h-full" />
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Official Responses */}
          {responses.length > 0 && (
            <div>
              <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                <MessageSquare className="w-5 h-5 text-slate-500" />
                Updates
              </h3>
              <div className="space-y-4">
                {responses
                  .filter(r => isOfficial || r.visibility === "PUBLIC_RESPONSE")
                  .map(response => (
                  <div key={response.id} className={`p-4 rounded-xl border ${response.visibility === 'INTERNAL_NOTE' ? 'bg-amber-50 border-amber-200' : 'bg-brand-50 border-brand-200'}`}>
                    <div className="flex items-center justify-between mb-2">
                      <div className="font-semibold flex items-center gap-2">
                        {response.author?.full_name}
                        {response.visibility === "INTERNAL_NOTE" && (
                          <span className="text-[10px] bg-amber-200 text-amber-800 px-2 py-0.5 rounded uppercase font-bold tracking-wider">Internal Note</span>
                        )}
                      </div>
                      <span className="text-xs text-slate-500">{formatDate(response.created_at)}</span>
                    </div>
                    <p className="text-slate-800 whitespace-pre-wrap">{response.content}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Resolution Submission Form (Only for officials when issue is IN_PROGRESS) */}
          {isOfficial && ["ASSIGNED", "IN_PROGRESS"].includes(issue.status) && (
            <ResolutionForm issueId={issue.id} />
          )}

          {/* Verification Form (Only for officials when issue is RESOLUTION_SUBMITTED) */}
          {isOfficial && issue.status === "RESOLUTION_SUBMITTED" && (
            <VerificationForm issueId={issue.id} versionNumber={issue.version_number} />
          )}
        </div>

        {/* Right Column: Sidebar (Map & Status) */}
        <div className="space-y-6">
          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-sm flex items-center gap-2">
                <MapPin className="w-4 h-4 text-slate-500" />
                Location
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0 h-64 relative rounded-b-xl overflow-hidden">
               {/* Client component MapLibre wrapper */}
               {/* We just need a static or non-interactive map centered on the issue */}
               {/* Due to Next.js restrictions, we might need a small wrapper component for this */}
               <div className="w-full h-full bg-slate-200 flex flex-col items-center justify-center text-slate-400">
                 {/* Mock for SSR before hydrating actual map */}
                 <MapPin className="w-8 h-8 mb-2" />
                 <span>{issue.latitude.toFixed(4)}, {issue.longitude.toFixed(4)}</span>
               </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="timeline">
                {history.map((h, i) => (
                  <div key={h.id} className="timeline-item">
                    <div className="text-sm font-semibold">{h.to_status.replace(/_/g, ' ')}</div>
                    <div className="text-xs text-slate-500 mt-1">
                      {formatDate(h.created_at)}
                      {h.actor?.full_name ? ` • by ${h.actor.full_name}` : ''}
                    </div>
                  </div>
                ))}
                {/* Initial state if not in history */}
                <div className="timeline-item">
                  <div className="text-sm font-semibold">REPORT SUBMITTED</div>
                  <div className="text-xs text-slate-500 mt-1">{formatDate(issue.created_at)}</div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
}
