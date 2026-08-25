"use client";

import { useEffect, useState, useRef, useMemo } from "react";
import maplibregl from "maplibre-gl";
import Supercluster from "supercluster";
import { MapView } from "./map-view";
import { useQuery } from "@tanstack/react-query";
import type { IssueMapMarker } from "@/types";
import { useRouter } from "next/navigation";

interface PublicMapProps {
  initialWest?: number;
  initialSouth?: number;
  initialEast?: number;
  initialNorth?: number;
}

// Custom Supercluster type for our issue markers
type IssueGeoJSONProperties = IssueMapMarker;
type ClusterGeoJSONProperties = {
  cluster: boolean;
  cluster_id: number;
  point_count: number;
  point_count_abbreviated: string;
};

export function PublicMap({
  initialWest,
  initialSouth,
  initialEast,
  initialNorth,
}: PublicMapProps) {
  const router = useRouter();
  const [map, setMap] = useState<maplibregl.Map | null>(null);
  const [bbox, setBbox] = useState<[number, number, number, number] | null>(
    initialWest !== undefined
      ? [initialWest, initialSouth!, initialEast!, initialNorth!]
      : null
  );
  const [zoom, setZoom] = useState(6);
  
  // Marker elements reference
  const markersRef = useRef<{ [key: string]: maplibregl.Marker }>({});

  // Supercluster instance
  const supercluster = useMemo(() => {
    return new Supercluster<IssueGeoJSONProperties, ClusterGeoJSONProperties>({
      radius: 60,
      maxZoom: 16,
    });
  }, []);

  // Fetch issues for the current viewport
  const { data: issues = [], isLoading } = useQuery({
    queryKey: ["map-issues", bbox],
    queryFn: async () => {
      if (!bbox) return [];
      const [west, south, east, north] = bbox;
      const res = await fetch(
        `/api/issues/map?west=${west}&south=${south}&east=${east}&north=${north}`
      );
      if (!res.ok) throw new Error("Failed to fetch map data");
      const json = await res.json();
      return json.data as IssueMapMarker[];
    },
    enabled: !!bbox,
  });

  // Update supercluster when data changes
  useEffect(() => {
    const geoJsonPoints = issues.map((issue) => ({
      type: "Feature" as const,
      properties: issue,
      geometry: {
        type: "Point" as const,
        coordinates: [issue.longitude, issue.latitude],
      },
    }));
    supercluster.load(geoJsonPoints);
  }, [issues, supercluster]);

  // Render clusters & markers on the map
  useEffect(() => {
    if (!map || !bbox) return;

    // Get clusters for current bbox and zoom
    const clusters = supercluster.getClusters(bbox, Math.floor(zoom));
    
    // Create new markers
    const newMarkersRef: { [key: string]: maplibregl.Marker } = {};

    clusters.forEach((cluster) => {
      const [longitude, latitude] = cluster.geometry.coordinates;
      const isCluster = (cluster.properties as any)?.cluster;
      
      let markerId: string;
      let el = document.createElement("div");

      if (isCluster) {
        markerId = `cluster-${(cluster.properties as any).cluster_id}`;
        const count = (cluster.properties as any).point_count_abbreviated;
        el.className = "cluster-marker";
        el.style.width = `${Math.max(30, 20 + (count.length * 5))}px`;
        el.style.height = el.style.width;
        el.innerText = count;

        el.addEventListener("click", (e) => {
          e.stopPropagation();
          const expansionZoom = supercluster.getClusterExpansionZoom(
            (cluster.properties as any).cluster_id
          );
          map.easeTo({
            center: [longitude, latitude],
            zoom: expansionZoom,
          });
        });
      } else {
        const issue = cluster.properties as IssueMapMarker;
        markerId = `issue-${issue.id}`;
        
        el.className = `issue-marker issue-marker--${issue.priority.toLowerCase()} ${
          issue.status === "RESOLVED" ? "issue-marker--resolved" : ""
        }`;

        el.addEventListener("click", (e) => {
          e.stopPropagation();
          router.push(`/issues/${issue.id}`);
        });
      }

      // Reuse existing marker if possible
      let marker = markersRef.current[markerId];
      if (!marker) {
        marker = new maplibregl.Marker({ element: el })
          .setLngLat([longitude, latitude])
          .addTo(map);
      } else {
        // Keep in DOM
        delete markersRef.current[markerId];
      }
      
      newMarkersRef[markerId] = marker;
    });

    // Remove old markers that are no longer visible
    Object.values(markersRef.current).forEach((marker) => marker.remove());
    markersRef.current = newMarkersRef;

  }, [map, bbox, zoom, supercluster, router, issues]); // Re-run when issues data is re-loaded

  // Handle map events
  useEffect(() => {
    if (!map) return;

    const updateBbox = () => {
      const bounds = map.getBounds();
      setBbox([
        bounds.getWest(),
        bounds.getSouth(),
        bounds.getEast(),
        bounds.getNorth(),
      ]);
      setZoom(map.getZoom());
    };

    map.on("moveend", updateBbox);
    map.on("zoomend", updateBbox);

    // Initial bbox
    updateBbox();

    return () => {
      map.off("moveend", updateBbox);
      map.off("zoomend", updateBbox);
    };
  }, [map]);

  return (
    <div className="relative w-full h-full">
      <MapView onMapLoad={setMap} />
      
      {isLoading && (
        <div className="absolute top-4 left-1/2 -translate-x-1/2 bg-white/90 px-4 py-2 rounded-full shadow text-sm font-medium animate-pulse z-10">
          Loading issues...
        </div>
      )}
    </div>
  );
}
