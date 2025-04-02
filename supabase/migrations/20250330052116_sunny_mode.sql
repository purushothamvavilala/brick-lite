/*
  # Final Fix for Messages Table RLS Policies

  1. Changes
    - Enable RLS on messages table
    - Add policy for inserting messages (both user and AI)
    - Add policy for reading messages in conversations
    
  2. Security
    - Allow authenticated users to insert any message
    - Allow authenticated users to read all messages
    - No delete or update policies (messages are immutable)
*/

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow authenticated users to insert messages" ON messages;
DROP POLICY IF EXISTS "Allow authenticated users to read messages" ON messages;
DROP POLICY IF EXISTS "Allow users to insert messages" ON messages;
DROP POLICY IF EXISTS "Allow users to read messages" ON messages;

-- Create new policies
CREATE POLICY "Allow authenticated users to insert messages"
ON messages
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read messages"
ON messages
FOR SELECT
TO authenticated
USING (true);

-- Ensure user_message column has a default value
ALTER TABLE messages 
ALTER COLUMN user_message SET DEFAULT false;