"use client";

import { useState, useEffect } from "react";
import { Filter, MapPin, Loader2, BarChart2, CheckCircle, AlertTriangle, Clock } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Country, State, City, ICountry, IState, ICity } from 'country-state-city';

interface MapDashboardOverlayProps {
  onLocationSelected: (target: { lng: number, lat: number, zoom: number }) => void;
  onFilterChange: (filters: { status?: string; categoryId?: string }) => void;
  categories: { id: string; name: string }[];
  stats: { total: number; solved: number; pending: number; emergency: number };
}

export function MapDashboardOverlay({ onLocationSelected, onFilterChange, categories, stats }: MapDashboardOverlayProps) {
  const [countries, setCountries] = useState<ICountry[]>([]);
  const [states, setStates] = useState<IState[]>([]);
  const [cities, setCities] = useState<ICity[]>([]);

  const [selectedCountry, setSelectedCountry] = useState<string>("");
  const [selectedState, setSelectedState] = useState<string>("");
  const [selectedCity, setSelectedCity] = useState<string>("");

  const [statusFilter, setStatusFilter] = useState<string>("");
  const [categoryFilter, setCategoryFilter] = useState<string>("");

  // Load countries on mount
  useEffect(() => {
    setCountries(Country.getAllCountries());
  }, []);

  const handleCountryChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedCountry(val);
    setSelectedState("");
    setSelectedCity("");
    setStates([]);
    setCities([]);

    if (val) {
      const country = countries.find(c => c.isoCode === val);
      if (country && country.latitude && country.longitude) {
        onLocationSelected({ lng: parseFloat(country.longitude), lat: parseFloat(country.latitude), zoom: 4 });
      }
      setStates(State.getStatesOfCountry(val));
    } else {
      // Zoom out to world map if cleared
      onLocationSelected({ lng: 0, lat: 20, zoom: 2 });
    }
  };

  const handleStateChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedState(val);
    setSelectedCity("");
    setCities([]);

    if (val) {
      const state = states.find(s => s.isoCode === val);
      if (state && state.latitude && state.longitude) {
        onLocationSelected({ lng: parseFloat(state.longitude), lat: parseFloat(state.latitude), zoom: 6 });
      }
      setCities(City.getCitiesOfState(selectedCountry, val));
    }
  };

  const handleCityChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    setSelectedCity(val);
    
    if (val) {
      const city = cities.find(c => c.name === val);
      if (city && city.latitude && city.longitude) {
        onLocationSelected({ lng: parseFloat(city.longitude), lat: parseFloat(city.latitude), zoom: 10 });
      }
    }
  };

  const handleApplyFilters = () => {
    onFilterChange({
      status: statusFilter || undefined,
      categoryId: categoryFilter || undefined,
    });
  };

  return (
    <Card className="absolute top-4 left-4 z-10 w-80 max-w-[calc(100vw-2rem)] bg-white/90 backdrop-blur-md shadow-xl border-slate-200/60 p-4 max-h-[calc(100vh-6rem)] overflow-y-auto">
      <div className="flex items-center gap-2 mb-4 text-brand-700">
        <MapPin className="w-5 h-5" />
        <h2 className="font-semibold text-lg">Global Explorer</h2>
      </div>

      <div className="space-y-4">
        {/* Real-time Statistics */}
        <div className="bg-slate-50 p-3 rounded-lg border border-slate-100 shadow-sm">
          <div className="flex items-center gap-2 mb-2 text-slate-600">
            <BarChart2 className="w-4 h-4" />
            <h3 className="text-xs font-semibold uppercase tracking-wider">Reports in View</h3>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div className="bg-white p-2 rounded-md shadow-sm border border-slate-100 flex flex-col items-center justify-center">
              <span className="text-xl font-bold text-slate-700">{stats.total}</span>
              <span className="text-[10px] uppercase font-semibold text-slate-400">Total</span>
            </div>
            <div className="bg-white p-2 rounded-md shadow-sm border border-slate-100 flex flex-col items-center justify-center">
              <div className="flex items-center gap-1 text-green-600 mb-1">
                <CheckCircle className="w-3 h-3" />
                <span className="text-lg font-bold leading-none">{stats.solved}</span>
              </div>
              <span className="text-[10px] uppercase font-semibold text-slate-400">Solved</span>
            </div>
            <div className="bg-white p-2 rounded-md shadow-sm border border-slate-100 flex flex-col items-center justify-center">
              <div className="flex items-center gap-1 text-orange-500 mb-1">
                <Clock className="w-3 h-3" />
                <span className="text-lg font-bold leading-none">{stats.pending}</span>
              </div>
              <span className="text-[10px] uppercase font-semibold text-slate-400">Pending</span>
            </div>
            <div className="bg-white p-2 rounded-md shadow-sm border border-slate-100 flex flex-col items-center justify-center">
              <div className="flex items-center gap-1 text-red-500 mb-1">
                <AlertTriangle className="w-3 h-3" />
                <span className="text-lg font-bold leading-none">{stats.emergency}</span>
              </div>
              <span className="text-[10px] uppercase font-semibold text-slate-400">Emergency</span>
            </div>
          </div>
        </div>

        {/* Hierarchy Filters */}
        <div className="space-y-2 pt-1">
          <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Jump To Region</label>
          
          <select 
            className="w-full text-sm border rounded-md px-3 py-2 bg-white disabled:bg-slate-100"
            value={selectedCountry}
            onChange={handleCountryChange}
          >
            <option value="">World Map...</option>
            {countries.map(c => <option key={c.isoCode} value={c.isoCode}>{c.name}</option>)}
          </select>

          {states.length > 0 && (
            <select 
              className="w-full text-sm border rounded-md px-3 py-2 bg-white"
              value={selectedState}
              onChange={handleStateChange}
            >
              <option value="">Any State...</option>
              {states.map(s => <option key={s.isoCode} value={s.isoCode}>{s.name}</option>)}
            </select>
          )}

          {cities.length > 0 && (
            <select 
              className="w-full text-sm border rounded-md px-3 py-2 bg-white"
              value={selectedCity}
              onChange={handleCityChange}
            >
              <option value="">Any City...</option>
              {cities.map(c => <option key={c.name} value={c.name}>{c.name}</option>)}
            </select>
          )}
        </div>

        {/* Issue Filters */}
        <div className="pt-3 border-t space-y-2">
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
          <Filter className="w-4 h-4" />
          Apply Filters
        </Button>
      </div>
    </Card>
  );
}
