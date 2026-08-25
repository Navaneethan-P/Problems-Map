import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { ResolutionEvidenceSchema } from "@/schemas";
import { requireRole } from "@/lib/auth";
import { validateTransition } from "@/lib/workflow/state-machine";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const issueId = (await params).id;

    // Only officers and above can submit resolution evidence
    const isAuthorized = await requireRole("OFFICER");
    if (!isAuthorized) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
    }

    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user!.id)
      .single();

    const body = await request.json();
    const parsed = ResolutionEvidenceSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid payload", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const data = parsed.data;

    // 1. Fetch current issue state to enforce state machine rules
    const { data: issue, error: issueError } = await supabase
      .from("issues")
      .select("status, version_number")
      .eq("id", issueId)
      .single();

    if (issueError || !issue) {
      return NextResponse.json({ error: "Issue not found" }, { status: 404 });
    }

    // 2. Validate state transition to RESOLUTION_SUBMITTED
    const newStatus = "RESOLUTION_SUBMITTED";
    const validation = validateTransition(
      issue.status,
      newStatus,
      profile!.role
    );

    if (!validation.valid) {
      return NextResponse.json({ error: validation.error }, { status: 403 });
    }

    // 3. Insert resolution evidence
    // We assume media paths exist in Supabase storage and they were already uploaded via our upload API.
    // If we wanted to strictly enforce link, we'd verify them here.
    const { data: evidence, error: evidenceError } = await supabase
      .from("issue_resolution_evidence")
      .insert({
        issue_id: issueId,
        submitted_by: user!.id,
        work_description: data.work_description,
        field_report: data.field_report || null,
        before_media_path: data.before_media_path || null,
        after_media_path: data.after_media_path || null,
        document_path: data.document_path || null,
        resolution_latitude: data.resolution_latitude || null,
        resolution_longitude: data.resolution_longitude || null,
      })
      .select()
      .single();

    if (evidenceError) {
      console.error("Evidence insertion error:", evidenceError);
      return NextResponse.json(
        { error: "Failed to submit resolution evidence" },
        { status: 500 }
      );
    }

    // 4. Update the issue status
    const { data: updatedIssue, error: updateError } = await supabase
      .from("issues")
      .update({
        status: newStatus,
        resolution_submitted_at: new Date().toISOString(),
        version_number: issue.version_number + 1,
      })
      .eq("id", issueId)
      .eq("version_number", issue.version_number) // OCC check
      .select()
      .single();

    if (updateError) {
      console.error("Issue update error:", updateError);
      // NOTE: In production we'd want this in a transaction. We could use an RPC.
      // But for MVP, this is sufficient.
      return NextResponse.json(
        { error: "Failed to update issue status" },
        { status: 500 }
      );
    }

    // 5. Add an official response to the timeline
    await supabase.from("issue_responses").insert({
      issue_id: issueId,
      author_id: user!.id,
      content: `Resolution evidence submitted: ${data.work_description.slice(0, 100)}${data.work_description.length > 100 ? "..." : ""}`,
      visibility: "PUBLIC_RESPONSE",
    });

    return NextResponse.json({ data: { issue: updatedIssue, evidence } });
  } catch (error) {
    console.error("Unhandled resolution error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
