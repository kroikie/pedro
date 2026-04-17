const admin = require('firebase-admin');
const { onCall, HttpsError } = require("firebase-functions/v2/https");

admin.initializeApp();

exports.createGame = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in to create a game.');
  }

  const { roomName } = request.data;
  if (!roomName) {
    throw new HttpsError('invalid-argument', 'Room name is required.');
  }

  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc();

  const gameData = {
    hostId: uid,
    name: roomName,
    playerIds: [uid],
    status: 'waiting',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await gameRef.set(gameData);

  return { gameId: gameRef.id };
});

exports.joinGame = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in to join a game.');
  }

  const { gameId } = request.data;
  if (!gameId) {
    throw new HttpsError('invalid-argument', 'Game ID is required.');
  }

  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();

  if (!gameDoc.exists) {
    throw new HttpsError('not-found', 'Game not found.');
  }

  const gameData = gameDoc.data();
  if (gameData.status !== 'waiting') {
    throw new HttpsError('failed-precondition', 'Game has already started or finished.');
  }

  if (gameData.playerIds.length >= 4) {
    throw new HttpsError('failed-precondition', 'Game room is full.');
  }

  if (gameData.playerIds.includes(uid)) {
    return { success: true };
  }

  await gameRef.update({
    playerIds: admin.firestore.FieldValue.arrayUnion(uid)
  });

  return { success: true };
});
