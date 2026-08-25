import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { StatusChangeSchema } from "@/schemas";
import { validateTransition } from "@/lib/workflow/state-machine";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const issueId = (await params).id;
    const supabase = await createClient();

    // 1. Auth check
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return NextResponse.json({ error: "Profile not found" }, { status: 401 });
    }

    // 2. Parse payload
    const body = await request.json();
    const parsed = StatusChangeSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid payload", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const { new_status, reason, version_number, rejection_reason, rejection_note } = parsed.data;

    // 3. Fetch current issue state
    const { data: issue, error: issueError } = await supabase
      .from("issues")
      .select("status, version_number, reporter_id")
      .eq("id", issueId)
      .single();

    if (issueError || !issue) {
      return NextResponse.json({ error: "Issue not found" }, { status: 404 });
    }

    // 4. Optimistic Concurrency Control (OCC)
    if (issue.version_number !== version_number) {
      return NextResponse.json(
        { error: "Conflict: The issue has been updated by someone else. Please refresh." },
        { status: 409 }
      );
    }

    // 5. State Machine Validation
    const validation = validateTransition(
      issue.status,
      new_status,
      profile.role
    );

    if (!validation.valid) {
      return NextResponse.json(
        { error: validation.error },
        { status: 403 }
      );
    }

    // 6. Execute update
    // The database function `update_issue_status` (from our migrations) handles
    // the version increment and inserting into `issue_status_history`.
    // We call it via RPC to ensure atomicity.
    
    // Wait, in migration 008, I didn't create `update_issue_status` RPC, 
    // I created triggers `trg_issue_status_change` which automatically inserts into `issue_status_history`!
    // So we just update the `issues` table.

    const updatePayload: any = {
      status: new_status,
      version_number: version_number + 1,
    };

    if (new_status === "REJECTED") {
      updatePayload.rejection_reason = rejection_reason;
      updatePayload.rejection_note = rejection_note;
    }

    // If it's a verification step, record who verified
    if (new_status === "VERIFIED") {
      updatePayload.verification_status = "VERIFIED";
      updatePayload.verification_method = "OFFICER";
      updatePayload.verified_by = user.id;
      updatePayload.verified_at = new Date().toISOString();
    }

    // Status timestamps handled by triggers usually, but we can set them explicitly if we didn't add triggers for them all
    // Let's rely on standard updates

    const { data: updatedIssue, error: updateError } = await supabase
      .from("issues")
      .update(updatePayload)
      .eq("id", issueId)
      .eq("version_number", version_number) // Extra safety
      .select()
      .single();

    if (updateError) {
      console.error("Update error:", updateError);
      return NextResponse.json(
        { error: "Failed to update issue status" },
        { status: 500 }
      );
    }

    // Now insert the history record explicitly since the trigger requires some fields like `reason` which we want to supply
    // Actually, trigger handles it, but we might want to attach notes.
    // Let's insert a response/note if reason was provided.
    if (reason) {
       await supabase.from("issue_responses").insert({
         issue_id: issueId,
         author_id: user.id,
         content: `Status changed to ${new_status}. ${reason}`,
         visibility: "PUBLIC_RESPONSE"
       });
    }

    return NextResponse.json({ data: updatedIssue });
  } catch (error) {
    console.error("Unhandled status change error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
