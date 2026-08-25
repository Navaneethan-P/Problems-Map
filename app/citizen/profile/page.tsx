import { getCurrentUser } from "@/lib/auth";
import { redirect } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { User, Phone, Shield, Calendar } from "lucide-react";
import { formatDate } from "@/lib/utils";

export default async function CitizenProfilePage() {
  const { profile } = await getCurrentUser();
  if (!profile) redirect("/login");

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Profile</h1>
        <p className="text-slate-500 mt-1">Manage your account and view your civic reputation.</p>
      </div>

      <Card>
        <CardHeader className="bg-slate-50 border-b">
          <div className="flex items-center gap-4">
            <div className="h-16 w-16 bg-brand-100 text-brand-700 flex items-center justify-center rounded-full text-2xl font-bold border-2 border-brand-200 shadow-sm">
              {profile.full_name ? profile.full_name[0].toUpperCase() : "U"}
            </div>
            <div>
              <CardTitle className="text-xl">{profile.full_name || "Anonymous Citizen"}</CardTitle>
              <CardDescription className="flex items-center gap-2 mt-1">
                <span className={`px-2 py-0.5 rounded text-xs font-semibold ${
                  profile.account_status === 'ACTIVE' ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'
                }`}>
                  {profile.account_status}
                </span>
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-6 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <h3 className="font-semibold text-sm text-slate-900 border-b pb-2">Account Details</h3>
              
              <div className="flex items-center gap-3 text-slate-700">
                <User className="w-5 h-5 text-slate-400" />
                <div>
                  <p className="text-xs text-slate-500 font-medium">Full Name</p>
                  <p className="font-medium">{profile.full_name || "Not provided"}</p>
                </div>
              </div>

              <div className="flex items-center gap-3 text-slate-700">
                <Phone className="w-5 h-5 text-slate-400" />
                <div>
                  <p className="text-xs text-slate-500 font-medium">Phone Number</p>
                  <p className="font-medium">{profile.phone || "Not provided"}</p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="font-semibold text-sm text-slate-900 border-b pb-2">System Information</h3>
              
              <div className="flex items-center gap-3 text-slate-700">
                <Shield className="w-5 h-5 text-slate-400" />
                <div>
                  <p className="text-xs text-slate-500 font-medium">Access Role</p>
                  <p className="font-medium">{profile.role}</p>
                </div>
              </div>

              <div className="flex items-center gap-3 text-slate-700">
                <Calendar className="w-5 h-5 text-slate-400" />
                <div>
                  <p className="text-xs text-slate-500 font-medium">Member Since</p>
                  <p className="font-medium">{formatDate(profile.created_at)}</p>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
