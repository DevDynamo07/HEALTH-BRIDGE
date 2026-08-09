-- ABHA-Style Schema Updates for HealthBridge
-- Run this in Supabase SQL Editor AFTER the initial migration

-- Add health_id column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS health_id TEXT UNIQUE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS health_id_created_at TIMESTAMPTZ;

-- Add vaccination and insurance record types (extend health_records)
-- No schema change needed — record_type is a free-form TEXT column.
-- New types: 'vaccination', 'insurance', 'consultation_note'

-- Add facility and doctor_name columns to health_records for richer metadata
ALTER TABLE health_records ADD COLUMN IF NOT EXISTS facility_name TEXT;
ALTER TABLE health_records ADD COLUMN IF NOT EXISTS doctor_name TEXT;
