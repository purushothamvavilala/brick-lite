/*
  # Add porruss99@gmail.com user
  
  1. Changes
    - Clean up any existing user data
    - Create new user with proper auth setup
    - Set up identity record
    - Create business settings
    
  2. Security
    - Use proper password hashing
    - Set up email verification
    - Create identity record correctly
*/

-- First clean up any existing data for this user
DO $$
BEGIN
  -- Delete related data first
  DELETE FROM public.business_settings
  WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email = 'porruss99@gmail.com'
  );
  
  -- Delete identities
  DELETE FROM auth.identities
  WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email = 'porruss99@gmail.com'
  );
  
  -- Delete user
  DELETE FROM auth.users
  WHERE email = 'porruss99@gmail.com';
END $$;

-- Create new user
DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
BEGIN
  -- Insert user without setting confirmed_at (it's generated)
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
    phone,
    confirmation_sent_at,
    recovery_sent_at,
    email_change_token_current,
    email_change_token_new,
    invited_at,
    is_sso_user,
    deleted_at
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    'porruss99@gmail.com',
    crypt('porus', gen_salt('bf')),
    now(),
    jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']::text[],
      'role', 'authenticated'
    ),
    jsonb_build_object(
      'name', 'Porus'
    ),
    'authenticated',
    'authenticated',
    now(),
    now(),
    now(),
    encode(gen_random_bytes(32), 'base64'),
    false,
    null,
    now(),
    null,
    null,
    null,
    null,
    false,
    null
  );

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
    gen_random_uuid(),
    new_user_id,
    'porruss99@gmail.com',
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', 'porruss99@gmail.com',
      'email_verified', true,
      'phone_verified', false,
      'name', 'Porus'
    ),
    'email',
    now(),
    now(),
    now()
  );

  -- Create business settings
  INSERT INTO public.business_settings (
    user_id,
    name,
    description,
    operating_hours,
    ai_features
  ) VALUES (
    new_user_id,
    'Porus Restaurant',
    'A modern restaurant with AI-powered ordering',
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
END $$;