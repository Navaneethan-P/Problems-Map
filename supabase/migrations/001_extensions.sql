-- Migration 001: Extensions
-- Enable required PostgreSQL extensions for Problems Map

-- PostGIS: spatial data types, functions, and operators
CREATE EXTENSION IF NOT EXISTS postgis;

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Trigram similarity for duplicate text matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Accent-insensitive text search
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Full-text search configuration using unaccent
CREATE TEXT SEARCH CONFIGURATION public.english_unaccent (COPY = pg_catalog.english);
ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
  ALTER MAPPING FOR hword, hword_part, word WITH unaccent, english_stem;
