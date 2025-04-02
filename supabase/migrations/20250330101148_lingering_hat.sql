/*
  # Clean up auth schema and remove direct user creation
  
  1. Changes
    - Remove all migrations that directly modify auth schema
    - Clean up any existing test users
    - Keep only table structure and RLS policies
    
  2. Security
    - Maintain proper data isolation
    - Preserve RLS policies
*/

-- Clean up any existing test users and their related data
DO $$
BEGIN
  -- Delete related data first
  DELETE FROM public.business_settings
  WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email IN ('demo@example.com', 'porruss99@gmail.com')
  );
END $$;