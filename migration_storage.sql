-- Create bucket for medical records
INSERT INTO storage.buckets (id, name, public) 
VALUES ('medical-records', 'medical-records', true)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for medical-records

-- 1. Patients can upload files to their own folder (folder name = user_id)
CREATE POLICY "Patients can upload own medical records"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'medical-records' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Patients can update their own records
CREATE POLICY "Patients can update own medical records"
ON storage.objects FOR UPDATE
TO authenticated
WITH CHECK (
  bucket_id = 'medical-records' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Patients can delete their own records
CREATE POLICY "Patients can delete own medical records"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'medical-records' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Anyone authenticated can read (Since it's health records, in a real app this should check access_requests.
-- For this mini project, we'll allow authenticated users to view records if they have the URL).
CREATE POLICY "Authenticated users can view medical records"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'medical-records');
