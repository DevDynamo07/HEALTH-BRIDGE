-- HealthBridge: Consent Settings Table
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/uwdcbseeuoznvrgskean/sql/new

-- 1. Create consent_settings table
CREATE TABLE IF NOT EXISTS consent_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID REFERENCES access_requests(id) ON DELETE CASCADE,
  patient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(request_id, consent_type)
);

-- 2. Enable RLS
ALTER TABLE consent_settings ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
-- Patients can view their own consent settings
CREATE POLICY "Patients can view own consents"
  ON consent_settings FOR SELECT
  USING (auth.uid() = patient_id);

-- Patients can insert their own consent settings
CREATE POLICY "Patients can insert own consents"
  ON consent_settings FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

-- Patients can update their own consent settings
CREATE POLICY "Patients can update own consents"
  ON consent_settings FOR UPDATE
  USING (auth.uid() = patient_id);

-- Patients can delete their own consent settings
CREATE POLICY "Patients can delete own consents"
  ON consent_settings FOR DELETE
  USING (auth.uid() = patient_id);

-- 4. Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_consent_settings_request_id ON consent_settings(request_id);
CREATE INDEX IF NOT EXISTS idx_consent_settings_patient_id ON consent_settings(patient_id);
