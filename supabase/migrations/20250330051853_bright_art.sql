/*
  # Update Messages Table RLS Policies

  1. Changes
    - Enable RLS on messages table
    - Add policy for inserting messages (both user and AI)
    - Add policy for reading messages
    
  2. Security
    - Allow authenticated users to insert messages
    - Allow authenticated users to read all messages
    - No delete or update policies (messages are immutable)
*/

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can insert their own messages" ON messages;
DROP POLICY IF EXISTS "Users can read their own messages" ON messages;

-- Create new policies
CREATE POLICY "Allow users to insert messages"
ON messages
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow users to read messages"
ON messages
FOR SELECT
TO authenticated
USING (true);