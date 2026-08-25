"use client";

import { useState, useEffect } from "react";
import { Filter, MapPin, Loader2 } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import type { IssueStatus } from "@/types";

interface Location {
  id: string;
  name: string;
  parent_id: string | null;
  bbox: any; // GeoJSON bbox
}

interface MapDashboardOverlayProps {
  onLocationSelected: (bbox: any) => void;
  onFilterChange: (filters: { status?: string; categoryId?: string }) => void;
  categories: { id: string; name: string }[];
}

export function MapDashboardOverlay({ onLocationSelected, onFilterChange, categories }: MapDashboardOverlayProps) {
  const [countries, setCountries] = useState<Location[]>([]);
  const [states, setStates] = useState<Location[]>([]);
  const [districts, setDistricts] = useState<Location[]>([]);
  const [municipalities, setMunicipalities] = useState<Location[]>([]);

  const [selectedCountry, setSelectedCountry] = useState<string>("");
  const [selectedState, setSelectedState] = useState<string>("");
  const [selectedDistrict, setSelectedDistrict] = useState<string>("");
  const [selectedMunicipality, setSelectedMunicipality] = useState<string>("");

  const [statusFilter, setStatusFilter] = useState<string>("");
  const [categoryFilter, setCategoryFilter] = useState<string>("");

  const [loading, setLoading] = useState(false);

  // Fetch initial countries
  useEffect(() => {
    fetchLocations("country").then(setCountries);
  }, []);

  const fetchLocations = async (type: string, parentId?: string) => {
    try {
      const url = new URL("/api/locations", window.location.origin);
      url.searchParams.set("type", type);
      if (parentId) url.searchParams.set("parentId", parentId);
      
      const res = await fetch(url.toString());
      const data = await res.json();
      return data.data || [];
    } catch (e) {
      console.error(e);
      return [];
    }
  };

  const handleCountryChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedCountry(val);
    setSelectedState("");
    setSelectedDistrict("");
    setSelectedMunicipality("");
    setStates([]);
    setDistricts([]);
    setMunicipalities([]);

    if (val) {
      const country = countries.find(c => c.id === val);
      if (country && country.bbox) onLocationSelected(country.bbox);
      
      setLoading(true);
      const childStates = await fetchLocations("state", val);
      setStates(childStates);
      setLoading(false);
    }
  };

  const handleStateChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedState(val);
    setSelectedDistrict("");
    setSelectedMunicipality("");
    setDistricts([]);
    setMunicipalities([]);

    if (val) {
      const state = states.find(s => s.id === val);
      if (state && state.bbox) onLocationSelected(state.bbox);

      setLoading(true);
      const childDistricts = await fetchLocations("district", val);
      setDistricts(childDistricts);
      setLoading(false);
    }
  };

  const handleDistrictChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedDistrict(val);
    setSelectedMunicipality("");
    setMunicipalities([]);

    if (val) {
      const district = districts.find(d => d.id === val);
      if (district && district.bbox) onLocationSelected(district.bbox);

      setLoading(true);
      const childMunis = await fetchLocations("municipality", val);
      setMunicipalities(childMunis);
      setLoading(false);
    }
  };

  const handleMunicipalityChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedMunicipality(val);
    
    if (val) {
      const muni = municipalities.find(m => m.id === val);
      if (muni && muni.bbox) onLocationSelected(muni.bbox);
    }
  };

  const handleApplyFilters = () => {
    onFilterChange({
      status: statusFilter || undefined,
      categoryId: categoryFilter || undefined,
    });
  };

  return (
    <Card className="absolute top-4 left-4 z-10 w-80 max-w-[calc(100vw-2rem)] bg-white/90 backdrop-blur-md shadow-xl border-slate-200/60 p-4">
      <div className="flex items-center gap-2 mb-4 text-brand-700">
        <MapPin className="w-5 h-5" />
        <h2 className="font-semibold text-lg">Global Explorer</h2>
      </div>

      <div className="space-y-3">
        {/* Hierarchy Filters */}
        <div className="space-y-2">
          <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Jump To Region</label>
          
          <select 
            className="w-full text-sm border rounded-md px-3 py-2 bg-white disabled:bg-slate-100"
            value={selectedCountry}
            onChange={handleCountryChange}
          >
            <option value="">Any Country...</option>
            {countries.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>

          {states.length > 0 && (
            <select 
              className="w-full text-sm border rounded-md px-3 py-2 bg-white"
              value={selectedState}
              onChange={handleStateChange}
            >
              <option value="">Any State...</option>
              {states.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          )}

          {districts.length > 0 && (
            <select 
              className="w-full text-sm border rounded-md px-3 py-2 bg-white"
              value={selectedDistrict}
              onChange={handleDistrictChange}
            >
              <option value="">Any District...</option>
              {districts.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
            </select>
          )}

          {municipalities.length > 0 && (
            <select 
              className="w-full text-sm border rounded-md px-3 py-2 bg-white"
              value={selectedMunicipality}
              onChange={handleMunicipalityChange}
            >
              <option value="">Any City/Municipality...</option>
              {municipalities.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
            </select>
          )}
        </div>

        {/* Issue Filters */}
        <div className="pt-2 border-t space-y-2">
           <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Filter Issues</label>
           
           <select 
            className="w-full text-sm border rounded-md px-3 py-2 bg-white"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">All Statuses</option>
            <option value="RESOLUTION_PENDING_VERIFICATION,RESOLUTION_SUBMITTED,IN_PROGRESS,ASSIGNED,VERIFIED,OPEN">Unsolved</option>
            <option value="RESOLVED">Solved</option>
            <option value="EMERGENCY">Emergency (Any)</option>
          </select>

          <select 
            className="w-full text-sm border rounded-md px-3 py-2 bg-white"
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <option value="">All Categories</option>
            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </div>

        <Button onClick={handleApplyFilters} className="w-full mt-2 flex items-center justify-center gap-2">
          {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Filter className="w-4 h-4" />}
          Apply Filters
        </Button>
      </div>
    </Card>
  );
}
