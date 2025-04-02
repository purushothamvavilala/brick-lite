import { generateBrickTone, BrickPersonaContext } from './brickPersona';

// Default sample menu to avoid fallback errors
const sampleMenu = [
  { name: "Margherita Pizza", ingredients: ["tomato", "mozzarella", "basil"], calories: 300 },
  { name: "Paneer Butter Masala", ingredients: ["paneer", "butter", "spices"], calories: 450 },
  { name: "Vegan Buddha Bowl", ingredients: ["quinoa", "chickpeas", "avocado"], calories: 350 }
];

import OpenAI from 'openai';
import { sampleMenu } from '../types';
import { extractFoodEntities } from './nlp';
import { useBFFStore } from './store';

if (!import.meta.env.VITE_OPENAI_API_KEY) {
  throw new Error('OpenAI API key is required. Please set VITE_OPENAI_API_KEY in your environment variables.');
}

const openai = new OpenAI({
  apiKey: import.meta.env.VITE_OPENAI_API_KEY,
  dangerouslyAllowBrowser: true
});

function getSystemPrompt(restaurantContext: any = null, businessTesting: any = null, emotion: EmotionAnalysis) {
  let prompt = `You are BFF (Brick For Food), an emotionally intelligent AI restaurant assistant. Adapt your personality based on the customer's mood:

Current Customer Mood: ${emotion.primary} (Intensity: ${emotion.intensity})
Context Clues: ${emotion.context.join(', ')}

Response Guidelines:
- For excited customers: Match their enthusiasm, suggest special experiences
- For hungry customers: Be quick and direct, focus on immediate satisfaction
- For rushed customers: Keep responses brief and actionable
- For confused customers: Be extra clear and patient, offer simple choices
- For happy customers: Enhance their mood with delightful suggestions
- For frustrated customers: Be empathetic and solution-focused

Always:
- Keep responses concise but warm
- Adapt tone to match customer mood
- Anticipate needs based on emotional context
- Offer relevant suggestions
- Create memorable moments`;

  if (businessTesting?.isBusinessOwner) {
    prompt += `\n\nI notice you're evaluating BFF for your business. I'd love to demonstrate how I can help with:`;
    
    if (businessTesting.features) {
      prompt += `\n- ${businessTesting.features.join('\n- ')}`;
    }
    
    if (businessTesting.testType === 'simulation') {
      prompt += `\n\nI'll demonstrate a natural guest interaction`;
      if (businessTesting.language === 'es') {
        prompt += ` in Spanish`;
      }
    }
    
    if (businessTesting.cuisine) {
      prompt += `\n\nI'll tailor my expertise to ${businessTesting.cuisine} cuisine, including its history, techniques, and regional variations.`;
    }
  }

  if (restaurantContext) {
    prompt += `\n\nI'm representing ${restaurantContext.name}, a ${restaurantContext.type} renowned for exceptional ${restaurantContext.cuisine} cuisine.\n\n${restaurantContext.description}\n\nOur signature dishes include: ${restaurantContext.specialties.join(', ')}`;
  }

  prompt += `\n\nComplete Menu Details:\n${JSON.stringify(sampleMenu, null, 2)}`;

  return prompt;
}

const PERSONALITY_RESPONSES = {
  GREETING: [
    "Hey there! 👋 I'm your foodie friend Brick! Ready to explore some amazing flavors together?",
    "Hi! I'm Brick, your personal taste adventure guide! What delicious journey shall we begin today? ✨",
    "Welcome, food lover! 🌟 I'm Brick, and I'm super excited to help you discover something amazing!"
  ],
  ENTHUSIASM: [
    "Oh wow, fantastic choice! 🎉 You're going to love this one - let me tell you why it's special...",
    "Yum! 😋 That's one of my absolute favorites! Let me share what makes it magical...",
    "Perfect pick! 🌟 Get ready for a taste sensation - this dish has an amazing story..."
  ],
  RECOMMENDATION: [
    "Ooh, I've got something perfect for you! 🎯 Based on your taste, you're going to absolutely love...",
    "I'm excited to suggest this one! ✨ It's been making our guests smile all week...",
    "Let me share a hidden gem with you! 💎 This dish is getting rave reviews..."
  ],
  APOLOGY: [
    "Oops! 🙈 Let me make this right for you - your satisfaction is my top priority!",
    "Oh no! 😅 Thanks for your patience - let me fix this and make your experience amazing!",
    "My bad! 🌟 Let me turn this around and make your experience extra special!"
  ],
  WINE_PAIRING: [
    "I've got the perfect wine match! 🍷 This pairing will make your taste buds dance...",
    "Oh, you're in for a treat! 🌟 This wine will elevate your dish to a whole new level...",
    "Let me work some magic! ✨ This wine pairing will make your meal unforgettable..."
  ],
  DIETARY_ACCOMMODATION: [
    "I've got your back! 💪 Let me show you some amazing options that perfectly fit your needs...",
    "No worries at all! 🌱 I know just the dishes that'll make you happy and healthy...",
    "You're in good hands! ✨ I'll make sure every bite is both safe and delicious..."
  ]
};

function getPersonalizedResponse(type: keyof typeof PERSONALITY_RESPONSES): string {
  const responses = PERSONALITY_RESPONSES[type];
  return responses[Math.floor(Math.random() * responses.length)];
}

export async function generateResponse(
  message: string,
  context: string,
  emotion: EmotionAnalysis,
  language: string,
  userId: string,
  restaurantContext: any = null,
  businessTesting: any = null
): Promise<{ content: string; menuItems?: typeof sampleMenu }> {
  try {
    const entities = extractFoodEntities(message);
    
    let conversationContext = context
      ? `Previous conversation:\n${context}\n\nCurrent message: ${message}\nCustomer Mood: ${entities.emotion.primary}`
      : message;

    const store = useBFFStore.getState();
    if (store.currentOrder.items.length > 0) {
      conversationContext += '\n\nCurrent Order:\n' + JSON.stringify(store.currentOrder.items);
    }

    const response = await Promise.race([
      openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: getSystemPrompt(restaurantContext, businessTesting)
          },
          {
            role: "user",
            content: conversationContext
          }
        ],
        temperature: 0.8,
        max_tokens: 500,
        presence_penalty: 0.6,
        frequency_penalty: 0.3
      }),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('TIMEOUT')), 15000)
      )
    ]);

    if (typeof response === 'object' && 'choices' in response) {
      let content = response.choices[0].message.content || 
        getPersonalizedResponse('GREETING');

      // Add personality touches
      if (message.toLowerCase().includes('hello') || message.toLowerCase().includes('hi')) {
        content = `${getPersonalizedResponse('GREETING')} ${content}`;
      }

      if (entities.dishes.length > 0) {
        content = `${getPersonalizedResponse('ENTHUSIASM')} ${content}`;
      }

      if (message.toLowerCase().includes('wine')) {
        content = `${getPersonalizedResponse('WINE_PAIRING')} ${content}`;
      }

      if (message.toLowerCase().includes('vegan') || message.toLowerCase().includes('allergy')) {
        content = `${getPersonalizedResponse('DIETARY_ACCOMMODATION')} ${content}`;
      }

      const menuItems = entities.dishes.length > 0 || entities.category
        ? sampleMenu.filter(item => {
            if (entities.category) {
              return item.category.toLowerCase() === entities.category.toLowerCase();
            }
            return entities.dishes.some(dish => 
              item.name.toLowerCase().includes(dish.toLowerCase()) ||
              item.description.toLowerCase().includes(dish.toLowerCase())
            );
          }).slice(0, 3)
        : undefined;

      return { content, menuItems };
    }

    throw new Error('Invalid response format from OpenAI');
  } catch (error) {
    console.error('Error generating response:', error);

    if (error instanceof OpenAI.APIError) {
      if (error.status === 429) {
        return { content: getPersonalizedResponse('APOLOGY') + " We're experiencing high demand right now. I'll be able to help you better in a moment." };
      }
      return { content: getPersonalizedResponse('APOLOGY') + " I'm having trouble connecting right now. Could you please try again?" };
    }

    if (error.message === 'TIMEOUT') {
      return { content: getPersonalizedResponse('APOLOGY') + " I apologize for the delay. I'd love to help you find what you're looking for. Could you please try again?" };
    }

    return {
      content: getPersonalizedResponse('GREETING') + " I'd be delighted to help you discover our menu. What interests you today?",
      menuItems: sampleMenu.slice(0, 3)
    };
  }


  const sessionPersona: BrickPersonaContext = {
    userName: context?.userName || 'friend',
    location: context?.location || 'the kitchen of dreams',
    dietaryPreference: context?.dietary || 'anything tasty',
    mood: context?.mood || 'friendly',
    flavorStyle: context?.flavorStyle || 'classic'
  };

  const systemPrompt = generateBrickTone(sessionPersona);



}