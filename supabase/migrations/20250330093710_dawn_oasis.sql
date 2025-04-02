/*
  # Create demo user and initial settings
  
  1. Changes
    - Create demo user with proper auth schema
    - Add required provider_id for identities
    - Set up initial business settings
    
  2. Security
    - Password is securely hashed
    - Uses proper auth schema
    - Sets up proper user role
*/

-- Create demo user through auth schema
DO $$
DECLARE
  new_user_id uuid;
  existing_user_id uuid;
BEGIN
  -- Check if user already exists
  SELECT id INTO existing_user_id 
  FROM auth.users 
  WHERE email = 'demo@example.com';

  IF existing_user_id IS NULL THEN
    -- Create new user
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
    ) VALUES (
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
    )
    RETURNING id INTO new_user_id;

    -- Create identity record
    INSERT INTO auth.identities (
      id,
      user_id,
      provider_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      new_user_id,
      new_user_id,
      'demo@example.com',  -- provider_id must match email for email provider
      jsonb_build_object(
        'sub', new_user_id,
        'email', 'demo@example.com'
      ),
      'email',
      now(),
      now(),
      now()
    );

    -- Create initial business settings
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