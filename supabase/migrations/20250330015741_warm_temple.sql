/*
  # Create messages table for BFF chat history

  1. New Tables
    - `messages`
      - `id` (uuid, primary key)
      - `content` (text)
      - `emotion` (text)
      - `language` (text)
      - `user_message` (boolean)
      - `created_at` (timestamp)
      
  2. Security
    - Enable RLS on `messages` table
    - Add policies for authenticated users
*/

CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content text NOT NULL,
  emotion text,
  language text DEFAULT 'en',
  user_message boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own messages"
  ON messages
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own messages"
  ON messages
  FOR INSERT
  TO authenticated
  WITH CHECK (true);