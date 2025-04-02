/*
  # Update RLS policies for messages table

  1. Changes
    - Safely update RLS policies for messages table
    - Ensure policies exist for both anonymous and authenticated users
    - Handle cases where policies may already exist

  2. Security
    - Maintain RLS on messages table
    - Allow anonymous users to insert messages for demo purposes
    - Allow authenticated users to read and update their own messages
*/

-- Enable RLS (idempotent)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop insert policy if exists
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'messages' 
    AND policyname = 'Allow anonymous message inserts'
  ) THEN
    DROP POLICY "Allow anonymous message inserts" ON messages;
  END IF;

  -- Drop select policy if exists
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'messages' 
    AND policyname = 'Users can view messages in their conversations'
  ) THEN
    DROP POLICY "Users can view messages in their conversations" ON messages;
  END IF;

  -- Drop update policy if exists
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'messages' 
    AND policyname = 'Users can update their own messages'
  ) THEN
    DROP POLICY "Users can update their own messages" ON messages;
  END IF;
END $$;

-- Create new policies
CREATE POLICY "Allow anonymous message inserts"
  ON messages
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    content IS NOT NULL AND
    content <> '' AND
    language IS NOT NULL AND
    language <> '' AND
    created_at <= now()
  );

CREATE POLICY "Users can view messages in their conversations"
  ON messages
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    conversation_id IN (
      SELECT id FROM conversations WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own messages"
  ON messages
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());