import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import * as admin from 'firebase-admin';
import { Card } from './deck';

const ai = genkit({
  plugins: [googleAI({
    apiKey: 'AIzaSyDn6HLlxBpHf1qu8ndYqlz5pMwGNjaf-GM'
  }
  )],
});

async function postCommentary(gameId: string, text: string) {
  await admin.firestore()
    .collection('games')
    .doc(gameId)
    .collection('messages')
    .add({
      senderId: 'ai_narrator',
      senderName: 'AI Narrator',
      text: text,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isAi: true,
    });
}

export const narrateWelcome = async (gameId: string, roomName: string) => {
  const prompt = `You are a witty card game narrator for Pedro. 
  A new game room named "${roomName}" has just been created. 
  Provide a short, 1-sentence witty welcome message for the players joining this room.`;

  const response = await ai.generate({
    model: googleAI.model('gemini-3.1-flash-lite-preview'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};

export const narrateBid = async (gameId: string, playerId: string, bid: number) => {
  const prompt = `You are a witty card game narrator for a game called Pedro. 
  A player just bid ${bid} points. Provide a short, 1-sentence reaction or commentary about this bid. 
  Keep it lighthearted and competitive.`;

  const response = await ai.generate({
    model: googleAI.model('gemini-1.5-flash'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};

export const narratePlay = async (gameId: string, playerId: string, card: Card, isSpecial: boolean) => {
  if (!isSpecial) return;

  const prompt = `You are a witty card game narrator for Pedro. 
  A player just played a high-value card: ${card.rank} of ${card.suit}. 
  Provide a short, 1-sentence witty reaction.`;

  const response = await ai.generate({
    model: googleAI.model('gemini-1.5-flash'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};
