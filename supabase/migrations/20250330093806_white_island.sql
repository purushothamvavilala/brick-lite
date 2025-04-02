/*
  # Create demo user with proper auth setup
  
  1. Changes
    - Create demo user in auth.users
    - Create matching identity in auth.identities
    - Set up initial business settings
    
  2. Security
    - Properly hash password
    - Set up correct auth metadata
    - Handle existing user case
*/

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
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      aud,
      role,
      created_at,
      updated_at,
      last_sign_in_at,
      confirmation_token,
      is_super_admin,
      phone
    ) VALUES (
      gen_random_uuid(),
      '00000000-0000-0000-0000-000000000000',
      'demo@example.com',
      crypt('demo123456', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"name":"Demo User"}',
      'authenticated',
      'authenticated',
      now(),
      now(),
      now(),
      encode(gen_random_bytes(32), 'base64'),
      false,
      null
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
      'demo@example.com',
      jsonb_build_object(
        'sub', new_user_id::text,
        'email', 'demo@example.com',
        'email_verified', true,
        'phone_verified', false
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