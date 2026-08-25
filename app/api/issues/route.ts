import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { CreateIssueSchema } from "@/schemas";
import { determinePriority, calculateLocationConfidence } from "@/lib/workflow/state-machine";

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Ensure user is authenticated
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const parsed = CreateIssueSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Validation failed", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const data = parsed.data;

    // Call rules engine for derived fields
    const priority = determinePriority(data.category_id); // In real app, we might need category slug instead of ID
    
    let location_confidence = null;
    let gps_accuracy = data.gps_accuracy;
    
    if (gps_accuracy !== undefined) {
      const captureTime = data.capture_timestamp
        ? new Date(data.capture_timestamp).getTime()
        : null;
      
      const confResult = calculateLocationConfidence(
        gps_accuracy,
        captureTime
      );
      location_confidence = confResult.confidence;
    }

    // Insert issue
    const { data: issue, error: issueError } = await supabase
      .from("issues")
      .insert({
        reporter_id: user.id,
        issue_source: "CITIZEN",
        title: data.title,
        description: data.description,
        category_id: data.category_id,
        latitude: data.latitude,
        longitude: data.longitude,
        gps_accuracy,
        location_confidence,
        capture_timestamp: data.capture_timestamp,
        priority,
        status: "SUBMITTED",
        parent_issue_id: data.parent_issue_id,
      })
      .select()
      .single();

    if (issueError) {
      console.error("Issue creation error:", issueError);
      return NextResponse.json(
        { error: "Failed to create issue" },
        { status: 500 }
      );
    }

    // Link media if any
    if (data.media_ids && data.media_ids.length > 0) {
      const { error: mediaError } = await supabase
        .from("issue_media")
        .update({ issue_id: issue.id })
        .in("id", data.media_ids);

      if (mediaError) {
        console.error("Media linking error:", mediaError);
        // We don't fail the whole request, but log it.
      }
    }

    return NextResponse.json({ data: issue }, { status: 201 });
  } catch (error) {
    console.error("Unhandled error creating issue:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
