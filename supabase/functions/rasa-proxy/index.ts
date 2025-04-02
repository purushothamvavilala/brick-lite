import { OpenAI } from "openai";

const RASA_URL = Deno.env.get('RASA_URL') || 'https://brick-rasa-pro.onrender.com';
const RASA_TOKEN = Deno.env.get('RASA_TOKEN');
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');

if (!OPENAI_API_KEY) {
  throw new Error('OpenAI API key is required. Please set OPENAI_API_KEY in your environment variables.');
}

const openai = new OpenAI({
  apiKey: OPENAI_API_KEY,
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { message, sender_id, metadata } = await req.json();

    // First try Rasa
    try {
      const rasaResponse = await fetch(`${RASA_URL}/webhooks/rest/webhook`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RASA_TOKEN}`
        },
        body: JSON.stringify({
          sender: sender_id,
          message,
          metadata
        })
      });

      const data = await rasaResponse.json();

      // If Rasa provided a valid response, return it
      if (data && Array.isArray(data) && data.length > 0) {
        return new Response(
          JSON.stringify(data),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          }
        );
      }
    } catch (error) {
      console.error('Rasa error:', error);
    }

    // If Rasa failed or returned no response, use OpenAI fallback
    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are Brick, an AI food assistant. Keep responses focused on food, orders, and restaurant operations."
        },
        {
          role: "user",
          content: message
        }
      ],
      temperature: 0.7,
      max_tokens: 150
    });

    return new Response(
      JSON.stringify([{
        text: completion.choices[0].message.content,
        custom: {
          source: 'openai',
          fallback: true
        }
      }]),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error:', error);
    
    return new Response(
      JSON.stringify([{
        text: "I apologize, but I'm having trouble connecting right now. Please try again in a moment.",
        custom: { error: error.message }
      }]),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    );
  }
});