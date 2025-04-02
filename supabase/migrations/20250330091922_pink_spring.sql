/*
  # Add Menu Items Table
  
  1. New Tables
    - `menu_items`
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `price` (numeric)
      - `category` (text)
      - `position` (integer)
      - `nutrition` (jsonb)
      - `customization_options` (jsonb)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
  
  2. Security
    - Enable RLS on menu_items table
    - Add policies for authenticated users
*/

CREATE TABLE IF NOT EXISTS menu_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price numeric(10,2) NOT NULL,
  category text NOT NULL,
  position integer NOT NULL DEFAULT 0,
  nutrition jsonb DEFAULT '{}'::jsonb,
  customization_options jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_position ON menu_items(position);

-- Enable RLS
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view menu items"
ON menu_items
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can manage menu items"
ON menu_items
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Add audit trigger
CREATE TRIGGER menu_items_audit_trigger
  BEFORE UPDATE ON menu_items
  FOR EACH ROW
  EXECUTE FUNCTION update_audit_fields();