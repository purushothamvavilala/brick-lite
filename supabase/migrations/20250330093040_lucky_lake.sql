/*
  # Add Enterprise Leads Table
  
  1. New Tables
    - `enterprise_leads`
      - `id` (uuid, primary key)
      - `name` (text)
      - `email` (text)
      - `company` (text)
      - `phone` (text)
      - `message` (text)
      - `locations` (text)
      - `budget` (text)
      - `status` (text)
      - `source` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
  
  2. Security
    - Enable RLS
    - Add policies for lead creation
*/

CREATE TABLE IF NOT EXISTS enterprise_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  company text NOT NULL,
  phone text,
  message text NOT NULL,
  locations text NOT NULL,
  budget text NOT NULL,
  status text NOT NULL DEFAULT 'new',
  source text NOT NULL DEFAULT 'website',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE enterprise_leads ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can create leads"
ON enterprise_leads
FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Only admins can view leads"
ON enterprise_leads
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'admin'
  )
);

-- Add audit trigger
CREATE TRIGGER enterprise_leads_audit_trigger
  BEFORE UPDATE ON enterprise_leads
  FOR EACH ROW
  EXECUTE FUNCTION update_audit_fields();