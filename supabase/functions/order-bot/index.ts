import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { order, restaurantId } = await req.json();

    // Create Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    // Insert order into database
    const { data: orderData, error: orderError } = await supabase
      .from('orders')
      .insert([{
        ...order,
        restaurant_id: restaurantId,
        status: 'pending'
      }])
      .select()
      .single();

    if (orderError) throw orderError;

    // Send notification through realtime
    const { error: notifyError } = await supabase
      .from('order_notifications')
      .insert([{
        order_id: orderData.id,
        restaurant_id: restaurantId,
        type: 'new_order',
        message: `New order #${orderData.id.slice(-6)} received`,
        metadata: {
          order: orderData
        }
      }]);

    if (notifyError) throw notifyError;

    return new Response(
      JSON.stringify({ success: true, order: orderData }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});