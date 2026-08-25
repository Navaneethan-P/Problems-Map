"use client";

import { useState } from "react";
import { PublicMap } from "./public-map";
import { MapDashboardOverlay } from "./map-dashboard-overlay";
import type { IssueMapMarker } from "@/types";

interface MapDashboardProps {
  categories: { id: string; name: string }[];
}

export function MapDashboard({ categories }: MapDashboardProps) {
  const [flyToTarget, setFlyToTarget] = useState<{ lng: number, lat: number, zoom: number } | null>(null);
  const [statusFilter, setStatusFilter] = useState<string | undefined>(undefined);
  const [categoryFilter, setCategoryFilter] = useState<string | undefined>(undefined);
  
  // Real-time map statistics
  const [mapIssues, setMapIssues] = useState<IssueMapMarker[]>([]);

  const handleLocationSelected = (target: { lng: number, lat: number, zoom: number }) => {
    setFlyToTarget(target);
  };

  const handleFilterChange = (filters: { status?: string; categoryId?: string }) => {
    setStatusFilter(filters.status);
    setCategoryFilter(filters.categoryId);
  };

  // Calculate statistics from the issues currently loaded in the map bounds
  const stats = {
    total: mapIssues.length,
    solved: mapIssues.filter(i => i.status === "RESOLVED").length,
    pending: mapIssues.filter(i => i.status !== "RESOLVED" && i.priority !== "EMERGENCY").length,
    emergency: mapIssues.filter(i => i.priority === "EMERGENCY").length,
  };

  return (
    <>
      <PublicMap 
        flyToTarget={flyToTarget} 
        statusFilter={statusFilter} 
        categoryFilter={categoryFilter} 
        onIssuesLoaded={setMapIssues}
      />
      
      <MapDashboardOverlay 
        categories={categories}
        onLocationSelected={handleLocationSelected}
        onFilterChange={handleFilterChange}
        stats={stats}
      />
      
      {/* Legend */}
      <div className="absolute bottom-6 right-6 z-10 w-48 bg-white/90 backdrop-blur-md rounded-xl shadow-lg p-3 border-slate-200/60 text-xs hidden md:block">
        <h3 className="font-semibold text-slate-700 mb-2">Priority Legend</h3>
        <div className="space-y-2">
          <div className="flex gap-2 items-center">
            <span className="w-3 h-3 rounded-full bg-emergency shadow-sm shadow-red-200"></span>
            <span className="font-medium text-slate-600">Emergency</span>
          </div>
          <div className="flex gap-2 items-center">
            <span className="w-3 h-3 rounded-full bg-high shadow-sm shadow-orange-200"></span>
            <span className="font-medium text-slate-600">High Priority</span>
          </div>
          <div className="flex gap-2 items-center">
            <span className="w-3 h-3 rounded-full bg-normal shadow-sm shadow-blue-200"></span>
            <span className="font-medium text-slate-600">Normal</span>
          </div>
        </div>
      </div>
    </>
  );
}
