import { Loader2 } from "lucide-react";

export default function Loading() {
  return (
    <div className="flex h-full w-full items-center justify-center p-8">
      <div className="flex flex-col items-center gap-2 text-brand-600">
        <Loader2 className="w-8 h-8 animate-spin" />
        <p className="text-sm font-medium">Loading...</p>
      </div>
    </div>
  );
}
