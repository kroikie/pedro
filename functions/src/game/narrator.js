const { genkit } = require('genkit');
const { googleAI } = require('@genkit-ai/google-genai');
const admin = require('firebase-admin');

const ai = genkit({
  plugins: [googleAI()],
});

async function postCommentary(gameId, text) {
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

exports.narrateWelcome = async (gameId, roomName) => {
  const prompt = `You are a witty card game narrator for Pedro. 
  A new game room named "${roomName}" has just been created. 
  Provide a short, 1-sentence witty welcome message for the players joining this room.`;

  const response = await ai.generate({
    model: googleAI.model('gemini-1.5-flash'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};

exports.narrateBid = async (gameId, playerId, bid) => {
  const prompt = `You are a witty card game narrator for a game called Pedro. 
  A player just bid ${bid} points. Provide a short, 1-sentence reaction or commentary about this bid. 
  Keep it lighthearted and competitive.`;

  const response = await ai.generate({
    model: googleAI.model('gemini-1.5-flash'),
    prompt: prompt,
  });

  await postCommentary(gameId, response.text.trim());
};

exports.narratePlay = async (gameId, playerId, card, isSpecial) => {
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
