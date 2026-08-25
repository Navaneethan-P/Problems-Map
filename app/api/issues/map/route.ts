import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { MapQuerySchema } from "@/schemas";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const query = {
      west: searchParams.get("west"),
      south: searchParams.get("south"),
      east: searchParams.get("east"),
      north: searchParams.get("north"),
      status: searchParams.get("status") || undefined,
      priority: searchParams.get("priority") || undefined,
      category_id: searchParams.get("category_id") || undefined,
      department_id: searchParams.get("department_id") || undefined,
    };

    const parsed = MapQuerySchema.safeParse(query);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid bounding box parameters", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const { west, south, east, north, status, priority, category_id, department_id } =
      parsed.data;

    // Convert comma-separated string to arrays for SQL IN clauses if provided
    const statusArray = status ? status.split(",") : null;
    const priorityArray = priority ? priority.split(",") : null;

    const supabase = await createClient();

    // Call the Postgres function we created in Migration 011
    const { data, error } = await supabase.rpc("get_issues_in_bbox", {
      west,
      south,
      east,
      north,
      p_status: statusArray,
      p_priority: priorityArray,
      p_category_id: category_id || null,
      p_department_id: department_id || null,
      p_limit: 500, // Hard limit to prevent massive payload
    });

    if (error) {
      console.error("Map query error:", error);
      return NextResponse.json(
        { error: "Failed to fetch map data" },
        { status: 500 }
      );
    }

    return NextResponse.json({ data });
  } catch (err) {
    console.error("Map query unhandled error:", err);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
