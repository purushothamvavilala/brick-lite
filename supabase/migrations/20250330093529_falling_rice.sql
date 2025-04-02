/*
  # Create demo user and initial settings
  
  1. Changes
    - Create demo user through auth.users
    - Set up initial business settings
    
  2. Security
    - Password is securely hashed
    - Uses proper auth schema
*/

-- Create demo user through auth schema
DO $$
DECLARE
  new_user_id uuid;
BEGIN
  -- Insert into auth.users if not exists
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud,
    confirmation_token
  ) 
  SELECT 
    gen_random_uuid(),
    'demo@example.com',
    crypt('demo123456', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"Demo User"}',
    now(),
    now(),
    'authenticated',
    'authenticated',
    encode(gen_random_bytes(32), 'base64')
  WHERE NOT EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'demo@example.com'
  )
  RETURNING id INTO new_user_id;

  -- Create initial business settings for the demo user
  IF new_user_id IS NOT NULL THEN
    INSERT INTO public.business_settings (
      user_id,
      name,
      description,
      operating_hours,
      ai_features
    ) VALUES (
      new_user_id,
      'Demo Restaurant',
      'A demo restaurant showcasing BFF capabilities',
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
END $$;