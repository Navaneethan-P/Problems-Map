"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ResolutionEvidenceSchema, type ResolutionEvidenceInput } from "@/schemas";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Upload, Loader2, CheckCircle2 } from "lucide-react";

export function ResolutionForm({ issueId }: { issueId: string }) {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [beforeFile, setBeforeFile] = useState<File | null>(null);
  const [afterFile, setAfterFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);

  const form = useForm<ResolutionEvidenceInput>({
    resolver: zodResolver(ResolutionEvidenceSchema),
    defaultValues: {
      work_description: "",
      field_report: "",
      before_media_path: null,
      after_media_path: null,
    },
  });

  const uploadFile = async (file: File) => {
    const formData = new FormData();
    formData.append("file", file);
    formData.append("media_source", "UPLOADED");
    formData.append("is_resolution_evidence", "true");

    const res = await fetch("/api/upload", {
      method: "POST",
      body: formData,
    });

    if (!res.ok) throw new Error("Failed to upload file");
    const json = await res.json();
    return json.data.storage_path;
  };

  async function onSubmit(data: ResolutionEvidenceInput) {
    setIsSubmitting(true);
    setIsUploading(true);

    try {
      let beforePath = null;
      let afterPath = null;

      // Upload files first if they exist
      if (beforeFile) {
        beforePath = await uploadFile(beforeFile);
      }
      if (afterFile) {
        afterPath = await uploadFile(afterFile);
      }

      setIsUploading(false);

      // Submit resolution evidence
      const payload = {
        ...data,
        before_media_path: beforePath,
        after_media_path: afterPath,
      };

      const res = await fetch(`/api/issues/${issueId}/resolve`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || "Failed to submit resolution");
      }

      toast.success("Resolution evidence submitted for verification.");
      router.refresh();
    } catch (err: any) {
      toast.error(err.message || "An error occurred");
      setIsSubmitting(false);
      setIsUploading(false);
    }
  }

  return (
    <Card className="border-emerald-200 shadow-sm mt-8">
      <CardHeader className="bg-emerald-50 border-b border-emerald-100 pb-4">
        <CardTitle className="text-emerald-800 flex items-center gap-2">
          <CheckCircle2 className="w-5 h-5" />
          Submit Resolution Evidence
        </CardTitle>
        <CardDescription className="text-emerald-700">
          Document the work completed to resolve this issue. This will be sent for verification.
        </CardDescription>
      </CardHeader>
      <CardContent className="pt-6">
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="work_description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Work Description</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Describe exactly what was done to fix the problem..."
                      className="min-h-[100px]"
                      {...field} 
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
              <div>
                <FormLabel className="mb-2 block">Before Photo (Optional)</FormLabel>
                <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-slate-300 rounded-lg cursor-pointer bg-slate-50 hover:bg-slate-100 overflow-hidden relative">
                  {beforeFile ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={URL.createObjectURL(beforeFile)} alt="Before" className="object-cover w-full h-full opacity-50" />
                  ) : (
                    <div className="flex flex-col items-center justify-center pt-5 pb-6">
                      <Upload className="w-6 h-6 text-slate-400 mb-2" />
                      <p className="text-sm text-slate-500 font-medium">Click to upload</p>
                    </div>
                  )}
                  <input type="file" className="hidden" accept="image/*" onChange={(e) => {
                    if (e.target.files?.[0]) setBeforeFile(e.target.files[0]);
                  }} />
                  {beforeFile && <div className="absolute inset-0 flex items-center justify-center font-bold text-slate-800 bg-white/40">{beforeFile.name}</div>}
                </label>
              </div>

              <div>
                <FormLabel className="mb-2 block">After Photo (Recommended)</FormLabel>
                <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-emerald-300 rounded-lg cursor-pointer bg-emerald-50 hover:bg-emerald-100 overflow-hidden relative">
                  {afterFile ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={URL.createObjectURL(afterFile)} alt="After" className="object-cover w-full h-full opacity-50" />
                  ) : (
                    <div className="flex flex-col items-center justify-center pt-5 pb-6 text-emerald-600">
                      <Upload className="w-6 h-6 mb-2" />
                      <p className="text-sm font-medium">Click to upload evidence</p>
                    </div>
                  )}
                  <input type="file" className="hidden" accept="image/*" onChange={(e) => {
                    if (e.target.files?.[0]) setAfterFile(e.target.files[0]);
                  }} />
                  {afterFile && <div className="absolute inset-0 flex items-center justify-center font-bold text-slate-800 bg-white/40">{afterFile.name}</div>}
                </label>
              </div>
            </div>

            <Button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-700" disabled={isSubmitting}>
              {isSubmitting ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : null}
              {isUploading ? "Uploading Evidence..." : "Submit Resolution"}
            </Button>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
