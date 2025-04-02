/*
  # Enhanced RLS Policies for Production Security

  1. Changes
    - Separate policies for different operations (SELECT, INSERT, UPDATE, DELETE)
    - More granular access control
    - Prevent unauthorized modifications
    - Ensure data isolation between users
  
  2. Security Improvements
    - Explicit policies for each operation
    - Prevent cross-user data access
    - Secure cascade operations
    - Timestamp tracking for modifications
*/

-- RLS Policies for conversations
DROP POLICY IF EXISTS "Users can manage their own conversations" ON conversations;

-- SELECT policy for conversations
DROP POLICY IF EXISTS "Users can view their own conversations" ON conversations;
CREATE POLICY "Users can view their own conversations"
ON conversations
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- INSERT policy for conversations
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations"
ON conversations
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() AND
  created_at <= now() AND
  updated_at <= now()
);

-- UPDATE policy for conversations
DROP POLICY IF EXISTS "Users can update their own conversations" ON conversations;
CREATE POLICY "Users can update their own conversations"
ON conversations
FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- DELETE policy for conversations
DROP POLICY IF EXISTS "Users can delete their own conversations" ON conversations;
CREATE POLICY "Users can delete their own conversations"
ON conversations
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- RLS Policies for messages
DROP POLICY IF EXISTS "Users can insert their own messages" ON messages;
DROP POLICY IF EXISTS "Users can read their conversation messages" ON messages;

-- SELECT policy for messages
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
CREATE POLICY "Users can view messages in their conversations"
ON messages
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  conversation_id IN (
    SELECT id FROM conversations 
    WHERE user_id = auth.uid()
  )
);

-- INSERT policy for messages
DROP POLICY IF EXISTS "Users can create messages" ON messages;
CREATE POLICY "Users can create messages"
ON messages
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id AND
  (
    -- Allow if message is in user's conversation
    conversation_id IN (
      SELECT id FROM conversations 
      WHERE user_id = auth.uid()
    )
  )
);

-- UPDATE policy for messages
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
CREATE POLICY "Users can update their own messages"
ON messages
FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- DELETE policy for messages
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
CREATE POLICY "Users can delete their own messages"
ON messages
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Add audit columns if they don't exist
DO $$ 
BEGIN
  ALTER TABLE conversations
    ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id),
    ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id);
    
  ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id),
    ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id);
EXCEPTION
  WHEN duplicate_column THEN NULL;
END $$;

-- Update triggers to track user modifications
CREATE OR REPLACE FUNCTION update_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for audit tracking
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'conversations_audit_trigger'
  ) THEN
    CREATE TRIGGER conversations_audit_trigger
      BEFORE UPDATE ON conversations
      FOR EACH ROW
      EXECUTE FUNCTION update_audit_fields();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'messages_audit_trigger'
  ) THEN
    CREATE TRIGGER messages_audit_trigger
      BEFORE UPDATE ON messages
      FOR EACH ROW
      EXECUTE FUNCTION update_audit_fields();
  END IF;
END $$;