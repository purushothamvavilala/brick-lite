/*
  # Fix Business Settings RLS Policies
  
  1. Changes
    - Drop existing RLS policies
    - Create new policies with proper user checks
    - Ensure proper access for authenticated users
    
  2. Security
    - Maintain data isolation between users
    - Allow users to manage their own settings
    - Prevent unauthorized access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own settings" ON business_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON business_settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON business_settings;

-- Enable RLS
ALTER TABLE business_settings ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY "Users can view their own settings"
ON business_settings
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
ON business_settings
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
ON business_settings
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id AND
  NOT EXISTS (
    SELECT 1 FROM business_settings
    WHERE user_id = auth.uid()
  )
);

-- Create default settings function
CREATE OR REPLACE FUNCTION create_default_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.business_settings (
    user_id,
    name,
    description,
    operating_hours,
    ai_features
  ) VALUES (
    NEW.id,
    'My Restaurant',
    'Restaurant description',
    '{
      "monday": {"open": "09:00", "close": "22:00"},
      "tuesday": {"open": "09:00", "close": "22:00"},
      "wednesday": {"open": "09:00", "close": "22:00"},
      "thursday": {"open": "09:00", "close": "22:00"},
      "friday": {"open": "09:00", "close": "23:00"},
      "saturday": {"open": "10:00", "close": "23:00"},
      "sunday": {"open": "10:00", "close": "22:00"}
    }'::jsonb,
    '{
      "autoUpsell": true,
      "allergyWarnings": true,
      "dietaryRecommendations": true,
      "smartPairing": true
    }'::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_default_settings();