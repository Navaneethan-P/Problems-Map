"use client";

import { useState, useRef, useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { CreateIssueSchema, type CreateIssueInput } from "@/schemas";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
import { MapView } from "@/components/map/map-view";
import maplibregl from "maplibre-gl";

import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Camera, MapPin, CheckCircle2, ChevronRight, ChevronLeft, Upload, Loader2, LocateFixed, FileText } from "lucide-react";

type Step = 1 | 2 | 3;

export default function ReportIssuePage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [mapInstance, setMapInstance] = useState<maplibregl.Map | null>(null);
  const markerRef = useRef<maplibregl.Marker | null>(null);
  const [mediaFiles, setMediaFiles] = useState<File[]>([]);
  const [mediaIds, setMediaIds] = useState<string[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [locating, setLocating] = useState(false);
  const [categories, setCategories] = useState<{id: string, name: string}[]>([]);

  // Fetch categories on mount
  useEffect(() => {
    async function fetchCategories() {
      // Basic fetch, in production use react-query
      try {
        // We'll hardcode some for MVP if the endpoint isn't ready
        // But let's assume we have them or we can just fetch from a public endpoint
        // For MVP frontend, we will mock them if they fail, or you can implement the API route.
        const res = await fetch("/api/categories");
        if (res.ok) {
          const data = await res.json();
          setCategories(data);
        } else {
          // Fallback demo categories
          setCategories([
            { id: "11111111-1111-1111-1111-111111111111", name: "Road Damage" },
            { id: "22222222-2222-2222-2222-222222222222", name: "Water Supply" },
            { id: "33333333-3333-3333-3333-333333333333", name: "Electricity" },
            { id: "44444444-4444-4444-4444-444444444444", name: "Sanitation & Garbage" },
          ]);
        }
      } catch {
         setCategories([
            { id: "11111111-1111-1111-1111-111111111111", name: "Road Damage" },
            { id: "22222222-2222-2222-2222-222222222222", name: "Water Supply" },
            { id: "33333333-3333-3333-3333-333333333333", name: "Electricity" },
            { id: "44444444-4444-4444-4444-444444444444", name: "Sanitation & Garbage" },
          ]);
      }
    }
    fetchCategories();
  }, []);

  const form = useForm<CreateIssueInput>({
    resolver: zodResolver(CreateIssueSchema),
    defaultValues: {
      title: "",
      description: "",
      category_id: "",
      latitude: 11.1271, // default
      longitude: 78.6569, // default
      gps_accuracy: 100, // default assumption
      media_ids: [],
    },
  });

  // Handle Map Interactions
  useEffect(() => {
    if (!mapInstance) return;

    const map = mapInstance;

    // Create marker if it doesn't exist
    if (!markerRef.current) {
      const el = document.createElement("div");
      el.className = "text-brand-600 drop-shadow-md";
      el.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 24 24" fill="currentColor" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>`;
      
      markerRef.current = new maplibregl.Marker({
        element: el,
        draggable: true,
        anchor: 'bottom'
      })
        .setLngLat([form.getValues("longitude"), form.getValues("latitude")])
        .addTo(map);

      // Listen to drag events
      markerRef.current.on('dragend', () => {
        const lngLat = markerRef.current!.getLngLat();
        form.setValue("longitude", lngLat.lng);
        form.setValue("latitude", lngLat.lat);
      });
    }

    // Click on map to move marker
    const clickHandler = (e: maplibregl.MapMouseEvent) => {
      markerRef.current?.setLngLat(e.lngLat);
      form.setValue("longitude", e.lngLat.lng);
      form.setValue("latitude", e.lngLat.lat);
    };

    map.on("click", clickHandler);

    return () => {
      map.off("click", clickHandler);
    };
  }, [mapInstance, form]);

  const handleGeolocate = () => {
    setLocating(true);
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude, accuracy } = position.coords;
          
          form.setValue("latitude", latitude);
          form.setValue("longitude", longitude);
          form.setValue("gps_accuracy", accuracy);
          form.setValue("capture_timestamp", new Date(position.timestamp).toISOString());
          
          if (mapInstance && markerRef.current) {
            markerRef.current.setLngLat([longitude, latitude]);
            mapInstance.flyTo({ center: [longitude, latitude], zoom: 15 });
          }
          setLocating(false);
          toast.success("Location found");
        },
        (error) => {
          console.error(error);
          setLocating(false);
          toast.error("Could not get your location");
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    } else {
      setLocating(false);
      toast.error("Geolocation not supported by your browser");
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    setIsUploading(true);
    
    // In a real app, upload multiple files in parallel
    // For MVP, we'll just handle the first one to keep it simple, or loop
    const newMediaIds = [...mediaIds];
    
    for (const file of files) {
      if (newMediaIds.length >= 6) {
        toast.error("Maximum 6 files allowed");
        break;
      }
      
      const formData = new FormData();
      formData.append("file", file);
      formData.append("media_source", "UPLOADED");
      
      try {
        const res = await fetch("/api/upload", {
          method: "POST",
          body: formData,
        });
        
        if (res.ok) {
          const { data } = await res.json();
          newMediaIds.push(data.id);
          setMediaFiles(prev => [...prev, file]);
        } else {
          toast.error(`Failed to upload ${file.name}`);
        }
      } catch (err) {
        console.error(err);
        toast.error(`Error uploading ${file.name}`);
      }
    }
    
    setMediaIds(newMediaIds);
    form.setValue("media_ids", newMediaIds);
    setIsUploading(false);
  };

  async function onSubmit(data: CreateIssueInput) {
    if (step !== 3) {
      // Validation check before proceeding
      let fieldsToValidate: any = [];
      if (step === 1) fieldsToValidate = ["latitude", "longitude"];
      if (step === 2) fieldsToValidate = ["title", "description", "category_id"];
      
      const isValid = await form.trigger(fieldsToValidate);
      if (isValid) setStep(step + 1 as Step);
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await fetch("/api/issues", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || "Failed to submit issue");
      }

      toast.success("Issue reported successfully");
      router.push("/citizen/dashboard");
      router.refresh();
    } catch (err: any) {
      toast.error(err.message || "An error occurred");
      setIsSubmitting(false);
    }
  }

  return (
    <div className="max-w-3xl mx-auto py-6">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Report an Issue</h1>
        
        {/* Progress Bar */}
        <div className="flex items-center justify-between mt-6 relative">
          <div className="absolute left-0 top-1/2 -translate-y-1/2 w-full h-1 bg-slate-200 -z-10 rounded-full overflow-hidden">
            <div 
              className="h-full bg-brand-500 transition-all duration-300" 
              style={{ width: `${((step - 1) / 2) * 100}%` }}
            />
          </div>
          
          {[
            { num: 1, label: "Location", icon: MapPin },
            { num: 2, label: "Details", icon: FileText },
            { num: 3, label: "Evidence", icon: Camera }
          ].map((s) => (
            <div key={s.num} className="flex flex-col items-center bg-slate-50 px-2">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center border-2 transition-colors ${
                step > s.num ? "bg-brand-500 border-brand-500 text-white" :
                step === s.num ? "bg-white border-brand-500 text-brand-600" :
                "bg-white border-slate-300 text-slate-400"
              }`}>
                {step > s.num ? <CheckCircle2 className="w-5 h-5" /> : <s.icon className="w-5 h-5" />}
              </div>
              <span className={`text-xs mt-2 font-medium ${step >= s.num ? "text-slate-900" : "text-slate-500"}`}>
                {s.label}
              </span>
            </div>
          ))}
        </div>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          
          {/* STEP 1: LOCATION */}
          {step === 1 && (
            <Card className="border-none shadow-md overflow-hidden">
              <CardHeader className="bg-white border-b z-10 relative">
                <CardTitle>Where is the problem?</CardTitle>
                <CardDescription>Drag the pin to the exact location of the issue.</CardDescription>
                <Button 
                  type="button" 
                  variant="outline" 
                  size="sm" 
                  className="absolute right-6 top-6"
                  onClick={handleGeolocate}
                  disabled={locating}
                >
                  {locating ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <LocateFixed className="w-4 h-4 mr-2" />}
                  Use my location
                </Button>
              </CardHeader>
              <div className="h-[400px] w-full relative">
                <MapView onMapLoad={setMapInstance} />
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-10 hidden">
                   {/* Fallback crosshair if marker is lost */}
                   <MapPin className="w-8 h-8 text-brand-600" />
                </div>
              </div>
            </Card>
          )}

          {/* STEP 2: DETAILS */}
          {step === 2 && (
            <Card className="border-none shadow-md">
              <CardHeader>
                <CardTitle>What is the issue?</CardTitle>
                <CardDescription>Provide a clear description of the problem.</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <FormField
                  control={form.control}
                  name="category_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Category</FormLabel>
                      <FormControl>
                        <select 
                          className="flex h-10 w-full items-center justify-between rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-slate-950 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                          {...field}
                        >
                          <option value="" disabled>Select a category...</option>
                          {categories.map((c) => (
                            <option key={c.id} value={c.id}>{c.name}</option>
                          ))}
                        </select>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="title"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Title</FormLabel>
                      <FormControl>
                        <Input placeholder="e.g. Deep pothole on Main Street" {...field} />
                      </FormControl>
                      <FormDescription>A short summary of the issue.</FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="description"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Description</FormLabel>
                      <FormControl>
                        <Textarea 
                          placeholder="Describe the issue in detail, including any specific landmarks or hazards..."
                          className="min-h-[120px]"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </CardContent>
            </Card>
          )}

          {/* STEP 3: EVIDENCE */}
          {step === 3 && (
            <Card className="border-none shadow-md">
              <CardHeader>
                <CardTitle>Add Evidence (Optional but recommended)</CardTitle>
                <CardDescription>Upload photos or videos showing the problem.</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                    {mediaFiles.map((file, i) => (
                      <div key={i} className="relative aspect-square rounded-lg overflow-hidden border bg-slate-100 group">
                        {file.type.startsWith('image') ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={URL.createObjectURL(file)} alt="preview" className="object-cover w-full h-full" />
                        ) : (
                          <div className="flex items-center justify-center h-full text-slate-500">Video</div>
                        )}
                      </div>
                    ))}
                    
                    {mediaFiles.length < 6 && (
                      <label className="aspect-square rounded-lg border-2 border-dashed border-slate-300 hover:border-brand-500 hover:bg-brand-50 cursor-pointer flex flex-col items-center justify-center text-slate-500 transition-colors">
                        <Upload className="w-8 h-8 mb-2" />
                        <span className="text-sm font-medium">Upload Media</span>
                        <span className="text-xs mt-1">Up to 6 files</span>
                        <input 
                          type="file" 
                          accept="image/*,video/mp4"
                          multiple
                          className="hidden"
                          onChange={handleFileUpload}
                          disabled={isUploading}
                        />
                      </label>
                    )}
                  </div>
                  {isUploading && (
                     <div className="flex items-center gap-2 text-sm text-brand-600">
                       <Loader2 className="w-4 h-4 animate-spin" /> Uploading media...
                     </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Navigation Controls */}
          <div className="flex justify-between pt-4">
            {step > 1 ? (
              <Button type="button" variant="outline" onClick={() => setStep(step - 1 as Step)}>
                <ChevronLeft className="w-4 h-4 mr-2" /> Back
              </Button>
            ) : (
              <Button type="button" variant="ghost" onClick={() => router.back()}>
                Cancel
              </Button>
            )}

            {step < 3 ? (
              <Button type="button" onClick={() => onSubmit(form.getValues())}>
                Next <ChevronRight className="w-4 h-4 ml-2" />
              </Button>
            ) : (
              <Button type="submit" disabled={isSubmitting || isUploading}>
                {isSubmitting ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : null}
                Submit Report
              </Button>
            )}
          </div>
        </form>
      </Form>
    </div>
  );
}
