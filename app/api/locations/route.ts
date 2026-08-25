import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const type = searchParams.get("type"); // 'country', 'state', 'district', 'municipality'
    const parentId = searchParams.get("parentId");

    if (!type || !["country", "state", "district", "municipality"].includes(type)) {
      return NextResponse.json({ error: "Invalid location type" }, { status: 400 });
    }

    const supabase = await createClient();

    // Call the RPC function we created in Migration 015
    const { data, error } = await supabase.rpc("get_locations", {
      p_type: type,
      p_parent_id: parentId || null,
    });

    if (error) {
      console.error("Locations API error:", error);
      return NextResponse.json(
        { error: "Failed to fetch locations" },
        { status: 500 }
      );
    }

    return NextResponse.json({ data });
  } catch (err) {
    console.error("Locations API unhandled error:", err);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
