-- Clean up any existing users created through SQL
DO $$
BEGIN
  -- Delete related data first
  DELETE FROM public.business_settings
  WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email IN ('demo@example.com', 'porruss99@gmail.com')
  );
  
  -- Delete identities
  DELETE FROM auth.identities
  WHERE user_id IN (
    SELECT id FROM auth.users
    WHERE email IN ('demo@example.com', 'porruss99@gmail.com')
  );
  
  -- Delete users
  DELETE FROM auth.users
  WHERE email IN ('demo@example.com', 'porruss99@gmail.com');
END $$;