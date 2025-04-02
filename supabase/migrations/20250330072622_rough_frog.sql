/*
  # Add new order statuses and update constraints
  
  1. Changes
    - Add new order statuses: preparing, ready, served
    - Update status constraint
    - Add indexes for performance
  
  2. Security
    - Maintain existing RLS policies
*/

-- Update status constraint
ALTER TABLE orders DROP CONSTRAINT IF EXISTS valid_status;
ALTER TABLE orders ADD CONSTRAINT valid_status 
  CHECK (status IN ('draft', 'confirmed', 'preparing', 'ready', 'served', 'cancelled'));

-- Add index for status and confirmed_at combination
CREATE INDEX IF NOT EXISTS idx_orders_status_confirmed_at 
  ON orders(status, confirmed_at);