import { useMemo } from 'react';
import { createClient } from './browser';

/**
 * Hook to get the Supabase browser client inside React components.
 * Memoizes the client instance so it's not recreated on every render.
 */
export function useSupabase() {
  return useMemo(createClient, []);
}
