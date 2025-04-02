/*
  # Fix anonymous message inserts

  1. Changes
    - Add policy to allow anonymous message inserts
    - Remove user_id requirement for message inserts
    - Add validation checks for required fields

  2. Security
    - Only allows inserts with valid content and language
    - Prevents null or empty values
    - Maintains data integrity while allowing anonymous access
*/

-- Drop existing insert policies
DROP POLICY IF EXISTS "Users can create messages" ON messages;
DROP POLICY IF EXISTS "Users can insert their own messages" ON messages;

-- Create new policy for anonymous message inserts
CREATE POLICY "Allow anonymous message inserts"
ON messages
FOR INSERT
TO anon, authenticated
WITH CHECK (
  -- Ensure required fields are present and valid
  content IS NOT NULL AND
  content <> '' AND
  language IS NOT NULL AND
  language <> '' AND
  created_at <= now()
);

-- Modify messages table to make user_id optional
ALTER TABLE messages ALTER COLUMN user_id DROP NOT NULL;