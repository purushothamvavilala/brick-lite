import OpenAI from 'openai';
import { sampleMenu } from '../types'; // Ensure this is imported only once
import { extractFoodEntities } from './nlp';
import { useBFFStore } from './store';

// Create an OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY, // Ensure the OpenAI API key is available in your environment variables
});

// Function to generate responses based on user input
export const generateResponse = async (userInput: string) => {
  try {
    // Extract food-related entities from the user input using NLP
    const foodEntities = extractFoodEntities(userInput);

    // Generate a prompt based on the extracted food entities and the user's message
    const prompt = `User wants to know about ${foodEntities.join(', ')}`;

    // Call OpenAI to generate a response
    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'system', content: 'You are a helpful assistant.' },
        { role: 'user', content: prompt },
      ],
    });

    // Return the OpenAI response
    return response.choices[0].message.content;

  } catch (error) {
    console.error('Error generating response:', error);
    return 'Sorry, something went wrong. Please try again later.';
  }
};

// Function to handle fallback to OpenAI when Rasa is unavailable
export const fallbackToOpenAI = async (userInput: string) => {
  const response = await generateResponse(userInput);
  return response;
};

// Example function to handle interactions with the sample menu
export const handleSampleMenuInteraction = async (userInput: string) => {
  const menuItems = sampleMenu.filter(item => item.toLowerCase().includes(userInput.toLowerCase()));

  if (menuItems.length > 0) {
    return `Here are some items from the menu that match your query: ${menuItems.join(', ')}`;
  } else {
    return 'Sorry, no items found matching your input. Please try again.';
  }
};

// Example function to get AI-powered food recommendations
export const getFoodRecommendation = async (userPreferences: string) => {
  const prompt = `Give a food recommendation based on these preferences: ${userPreferences}`;

  const response = await generateResponse(prompt);
  return `Based on your preferences, I recommend: ${response}`;
};

