/*
  # Fix Business Settings RLS Policies
  
  1. Changes
    - Drop existing policies safely
    - Create new RLS policies with unique names
    - Add trigger for default settings
    
  2. Security
    - Maintain proper user data isolation
    - Enable secure default settings creation
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop policies if they exist
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'business_settings' 
    AND schemaname = 'public'
  ) THEN
    DROP POLICY IF EXISTS "Enable read access for users" ON business_settings;
    DROP POLICY IF EXISTS "Enable insert access for users" ON business_settings;
    DROP POLICY IF EXISTS "Enable update access for users" ON business_settings;
  END IF;
END $$;

-- Enable RLS
ALTER TABLE business_settings ENABLE ROW LEVEL SECURITY;

-- Create new policies with unique names
CREATE POLICY "business_settings_select"
ON business_settings
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "business_settings_insert"
ON business_settings
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "business_settings_update"
ON business_settings
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Update default settings function with error handling
CREATE OR REPLACE FUNCTION create_default_settings()
RETURNS TRIGGER SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if settings already exist
  IF NOT EXISTS (
    SELECT 1 FROM public.business_settings
    WHERE user_id = NEW.id
  ) THEN
    -- Create default settings
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
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error and continue
    RAISE WARNING 'Error creating default settings for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger for new users if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION create_default_settings();
  END IF;
END $$;