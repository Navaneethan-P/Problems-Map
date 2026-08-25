import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Check auth
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const formData = await request.formData();
    const file = formData.get("file") as File;
    const mediaSource = formData.get("media_source") as string;
    const isResolutionEvidence = formData.get("is_resolution_evidence") === "true";

    if (!file) {
      return NextResponse.json({ error: "No file provided" }, { status: 400 });
    }

    // Basic validation
    const validTypes = ["image/jpeg", "image/png", "image/webp", "video/mp4"];
    if (!validTypes.includes(file.type)) {
      return NextResponse.json(
        { error: "Invalid file type. Supported: JPG, PNG, WEBP, MP4" },
        { status: 400 }
      );
    }

    if (file.size > 20 * 1024 * 1024) { // 20MB limit
      return NextResponse.json(
        { error: "File too large. Maximum size is 20MB." },
        { status: 400 }
      );
    }

    // Upload to Supabase Storage
    const fileExt = file.name.split(".").pop();
    const fileName = `${user.id}/${Date.now()}-${Math.random()
      .toString(36)
      .substring(2, 9)}.${fileExt}`;

    const { data: storageData, error: storageError } = await supabase.storage
      .from("issue-media")
      .upload(fileName, file, {
        cacheControl: "3600",
        upsert: false,
      });

    if (storageError) {
      console.error("Storage error:", storageError);
      return NextResponse.json(
        { error: "Failed to upload file to storage" },
        { status: 500 }
      );
    }

    const { data: publicUrlData } = supabase.storage
      .from("issue-media")
      .getPublicUrl(fileName);

    // Create record in issue_media table (issue_id will be linked later when issue is saved)
    const { data: mediaRecord, error: dbError } = await supabase
      .from("issue_media")
      .insert({
        uploader_id: user.id,
        storage_path: fileName,
        public_url: publicUrlData.publicUrl,
        media_type: file.type.startsWith("image/") ? "image" : "video",
        mime_type: file.type,
        file_size_bytes: file.size,
        media_source: mediaSource || "UPLOADED",
        is_resolution_evidence: isResolutionEvidence,
      })
      .select()
      .single();

    if (dbError) {
      console.error("DB insert error:", dbError);
      // Try to clean up storage if DB insert fails
      await supabase.storage.from("issue-media").remove([fileName]);
      return NextResponse.json(
        { error: "Failed to create media record" },
        { status: 500 }
      );
    }

    return NextResponse.json({ data: mediaRecord }, { status: 201 });
  } catch (error) {
    console.error("Unhandled error uploading file:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
