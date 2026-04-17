const admin = require('firebase-admin');
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { createDeck, shuffle } = require('./src/game/deck');
const { evaluateLiftWinner } = require('./src/game/logic');
const { narrateWelcome, narrateBid, narratePlay } = require('./src/game/narrator');

admin.initializeApp();

exports.createGame = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { roomName } = request.data;
  if (!roomName) throw new HttpsError('invalid-argument', 'Room name is required.');
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc();
  const gameData = { hostId: uid, name: roomName, playerIds: [uid], status: 'waiting', createdAt: admin.firestore.FieldValue.serverTimestamp() };
  await gameRef.set(gameData);
  
  narrateWelcome(gameRef.id, roomName).catch(console.error);

  return { gameId: gameRef.id };
});

exports.joinGame = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId } = request.data;
  if (!gameId) throw new HttpsError('invalid-argument', 'Game ID is required.');
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data();
  if (gameData.status !== 'waiting') throw new HttpsError('failed-precondition', 'Game has already started.');
  if (gameData.playerIds.length >= 8) throw new HttpsError('failed-precondition', 'Game room is full.');
  if (gameData.playerIds.includes(uid)) return { success: true };
  await gameRef.update({ playerIds: admin.firestore.FieldValue.arrayUnion(uid) });
  return { success: true };
});

exports.startGame = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data();
  if (gameData.hostId !== uid) throw new HttpsError('permission-denied', 'Only the host can start.');
  const playerIds = gameData.playerIds;
  if (playerIds.length < 4) throw new HttpsError('failed-precondition', 'Need at least 4 players.');
  let cardsPerPlayer = 0;
  if (playerIds.length === 4) cardsPerPlayer = 9;
  else if (playerIds.length === 5) cardsPerPlayer = 6;
  else if (playerIds.length === 6) cardsPerPlayer = 4;
  else if (playerIds.length === 7) cardsPerPlayer = 3;
  else if (playerIds.length === 8) cardsPerPlayer = 2;
  const deck = shuffle(createDeck());
  const playerHands = {};
  for (const pid of playerIds) playerHands[pid] = deck.splice(0, cardsPerPlayer);
  const sessionData = {
    status: 'playing',
    currentRound: {
      dealerId: uid,
      phase: 'wadger',
      deck: deck,
      playerStates: playerIds.map(pid => ({ uid: pid, hand: playerHands[pid], currentRoundPoints: 0, totalScore: 0 })),
      bidWinnerId: null,
      bidValue: 0,
      turnIndex: (playerIds.indexOf(uid) + 1) % playerIds.length,
      consecutivePasses: 0,
    }
  };
  await gameRef.update(sessionData);
  return { success: true };
});

exports.submitBid = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId, bid } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data();
  const round = gameData.currentRound;
  if (round.phase !== 'wadger') throw new HttpsError('failed-precondition', 'Not in wadger phase.');
  const playerIds = gameData.playerIds;
  if (uid !== playerIds[round.turnIndex]) throw new HttpsError('failed-precondition', 'Not your turn.');
  let newBidValue = round.bidValue;
  let newBidWinnerId = round.bidWinnerId;
  let newConsecutivePasses = round.consecutivePasses || 0;
  if (bid === null) newConsecutivePasses++;
  else {
    if (bid <= round.bidValue) throw new HttpsError('invalid-argument', 'Bid must be higher.');
    newBidValue = bid;
    newBidWinnerId = uid;
    newConsecutivePasses = 0;
  }
  const numPlayers = playerIds.length;
  let nextPhase = 'wadger';
  let nextTurnIndex = (round.turnIndex + 1) % numPlayers;
  if (newConsecutivePasses === numPlayers - 1 && newBidWinnerId !== null) {
    nextPhase = 'discarding';
    nextTurnIndex = playerIds.indexOf(newBidWinnerId);
  } else if (newConsecutivePasses === numPlayers) {
    newBidValue = 1; newBidWinnerId = round.dealerId; nextPhase = 'discarding'; nextTurnIndex = playerIds.indexOf(newBidWinnerId);
  }
  await gameRef.update({ 'currentRound.bidValue': newBidValue, 'currentRound.bidWinnerId': newBidWinnerId, 'currentRound.consecutivePasses': newConsecutivePasses, 'currentRound.phase': nextPhase, 'currentRound.turnIndex': nextTurnIndex });
  
  if (bid !== null && bid >= 7) {
    narrateBid(gameId, uid, bid).catch(console.error);
  }

  return { success: true };
});

exports.setTrumpSuit = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId, suit } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data();
  const round = gameData.currentRound;
  if (round.phase !== 'discarding') throw new HttpsError('failed-precondition', 'Not in discarding phase.');
  if (uid !== round.bidWinnerId) throw new HttpsError('permission-denied', 'Only bid winner.');
  const playerIds = gameData.playerIds;
  const playerStates = round.playerStates;
  const discardedCards = [];
  for (const ps of playerStates) {
    const keep = ps.hand.filter(c => c.suit === suit);
    const discard = ps.hand.filter(c => c.suit !== suit);
    ps.hand = keep; discardedCards.push(...discard);
  }
  const newDeck = [...round.deck, ...shuffle(discardedCards)];
  const bidWinnerIndex = playerIds.indexOf(uid);
  for (let i = 0; i < playerIds.length; i++) {
    const ps = playerStates.find(p => p.uid === playerIds[(bidWinnerIndex + i) % playerIds.length]);
    while (ps.hand.length < 6 && newDeck.length > 0) ps.hand.push(newDeck.shift());
  }
  await gameRef.update({ 'currentRound.trumpSuit': suit, 'currentRound.phase': 'playing', 'currentRound.playerStates': playerStates, 'currentRound.deck': newDeck, 'currentRound.turnIndex': bidWinnerIndex, 'currentRound.currentLift': { leadPlayerId: uid, plays: {}, winnerId: null } });
  return { success: true };
});

exports.playCard = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId, card } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data();
  const round = gameData.currentRound;
  if (round.phase !== 'playing') throw new HttpsError('failed-precondition', 'Not in playing phase.');
  if (uid !== gameData.playerIds[round.turnIndex]) throw new HttpsError('failed-precondition', 'Not your turn.');
  const playerState = round.playerStates.find(p => p.uid === uid);
  const cardIndex = playerState.hand.findIndex(c => c.suit === card.suit && c.rank === card.rank);
  if (cardIndex === -1) throw new HttpsError('invalid-argument', 'Card not in hand.');
  playerState.hand.splice(cardIndex, 1);
  const currentLift = round.currentLift;
  currentLift.plays[uid] = card;
  let nextTurnIndex = (round.turnIndex + 1) % gameData.playerIds.length;
  let nextPhase = 'playing';
  if (Object.keys(currentLift.plays).length === gameData.playerIds.length) {
    const leadSuit = currentLift.plays[currentLift.leadPlayerId].suit;
    const winnerId = evaluateLiftWinner(currentLift.plays, leadSuit, round.trumpSuit);
    currentLift.winnerId = winnerId;
    const winnerState = round.playerStates.find(p => p.uid === winnerId);
    let liftPoints = 0;
    let isSpecial = false;
    for (const [pId, playedCard] of Object.entries(currentLift.plays)) {
      if (playedCard.suit === round.trumpSuit) {
        if (playedCard.rank === 'five') { liftPoints += 5; isSpecial = true; }
        if (playedCard.rank === 'nine') { liftPoints += 9; isSpecial = true; }
        if (playedCard.rank === 'ten') liftPoints += 1;
        if (playedCard.rank === 'jack') {
          liftPoints += (pId === winnerId) ? 1 : 3;
          isSpecial = true;
        }
      }
    }
    winnerState.currentRoundPoints += liftPoints;
    
    if (isSpecial) {
      narratePlay(gameId, uid, card, true).catch(console.error);
    }

    if (round.playerStates.every(p => p.hand.length === 0)) nextPhase = 'finished';
    else {
      round.currentLift = { leadPlayerId: winnerId, plays: {}, winnerId: null };
      nextTurnIndex = gameData.playerIds.indexOf(winnerId);
    }
  }
  await gameRef.update({ 'currentRound.playerStates': round.playerStates, 'currentRound.currentLift': round.currentLift, 'currentRound.turnIndex': nextTurnIndex, 'currentRound.phase': nextPhase });
  return { success: true };
});
