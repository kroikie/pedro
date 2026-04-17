import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { createDeck, shuffle, Suit, Card, Rank } from './game/deck';
import { evaluateLiftWinner, RankValues } from './game/logic';
import { narrateWelcome, narrateBid, narratePointEvent } from './game/narrator';

admin.initializeApp();

interface CreateGameData {
  roomName: string;
  targetScore?: number;
}

export const createGame = onCall<CreateGameData>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { roomName, targetScore } = request.data;
  if (!roomName) throw new HttpsError('invalid-argument', 'Room name is required.');
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc();
  const gameData = {
    hostId: uid,
    name: roomName,
    targetScore: targetScore || 35,
    playerIds: [uid],
    invitedPlayerIds: [],
    status: 'waiting',
    createdAt: FieldValue.serverTimestamp()
  };
  await gameRef.set(gameData);

  narrateWelcome(gameRef.id, roomName).catch(console.error);

  return { gameId: gameRef.id };
});

interface InvitePlayerData {
  gameId: string;
  targetPlayerId: string;
}

export const invitePlayer = onCall<InvitePlayerData>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId, targetPlayerId } = request.data;
  const uid = request.auth.uid;

  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');

  const gameData = gameDoc.data()!;
  if (gameData.hostId !== uid) throw new HttpsError('permission-denied', 'Only the host can invite players.');

  await gameRef.update({
    invitedPlayerIds: FieldValue.arrayUnion(targetPlayerId)
  });

  return { success: true };
});

interface JoinGameData {
  gameId: string;
}

export const joinGame = onCall<JoinGameData>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId } = request.data;
  if (!gameId) throw new HttpsError('invalid-argument', 'Game ID is required.');
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data()!;

  if (gameData.status !== 'waiting') throw new HttpsError('failed-precondition', 'Game has already started.');
  if (gameData.playerIds.length >= 8) throw new HttpsError('failed-precondition', 'Game room is full.');

  if (gameData.playerIds.includes(uid)) return { success: true };

  const isInvited = gameData.invitedPlayerIds && gameData.invitedPlayerIds.includes(uid);
  if (!isInvited && gameData.hostId !== uid) {
    throw new HttpsError('permission-denied', 'You are not invited to this game.');
  }

  await gameRef.update({
    playerIds: FieldValue.arrayUnion(uid),
    invitedPlayerIds: FieldValue.arrayRemove(uid)
  });
  return { success: true };
});

interface StartGameData {
  gameId: string;
}

export const startGame = onCall<StartGameData>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data()!;
  if (gameData.hostId !== uid) throw new HttpsError('permission-denied', 'Only the host can start.');
  const playerIds: string[] = gameData.playerIds;
  if (playerIds.length < 4) throw new HttpsError('failed-precondition', 'Need at least 4 players.');

  let cardsPerPlayer = 0;
  if (playerIds.length === 4) cardsPerPlayer = 9;
  else if (playerIds.length === 5) cardsPerPlayer = 6;
  else if (playerIds.length === 6) cardsPerPlayer = 4;
  else if (playerIds.length === 7) cardsPerPlayer = 3;
  else if (playerIds.length === 8) cardsPerPlayer = 2;

  const deck = shuffle(createDeck());
  const playerHands: Record<string, Card[]> = {};
  for (const pid of playerIds) playerHands[pid] = deck.splice(0, cardsPerPlayer);

  const sessionData = {
    status: 'playing',
    currentRound: {
      dealerId: uid,
      phase: 'wadger',
      deck: deck,
      playerStates: playerIds.map(pid => ({
        uid: pid,
        hand: playerHands[pid],
        currentRoundPoints: 0,
        totalScore: 0,
        capturedValueCards: [],
        earnedPoints: []
      })),
      bidWinnerId: null,
      bidValue: 0,
      turnIndex: (playerIds.indexOf(uid) + 1) % playerIds.length,
      consecutivePasses: 0,
      playedCards: []
    }
  };
  await gameRef.update(sessionData);
  return { success: true };
});

interface SubmitBidData {
  gameId: string;
  bid: number | null;
}

export const submitBid = onCall<SubmitBidData>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId, bid } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data()!;
  const round = gameData.currentRound;
  if (round.phase !== 'wadger') throw new HttpsError('failed-precondition', 'Not in wadger phase.');
  const playerIds: string[] = gameData.playerIds;
  const playerStates: any[] = round.playerStates;
  if (uid !== playerIds[round.turnIndex]) throw new HttpsError('failed-precondition', 'Not your turn.');

  const playerState = playerStates.find((p: any) => p.uid === uid);

  let newBidValue: number = round.bidValue;
  let newBidWinnerId: string | null = round.bidWinnerId;
  let newConsecutivePasses: number = round.consecutivePasses || 0;

  if (bid === null) {
    newConsecutivePasses++;
    playerState.earnedPoints = ['Pass'];
  } else {
    if (bid <= round.bidValue) throw new HttpsError('invalid-argument', 'Bid must be higher.');
    newBidValue = bid;
    newBidWinnerId = uid;
    newConsecutivePasses = 0;
    // Clear other players' bids that were lower? No, just show latest.
    playerState.earnedPoints = [`Bid: ${bid}`];
  }

  const numPlayers = playerIds.length;
  let nextPhase = 'wadger';
  let nextTurnIndex = (round.turnIndex + 1) % numPlayers;

  if (newConsecutivePasses === numPlayers - 1 && newBidWinnerId !== null) {
    nextPhase = 'discarding';
    nextTurnIndex = playerIds.indexOf(newBidWinnerId);
    // Clear bid chips when moving to next phase
    playerStates.forEach((ps: any) => ps.earnedPoints = []);
  } else if (newConsecutivePasses === numPlayers) {
    newBidValue = 1;
    newBidWinnerId = round.dealerId;
    nextPhase = 'discarding';
    nextTurnIndex = playerIds.indexOf(newBidWinnerId!);
    playerStates.forEach((ps: any) => ps.earnedPoints = []);
  }

  await gameRef.update({
    'currentRound.bidValue': newBidValue,
    'currentRound.bidWinnerId': newBidWinnerId,
    'currentRound.consecutivePasses': newConsecutivePasses,
    'currentRound.phase': nextPhase,
    'currentRound.turnIndex': nextTurnIndex,
    'currentRound.playerStates': playerStates
  });

  if (bid !== null && bid >= 7) {
    narrateBid(gameId, uid, bid).catch(console.error);
  }

  return { success: true };
});

interface SetTrumpSuitData {
  gameId: string;
  suit: Suit;
}

export const setTrumpSuit = onCall<SetTrumpSuitData>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId, suit } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data()!;
  const round = gameData.currentRound;
  if (round.phase !== 'discarding') throw new HttpsError('failed-precondition', 'Not in discarding phase.');
  if (uid !== round.bidWinnerId) throw new HttpsError('permission-denied', 'Only bid winner.');

  const playerIds: string[] = gameData.playerIds;
  const playerStates: any[] = round.playerStates;
  const discardedCards: Card[] = [];
  for (const ps of playerStates) {
    const keep = ps.hand.filter((c: Card) => c.suit === suit);
    const discard = ps.hand.filter((c: Card) => c.suit !== suit);
    ps.hand = keep; discardedCards.push(...discard);
  }
  const newDeck = [...round.deck, ...shuffle(discardedCards)];
  const bidWinnerIndex = playerIds.indexOf(uid);
  for (let i = 0; i < playerIds.length; i++) {
    const ps = playerStates.find(p => p.uid === playerIds[(bidWinnerIndex + i) % playerIds.length]);
    while (ps.hand.length < 6 && newDeck.length > 0) ps.hand.push(newDeck.shift());
  }
  await gameRef.update({
    'currentRound.trumpSuit': suit,
    'currentRound.phase': 'playing',
    'currentRound.playerStates': playerStates,
    'currentRound.deck': newDeck,
    'currentRound.turnIndex': bidWinnerIndex,
    'currentRound.currentLift': { leadPlayerId: uid, plays: {}, winnerId: null },
    'currentRound.highTrumpPlayerId': null,
    'currentRound.lowTrumpPlayerId': null
  });
  return { success: true };
});

interface PlayCardData {
  gameId: string;
  card: Card;
}

export const playCard = onCall<PlayCardData>(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'User must be logged in.');
  const { gameId, card } = request.data;
  const uid = request.auth.uid;
  const gameRef = admin.firestore().collection('games').doc(gameId);
  const gameDoc = await gameRef.get();
  if (!gameDoc.exists) throw new HttpsError('not-found', 'Game not found.');
  const gameData = gameDoc.data()!;
  const round = gameData.currentRound;
  if (round.phase !== 'playing') throw new HttpsError('failed-precondition', 'Not in playing phase.');
  if (uid !== gameData.playerIds[round.turnIndex]) throw new HttpsError('failed-precondition', 'Not your turn.');
  const playerStates: any[] = round.playerStates;
  const playerState = playerStates.find((p: any) => p.uid === uid);
  const cardIndex = playerState.hand.findIndex((c: Card) => c.suit === card.suit && c.rank === card.rank);
  if (cardIndex === -1) throw new HttpsError('invalid-argument', 'Card not in hand.');

  const currentLift = round.currentLift;

  // Following Suit Rule Enforcement
  const isLeader = Object.keys(currentLift.plays).length === 0;
  if (!isLeader) {
    const leadCard = currentLift.plays[currentLift.leadPlayerId];
    const leadSuit = leadCard.suit;
    if (card.suit !== round.trumpSuit && card.suit !== leadSuit) {
      const hasLeadSuit = playerState.hand.some((c: Card) => c.suit === leadSuit);
      if (hasLeadSuit) throw new HttpsError('invalid-argument', `Must follow suit (${leadSuit}) or play Trump.`);
    }
  }

  playerState.hand.splice(cardIndex, 1);
  currentLift.plays[uid] = card;

  const playedCards = round.playedCards || [];
  playedCards.push(card);

  // Track High/Low Trumps and Assign Points IMMEDIATELY to holder
  if (card.suit === round.trumpSuit) {
    // High Trump logic
    if (!round.highTrumpPlayerId || RankValues[card.rank as Rank] > RankValues[round.highTrumpPlayedCard.rank as Rank]) {
      if (round.highTrumpPlayerId) {
        const oldHolder = playerStates.find((ps: any) => ps.uid === round.highTrumpPlayerId);
        oldHolder.currentRoundPoints -= 1;
        oldHolder.earnedPoints = (oldHolder.earnedPoints || []).filter((p: string) => p !== 'High');
      }
      playerState.currentRoundPoints += 1;
      playerState.earnedPoints = [...(playerState.earnedPoints || []), 'High'];
      round.highTrumpPlayerId = uid;
      round.highTrumpPlayedCard = card;

      narratePointEvent(gameId, "A player", "High", false).catch(console.error);
    }
    // Low Trump logic
    if (!round.lowTrumpPlayerId || RankValues[card.rank as Rank] < RankValues[round.lowTrumpPlayedCard.rank as Rank]) {
      if (round.lowTrumpPlayerId) {
        const oldHolder = playerStates.find((ps: any) => ps.uid === round.lowTrumpPlayerId);
        oldHolder.currentRoundPoints -= 1;
        oldHolder.earnedPoints = (oldHolder.earnedPoints || []).filter((p: string) => p !== 'Low');
      }
      playerState.currentRoundPoints += 1;
      playerState.earnedPoints = [...(playerState.earnedPoints || []), 'Low'];
      round.lowTrumpPlayerId = uid;
      round.lowTrumpPlayedCard = card;

      narratePointEvent(gameId, "A player", "Low", false).catch(console.error);
    }
  }

  let nextTurnIndex = (round.turnIndex + 1) % gameData.playerIds.length;
  let nextPhase = 'playing';

  if (Object.keys(currentLift.plays).length === gameData.playerIds.length) {
    const leadSuit = currentLift.plays[currentLift.leadPlayerId].suit;
    const winnerId = evaluateLiftWinner(currentLift.plays, leadSuit, round.trumpSuit);
    currentLift.winnerId = winnerId;
    const winnerState = playerStates.find((p: any) => p.uid === winnerId);

    let liftPoints = 0;
    for (const [pId, playedCard] of Object.entries<Card>(currentLift.plays)) {
      if (playedCard.suit === round.trumpSuit) {
        if (playedCard.rank === 'five') {
          liftPoints += 5;
          winnerState.earnedPoints = [...(winnerState.earnedPoints || []), '5'];
          narratePointEvent(gameId, "A player", "5", false).catch(console.error);
        }
        if (playedCard.rank === 'nine') {
          liftPoints += 9;
          winnerState.earnedPoints = [...(winnerState.earnedPoints || []), '9'];
          narratePointEvent(gameId, "A player", "9", false).catch(console.error);
        }
        if (playedCard.rank === 'jack') {
          const isStolen = pId !== winnerId;
          liftPoints += isStolen ? 3 : 1;
          winnerState.earnedPoints = [...(winnerState.earnedPoints || []), isStolen ? 'Hang Jack' : 'Jack'];
          narratePointEvent(gameId, "A player", "Jack", isStolen).catch(console.error);
        }
      }
      const valueMap: any = { 'ten': 10, 'jack': 1, 'queen': 2, 'king': 3, 'ace': 4 };
      if (valueMap[playedCard.rank]) {
        winnerState.capturedValueCards = winnerState.capturedValueCards || [];
        winnerState.capturedValueCards.push(playedCard);
      }
    }
    winnerState.currentRoundPoints += liftPoints;

    const allHandsEmpty = playerStates.every((p: any) => p.hand.length === 0);
    if (allHandsEmpty) {
      return finalizeRound(gameRef, gameData);
    } else {
      round.currentLift = { leadPlayerId: winnerId, plays: {}, winnerId: null };
      nextTurnIndex = gameData.playerIds.indexOf(winnerId!);
    }
  }

  await gameRef.update({
    'currentRound.playerStates': playerStates,
    'currentRound.currentLift': round.currentLift,
    'currentRound.turnIndex': nextTurnIndex,
    'currentRound.phase': nextPhase,
    'currentRound.highTrumpPlayerId': round.highTrumpPlayerId,
    'currentRound.highTrumpPlayedCard': round.highTrumpPlayedCard,
    'currentRound.lowTrumpPlayerId': round.lowTrumpPlayerId,
    'currentRound.lowTrumpPlayedCard': round.lowTrumpPlayedCard,
    'currentRound.playedCards': playedCards
  });
  return { success: true };
});

async function finalizeRound(gameRef: admin.firestore.DocumentReference, gameData: any) {
  const round = gameData.currentRound;
  const playerStates = round.playerStates;

  const valueMap: any = { 'ten': 10, 'jack': 1, 'queen': 2, 'king': 3, 'ace': 4 };
  let bestValue = -1;
  let gamePointWinner: any = null;
  for (const ps of playerStates) {
    let totalValue = 0;
    (ps.capturedValueCards || []).forEach((c: Card) => totalValue += valueMap[c.rank as Rank]);
    if (totalValue > bestValue) {
      bestValue = totalValue;
      gamePointWinner = ps;
    } else if (totalValue === bestValue) {
      gamePointWinner = null;
    }
  }
  if (gamePointWinner) {
    gamePointWinner.currentRoundPoints += 1;
    gamePointWinner.earnedPoints = [...(gamePointWinner.earnedPoints || []), 'Game'];
  }

  for (const ps of playerStates) {
    if (ps.uid === round.bidWinnerId) {
      if (ps.currentRoundPoints >= round.bidValue) {
        ps.totalScore += ps.currentRoundPoints;
      } else {
        ps.totalScore -= round.bidValue;
      }
    } else {
      ps.totalScore += ps.currentRoundPoints;
    }
  }

  const winner = playerStates.find((ps: any) => ps.totalScore >= gameData.targetScore);
  if (winner) {
    await gameRef.update({
      status: 'finished',
      'currentRound.playerStates': playerStates,
      'currentRound.phase': 'finished',
      winnerId: winner.uid
    });
  } else {
    const playerIds = gameData.playerIds;
    const oldDealerIndex = playerIds.indexOf(round.dealerId);
    const newDealerId = playerIds[(oldDealerIndex + 1) % playerIds.length];

    let cardsPerPlayer = 0;
    if (playerIds.length === 4) cardsPerPlayer = 9;
    else if (playerIds.length === 5) cardsPerPlayer = 6;
    else if (playerIds.length === 6) cardsPerPlayer = 4;
    else if (playerIds.length === 7) cardsPerPlayer = 3;
    else if (playerIds.length === 8) cardsPerPlayer = 2;

    const deck = shuffle(createDeck());
    const playerHands: Record<string, Card[]> = {};
    for (const pid of playerIds) playerHands[pid] = deck.splice(0, cardsPerPlayer);

    const nextRound = {
      dealerId: newDealerId,
      phase: 'wadger',
      deck: deck,
      playerStates: playerIds.map((pid: string) => {
        const prev = playerStates.find((ps: any) => ps.uid === pid);
        return {
          uid: pid,
          hand: playerHands[pid],
          currentRoundPoints: 0,
          totalScore: prev.totalScore,
          capturedValueCards: [],
          earnedPoints: []
        };
      }),
      bidWinnerId: null,
      bidValue: 0,
      turnIndex: (playerIds.indexOf(newDealerId) + 1) % playerIds.length,
      consecutivePasses: 0,
      playedCards: []
    };
    await gameRef.update({ currentRound: nextRound });
  }
  return { success: true };
}
