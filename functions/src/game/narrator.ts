import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import * as admin from 'firebase-admin';
import { Card } from './deck';

const ai = genkit({
  plugins: [googleAI({
    apiKey: 'AIzaSyDn6HLlxBpHf1qu8ndYqlz5pMwGNjaf-GM'
  })],
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
    model: googleAI.model('gemini-3-flash-preview'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};

export const narrateBid = async (gameId: string, playerId: string, bid: number) => {
  const prompt = `You are a witty card game narrator for a game called Pedro. 
  A player just bid ${bid} points. Provide a short, 1-sentence reaction or commentary about this bid. 
  Keep it lighthearted and competitive.`;

  const response = await ai.generate({
    model: googleAI.model('gemini-3-flash-preview'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};

export const narratePointEvent = async (gameId: string, playerName: string, pointType: string, isStolen: boolean) => {
  let context = '';
  if (pointType === 'Jack') {
    context = isStolen
      ? `${playerName} just "Hung the Jack"! They stole it from an opponent for a massive 3-point swing!`
      : `${playerName} played and won their own Jack for 1 point. Safe play.`;
  } else if (pointType === '5') {
    context = `${playerName} just won a lift with the 5 of trumps! That's 5 big points.`;
  } else if (pointType === '9') {
    context = `${playerName} secured the 9 of trumps! 9 points in one go!`;
  } else if (pointType === 'High') {
    context = `${playerName} now holds the High trump point.`;
  } else if (pointType === 'Low') {
    context = `${playerName} just played the lowest trump. They get 1 point even if they lose the lift!`;
  }

  const prompt = `You are a witty card game narrator for Pedro.
  Event: ${context}
  Provide a short, 1-sentence witty reaction to this specific event.
  If it is a "Hang Jack" event, be extra dramatic about the theft.`;

  const response = await ai.generate({
    model: googleAI.model('gemini-3-flash-preview'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};

export const narratePlay = async (gameId: string, playerId: string, card: Card, isSpecial: boolean) => {
  // Deprecated in favor of narratePointEvent but keeping for compatibility if needed
  if (!isSpecial) return;
  const prompt = `You are a witty card game narrator for Pedro. 
  A player just played a high-value card: ${card.rank} of ${card.suit}. 
  Provide a short, 1-sentence witty reaction.`;
  const response = await ai.generate({
    model: googleAI.model('gemini-3-flash-preview'),
    prompt: prompt,
  });
  await postCommentary(gameId, response.text.trim());
};
