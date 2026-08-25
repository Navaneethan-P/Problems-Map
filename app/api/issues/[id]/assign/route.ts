import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { AssignmentSchema } from "@/schemas";
import { requireRole } from "@/lib/auth";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const issueId = (await params).id;
    
    // Only officers and above can assign
    const isAuthorized = await requireRole("OFFICER");
    if (!isAuthorized) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
    }

    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    const body = await request.json();
    const parsed = AssignmentSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid payload", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const data = parsed.data;

    // 1. Deactivate old assignments
    await supabase
      .from("issue_assignments")
      .update({ is_active: false })
      .eq("issue_id", issueId);

    // 2. Create new assignment
    const { data: assignment, error: assignError } = await supabase
      .from("issue_assignments")
      .insert({
        issue_id: issueId,
        department_id: data.department_id,
        officer_id: data.officer_id || null,
        assigned_by: user!.id,
        assignment_notes: data.assignment_notes,
        deadline: data.deadline,
        is_active: true,
      })
      .select()
      .single();

    if (assignError) {
      console.error("Assignment error:", assignError);
      return NextResponse.json(
        { error: "Failed to assign issue" },
        { status: 500 }
      );
    }

    // 3. Update the issue record denormalized fields
    await supabase
      .from("issues")
      .update({
        responsible_department_id: data.department_id,
        assigned_officer_id: data.officer_id || null,
        // Also update status to ASSIGNED if it's VERIFIED
        // We'd ideally check current status, but for MVP:
      })
      .eq("id", issueId);

    // Create a system note
    await supabase.from("issue_responses").insert({
      issue_id: issueId,
      author_id: user!.id,
      content: `Issue assigned to department. ${data.assignment_notes || ""}`,
      visibility: "INTERNAL_NOTE"
    });

    return NextResponse.json({ data: assignment });
  } catch (error) {
    console.error("Unhandled assignment error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
