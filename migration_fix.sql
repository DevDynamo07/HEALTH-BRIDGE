-- Fix-up: Drop existing policies then recreate everything
-- Run this in Supabase SQL Editor

-- Drop existing policies (ignore errors if they don't exist)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view own requests" ON access_requests;
DROP POLICY IF EXISTS "Doctors can create requests" ON access_requests;
DROP POLICY IF EXISTS "Patients can update request status" ON access_requests;
DROP POLICY IF EXISTS "Patients manage own records" ON health_records;
DROP POLICY IF EXISTS "Granted doctors can view records" ON health_records;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;

-- Recreate policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own requests" ON access_requests FOR SELECT USING (auth.uid() = doctor_id OR auth.uid() = patient_id);
CREATE POLICY "Doctors can create requests" ON access_requests FOR INSERT WITH CHECK (auth.uid() = doctor_id);
CREATE POLICY "Patients can update request status" ON access_requests FOR UPDATE USING (auth.uid() = patient_id);

CREATE POLICY "Patients manage own records" ON health_records FOR ALL USING (auth.uid() = patient_id);
CREATE POLICY "Granted doctors can view records" ON health_records FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM access_requests
    WHERE access_requests.doctor_id = auth.uid()
      AND access_requests.patient_id = health_records.patient_id
      AND access_requests.status = 'granted'
  )
);

-- Recreate trigger
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
