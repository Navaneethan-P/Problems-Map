"use client";

import { useState } from "react";
import { PublicMap } from "./public-map";
import { MapDashboardOverlay } from "./map-dashboard-overlay";

interface MapDashboardProps {
  categories: { id: string; name: string }[];
}

export function MapDashboard({ categories }: MapDashboardProps) {
  const [flyToBbox, setFlyToBbox] = useState<[number, number, number, number] | null>(null);
  const [statusFilter, setStatusFilter] = useState<string | undefined>(undefined);
  const [categoryFilter, setCategoryFilter] = useState<string | undefined>(undefined);

  const handleLocationSelected = (bbox: any) => {
    if (bbox && bbox.coordinates && bbox.coordinates[0]) {
      // GeoJSON Polygon coordinates: [[[lon, lat], [lon, lat], ...]]
      // We need to extract the min/max lon/lat to form a bounding box
      const coords = bbox.coordinates[0];
      let minLon = 180, maxLon = -180, minLat = 90, maxLat = -90;
      
      coords.forEach(([lon, lat]: [number, number]) => {
        if (lon < minLon) minLon = lon;
        if (lon > maxLon) maxLon = lon;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
      });

      setFlyToBbox([minLon, minLat, maxLon, maxLat]);
    }
  };

  const handleFilterChange = (filters: { status?: string; categoryId?: string }) => {
    setStatusFilter(filters.status);
    setCategoryFilter(filters.categoryId);
  };

  return (
    <>
      <PublicMap 
        flyToBbox={flyToBbox} 
        statusFilter={statusFilter} 
        categoryFilter={categoryFilter} 
      />
      <MapDashboardOverlay 
        categories={categories}
        onLocationSelected={handleLocationSelected}
        onFilterChange={handleFilterChange}
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
