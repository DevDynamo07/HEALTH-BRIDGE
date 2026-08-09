-- Hospital and Appointment Tables for HealthBridge
-- Run this in your Supabase SQL Editor: https://supabase.com/dashboard/project/_/sql/new

-- 1. Create Hospitals Table
CREATE TABLE IF NOT EXISTS hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  address TEXT,
  total_beds INTEGER DEFAULT 100,
  occupied_beds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Appointments Table
CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  hospital_id UUID REFERENCES hospitals(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  department TEXT NOT NULL,
  appointment_date DATE NOT NULL,
  appointment_time TEXT NOT NULL,
  symptoms TEXT,
  status TEXT CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
CREATE POLICY "Hospitals are viewable by everyone" ON hospitals FOR SELECT USING (true);

CREATE POLICY "Patients manage own appointments" ON appointments FOR ALL USING (
  auth.uid() = patient_id
);

CREATE POLICY "Doctors view allocated appointments" ON appointments FOR SELECT USING (
  auth.uid() = doctor_id
);

CREATE POLICY "Doctors update allocated appointments" ON appointments FOR UPDATE USING (
  auth.uid() = doctor_id
);

-- 5. Seed Hospitals Data
INSERT INTO hospitals (name, city, state, address, total_beds, occupied_beds) VALUES
('AIIMS (All India Institute of Medical Sciences)', 'New Delhi', 'Delhi', 'Ansari Nagar, New Delhi - 110029', 1800, 1640),
('Apollo Hospital', 'Chennai', 'Tamil Nadu', 'Greams Lane, Off Greams Road, Chennai - 600006', 900, 780),
('Fortis Memorial Research Institute', 'Gurgaon', 'Haryana', 'Sector 44, opposite HUDA City Centre, Gurgaon - 122002', 450, 390),
('Tata Memorial Hospital', 'Mumbai', 'Maharashtra', 'Dr. E Borges Road, Parel, Mumbai - 400012', 700, 680),
('Narayana Health City', 'Bangalore', 'Karnataka', 'Bommasandra Industrial Area, Anekal Taluk, Bangalore - 560099', 1000, 890),
('Medanta - The Medicity', 'Gurgaon', 'Haryana', 'CH Baktawar Singh Road, Sector 38, Gurgaon - 122001', 1250, 1120),
('Max Super Speciality Hospital', 'New Delhi', 'Delhi', 'Press Enclave Road, Saket, New Delhi - 110017', 530, 480),
('Christian Medical College (CMC)', 'Vellore', 'Tamil Nadu', 'Ida Scudder Road, Vellore - 632004', 2200, 2110)
ON CONFLICT DO NOTHING;
