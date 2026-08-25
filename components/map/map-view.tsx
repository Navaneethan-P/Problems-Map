"use client";

import { useEffect, useRef, useState } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { cn } from "@/lib/utils";

export interface MapViewProps {
  className?: string;
  initialViewState?: {
    longitude: number;
    latitude: number;
    zoom: number;
  };
  children?: React.ReactNode;
  onMapLoad?: (map: maplibregl.Map) => void;
  interactive?: boolean;
}

const DEFAULT_CENTER = {
  longitude: 0,
  latitude: 20, // World map center
  zoom: 2,
};

export function MapView({
  className,
  initialViewState,
  children,
  onMapLoad,
  interactive = true,
}: MapViewProps) {
  const mapContainer = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    if (!mapContainer.current || mapRef.current) return;

    const styleUrl =
      process.env.NEXT_PUBLIC_MAP_STYLE_URL ||
      "https://tiles.openfreemap.org/styles/liberty";

    const viewState = initialViewState || DEFAULT_CENTER;

    const map = new maplibregl.Map({
      container: mapContainer.current,
      style: styleUrl,
      center: [viewState.longitude, viewState.latitude],
      zoom: viewState.zoom,
      interactive,
      attributionControl: false, // We'll add a custom one if needed or just use default
    });

    if (interactive) {
      map.addControl(
        new maplibregl.NavigationControl({
          visualizePitch: true,
        }),
        "bottom-right"
      );
      
      map.addControl(
        new maplibregl.GeolocateControl({
          positionOptions: { enableHighAccuracy: true },
          trackUserLocation: true,
        }),
        "bottom-right"
      );
    }

    map.on("load", () => {
      setLoaded(true);
      if (onMapLoad) onMapLoad(map);
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className={cn("relative w-full h-full", className)}>
      <div ref={mapContainer} className="absolute inset-0" />
      {/* We can render children like custom markers here, though with MapLibre 
          we usually add them via DOM elements attached to the map instance.
          React-map-gl provides a better declarative approach, but since we are 
          using vanilla maplibre-gl, we will handle markers imperatively in the parent component. */}
      {loaded && children}
    </div>
  );
}
