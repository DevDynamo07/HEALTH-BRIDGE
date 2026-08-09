-- HealthBridge Database Schema
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/lxgwspvoxhtldbfypimy/sql/new

-- 1. Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  role TEXT CHECK (role IN ('doctor', 'patient')) DEFAULT 'patient',
  phone TEXT,
  address TEXT,
  specialization TEXT,
  license_number TEXT,
  date_of_birth DATE,
  blood_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Access requests table
CREATE TABLE IF NOT EXISTS access_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  patient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'granted', 'denied')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doctor_id, patient_id)
);

-- 3. Health records table
CREATE TABLE IF NOT EXISTS health_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  record_type TEXT,
  file_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for profiles
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 6. RLS Policies for access_requests
CREATE POLICY "Users can view own requests" ON access_requests FOR SELECT USING (auth.uid() = doctor_id OR auth.uid() = patient_id);
CREATE POLICY "Doctors can create requests" ON access_requests FOR INSERT WITH CHECK (auth.uid() = doctor_id);
CREATE POLICY "Patients can update request status" ON access_requests FOR UPDATE USING (auth.uid() = patient_id);

-- 7. RLS Policies for health_records
CREATE POLICY "Patients manage own records" ON health_records FOR ALL USING (auth.uid() = patient_id);
CREATE POLICY "Granted doctors can view records" ON health_records FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM access_requests
    WHERE access_requests.doctor_id = auth.uid()
      AND access_requests.patient_id = health_records.patient_id
      AND access_requests.status = 'granted'
  )
);

-- 8. Auto-create profile on signup trigger
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'patient')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
