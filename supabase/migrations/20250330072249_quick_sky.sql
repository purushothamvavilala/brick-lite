/*
  # Add Orders Table and Relations
  
  1. New Tables
    - `orders`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `items` (jsonb, stores order details)
      - `total_amount` (numeric)
      - `status` (text)
      - `confirmed_at` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
  
  2. Security
    - Enable RLS on orders table
    - Add policies for authenticated users
    - Ensure proper data isolation
*/

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  items jsonb NOT NULL DEFAULT '[]'::jsonb,
  total_amount numeric(10,2) NOT NULL,
  status text NOT NULL DEFAULT 'draft',
  confirmed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id),
  
  -- Add constraint to validate status
  CONSTRAINT valid_status CHECK (status IN ('draft', 'confirmed', 'cancelled'))
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_confirmed_at ON orders(confirmed_at);

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own orders"
ON orders
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can create orders"
ON orders
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() AND
  created_at <= now() AND
  updated_at <= now()
);

CREATE POLICY "Users can update their own orders"
ON orders
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Add audit trigger
CREATE TRIGGER orders_audit_trigger
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_audit_fields();