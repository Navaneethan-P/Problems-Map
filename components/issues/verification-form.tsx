"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Loader2, ShieldCheck, XCircle, CheckCircle } from "lucide-react";

export function VerificationForm({ 
  issueId, 
  versionNumber 
}: { 
  issueId: string;
  versionNumber: number;
}) {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [note, setNote] = useState("");
  const [actionType, setActionType] = useState<"APPROVE" | "REJECT" | null>(null);

  async function handleVerification(action: "APPROVE" | "REJECT") {
    if (action === "REJECT" && !note.trim()) {
      toast.error("A rejection reason is required.");
      return;
    }

    setIsSubmitting(true);
    setActionType(action);

    try {
      const newStatus = action === "APPROVE" ? "RESOLVED" : "IN_PROGRESS";
      
      const payload: any = {
        new_status: newStatus,
        version_number: versionNumber,
        reason: note,
      };

      if (action === "REJECT") {
        payload.rejection_reason = "INCOMPLETE_WORK";
        payload.rejection_note = note;
      }

      const res = await fetch(`/api/issues/${issueId}/status`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || "Failed to verify resolution");
      }

      toast.success(action === "APPROVE" ? "Issue marked as resolved!" : "Resolution rejected. Issue sent back.");
      setNote("");
      router.refresh();
    } catch (err: any) {
      toast.error(err.message || "An error occurred");
    } finally {
      setIsSubmitting(false);
      setActionType(null);
    }
  }

  return (
    <Card className="border-blue-200 shadow-sm mt-8">
      <CardHeader className="bg-blue-50 border-b border-blue-100 pb-4">
        <CardTitle className="text-blue-800 flex items-center gap-2">
          <ShieldCheck className="w-5 h-5" />
          Verify Resolution
        </CardTitle>
        <CardDescription className="text-blue-700">
          Review the submitted evidence and approve or reject the resolution.
        </CardDescription>
      </CardHeader>
      <CardContent className="pt-6 space-y-4">
        <div>
          <label className="text-sm font-medium mb-2 block">Verification Note (Required for rejection)</label>
          <Textarea 
            placeholder="Add comments about the verification..."
            value={note}
            onChange={(e) => setNote(e.target.value)}
            disabled={isSubmitting}
          />
        </div>
        
        <div className="flex gap-4 pt-2">
          <Button 
            variant="outline" 
            className="w-full border-red-200 text-red-600 hover:bg-red-50 hover:text-red-700"
            onClick={() => handleVerification("REJECT")}
            disabled={isSubmitting}
          >
            {isSubmitting && actionType === "REJECT" ? (
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
            ) : (
              <XCircle className="w-4 h-4 mr-2" />
            )}
            Reject & Reopen
          </Button>

          <Button 
            className="w-full bg-blue-600 hover:bg-blue-700"
            onClick={() => handleVerification("APPROVE")}
            disabled={isSubmitting}
          >
            {isSubmitting && actionType === "APPROVE" ? (
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
            ) : (
              <CheckCircle className="w-4 h-4 mr-2" />
            )}
            Approve Resolution
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
