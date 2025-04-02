/*
  # Fix user credentials migration
  
  1. Changes
    - Create or update user with new credentials
    - Handle generated columns correctly
    - Ensure proper auth setup
    - Create business settings if needed
    
  2. Security
    - Maintain data integrity
    - Handle foreign key constraints
*/

DO $$
DECLARE
  target_user_id uuid;
BEGIN
  -- First try to get the user by the new email
  SELECT id INTO target_user_id
  FROM auth.users
  WHERE email = 'porruss99@gmail.com';

  IF target_user_id IS NULL THEN
    -- Create new user with all required fields
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
      gen_random_uuid(),
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
        'name', 'Demo User'
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
    )
    RETURNING id INTO target_user_id;

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
      target_user_id,
      'porruss99@gmail.com',
      jsonb_build_object(
        'sub', target_user_id::text,
        'email', 'porruss99@gmail.com',
        'email_verified', true,
        'phone_verified', false,
        'name', 'Demo User'
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
      target_user_id,
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