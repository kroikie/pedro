import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {auth} from 'firebase-functions/v1';
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {Deck} from "./deck";

initializeApp();

exports.startGame = onCall({cors: true}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }
    const gameData = request.data;
    const gameId = gameData['gameId'];

    const playersRef = getFirestore().collection(`games/${gameId}/players`);
    const playerDocs = await playersRef.get()
    for (const playerDoc of playerDocs.docs) {
        await playerDoc.ref.set({turn: Math.random()}, {});
    }
});

exports.createGame = onCall({cors: true}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }

    const timestamp = Date.now();

    const gameName = generateGameName();
    const gamesRef = getFirestore().collection('games');
    const gameRef = await gamesRef.add({
        name: gameName,
        creation: timestamp,
        target: 62,
        status: 'lobby',
        owner: request.auth.uid,
        players: [request.auth.uid],
    });

    try {
        const user = await getAuth().getUser(request.auth.uid);
        const userDoc = await getFirestore().doc(`users/${user.uid}`).get();
        const playerRef = gameRef.collection('players').doc(user.uid);
        await playerRef.set({
            'nick-name': userDoc.get('nick-name'),
            'photo-url': user.photoURL,
        });
        await userDoc.ref.collection('games').doc(gameRef.id).set({
            creation: timestamp,
            name: gameName,
        })
    } catch(e) {
        console.log(e);
    }

    return {
        gameId: gameRef.id,
    };
});

exports.addPlayer = onCall({cors: true}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }
    const gameId = request.data['gid'];
    const playerId = request.data['pid'];
    const playerDoc = await getFirestore().doc(`users/${playerId}`).get()
    const gameDoc = await getFirestore().doc(`games/${gameId}`).get();
    const gamePlayers = Array.from(gameDoc.get('players'));
    const user = await getAuth().getUser(request.auth.uid);

    if (user.uid !== gameDoc.get('owner')) {
        throw new HttpsError("failed-precondition", "Only owner can call this");
    }
    if (user.uid === playerId) {
        throw new HttpsError("failed-precondition", "Owner cannot add themself");
    }
    if (gamePlayers.indexOf(playerId) !== -1) {
        throw new HttpsError("failed-precondition", "Player is already in the game");
    }

    // add player to players array
    gamePlayers.push(playerId)
    await gameDoc.ref.update({
        players: gamePlayers
    });
    // add player to players collection in the game
    await gameDoc.ref.collection('players').doc(playerId).set({
        'nick-name': playerDoc.get('nick-name'),
        'photo-url': playerDoc.get('photo-url'),
        'status': 'invited',
    });
    // add game to player's games collection
    await playerDoc.ref.collection('games').doc(gameId).set({
        'name': gameDoc.get('name'),
        'creation': gameDoc.get('creation'),
    });
});

exports.removePlayer = onCall({cors: true}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }
    const gameId = request.data['gid'];
    const playerId = request.data['pid'];
    const playerDoc = await getFirestore().doc(`users/${playerId}`).get()
    const gameDoc = await getFirestore().doc(`games/${gameId}`).get();
    const gamePlayers = Array.from(gameDoc.get('players'));
    const user = await getAuth().getUser(request.auth.uid);

    if (user.uid !== gameDoc.get('owner')) {
        throw new HttpsError("failed-precondition", "Only owner can call this");
    }
    if (user.uid === playerId) {
        console.log("owner can't remove themself");
        throw new HttpsError("failed-precondition", "Owner cannot add themself");
    }
    if (gamePlayers.indexOf(playerId) === -1) {
        console.log('player must already be in the game');
        throw new HttpsError("failed-precondition", "Player must already be in the game");
    }

    // remove player from players array
    gamePlayers.splice(gamePlayers.indexOf(playerId), 1);
    await gameDoc.ref.update({
        players: gamePlayers
    });
    // remove player from players collection in the game
    await gameDoc.ref.collection('players').doc(playerId).delete();
    // remove game from player's games collection
    await playerDoc.ref.collection('games').doc(gameId).delete();
});

exports.rsvp = onCall({cors: true}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }
    const gameId = request.data['gid'];
    const choice = request.data['choice'];
    const gameDoc = await getFirestore().doc(`games/${gameId}`).get();
    const gamePlayers = Array.from(gameDoc.get('players'));
    const user = await getAuth().getUser(request.auth.uid);

    if (gameDoc.get('status') !== 'lobby') {
        throw new HttpsError("failed-precondition", "Game must be in the lobby status");
    }
    if (user.uid === gameDoc.get('owner')) {
        throw new HttpsError("failed-precondition", "Owner is not invited");
    }
    if (gamePlayers.indexOf(user.uid) === -1) {
        throw new HttpsError("failed-precondition", "Player must already be in the game");
    }
    // update player status in game
    await getFirestore().doc(`games/${gameId}/players/${user.uid}`).set({
        'status': choice,
    }, {merge: true});
});

exports.startGame = onCall({cors: true}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }
    const gameId = request.data['gid'];
    const gameDoc = await getFirestore().doc(`games/${gameId}`).get();
    const gameOwner = gameDoc.get('owner');
    const gamePlayers = await gameDoc.ref.collection('players').get();
    const user = await getAuth().getUser(request.auth.uid);


    if (gameDoc.get('status') !== 'lobby') {
        throw new HttpsError("failed-precondition", "Game must be in the lobby before starting");
    }
    // confirm owner is making the request
    if (user.uid !== gameDoc.get('owner')) {
        throw new HttpsError("failed-precondition", "Only owner can start game");
    }
    // confirm game has at least 5 accepted players
    let acceptedCount = 0;
    for (const gamePlayerDoc of gamePlayers.docs) {
        if (gamePlayerDoc.get('status') === 'accepted') {
            acceptedCount++;
        }
    }
    if (acceptedCount < 5 || acceptedCount > 7) {
        throw new HttpsError("failed-precondition",
            "Game must start with at least 6 - 8 accepting players");
    }

    // remove players without status of accepted and not owner
    for (const gamePlayerDoc of gamePlayers.docs) {
        if (gamePlayerDoc.id !== gameOwner && gamePlayerDoc.get('status') !== 'accepted') {
            await gamePlayerDoc.ref.delete();
            await getFirestore().doc(`users/${gamePlayerDoc.id}/games/${gameId}`).delete();
        }
    }

    // randomly assign order and initial score to players
    const acceptedPlayerIds = [];
    const acceptedPlayers = await gameDoc.ref.collection('players').get();
    let lowestTurn = 1;
    let firstPlayerId = '';
    const playerOrderMap = new Map<number, string>();
    for (const acceptedPlayerDoc of acceptedPlayers.docs) {
        // TODO: confirm that randomTurn is unique among accepted players
        const randomTurn = Math.random();
        playerOrderMap.set(randomTurn, acceptedPlayerDoc.id);
        await acceptedPlayerDoc.ref.set({
            turn: randomTurn,
            score: 0,
        }, {merge: true});
        acceptedPlayerIds.push(acceptedPlayerDoc.id);
        if (randomTurn < lowestTurn) {
            firstPlayerId = acceptedPlayerDoc.id
            lowestTurn = randomTurn;
        }
    }
    await gameDoc.ref.update({
        turn: firstPlayerId
    });

    // update game's players list
    await gameDoc.ref.update({
        players: acceptedPlayerIds,
    });

    // create round in game
    const roundRef = await gameDoc.ref.collection('rounds').add({
        stage: 'betting',
    });

    // add players to round
    for (const acceptedPlayerDoc of acceptedPlayers.docs) {
        await roundRef.collection('players').doc(acceptedPlayerDoc.id).set({
            'nick-name': acceptedPlayerDoc.get('nick-name'),
            'photo-url': acceptedPlayerDoc.get('photo-url'),
        });
    }

    // deal cards to players
    const deck = new Deck();
    const bettingCardCount = cardCountForBetting(acceptedCount + 1);

    const sortedPlayerTurns = Array.from(playerOrderMap.keys()).sort();
    for (const playerTurn of sortedPlayerTurns) {
        const playerId = playerOrderMap.get(playerTurn)
        const cards = deck.draw(bettingCardCount);
        await roundRef.collection('players').doc(playerId).update({
            hand: cards
        });
    }

    // set deck to round
    await roundRef.update({
        deck: deck.cards
    });

    // set game's turn to player with the smallest turn value and set status to play
    await gameDoc.ref.update({
        turn: firstPlayerId,
        status: 'play',
        'active-round': roundRef.id,
    });
});

exports.bet = onCall({cors: true}, (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }
});

exports.play = onCall({cors: true}, (request) => {
    if (!request.auth) {
        throw new HttpsError("failed-precondition", "User must be authenticated");
    }
});

exports.setupUser = auth.user().onCreate(async (user) => {
    await getFirestore().collection('users').doc(user.uid).set({
        // TODO: use AI to generate an avatar based on the nick name
        'photo-url': user.photoURL,
        'nick-name': generateNickName(),
        'team': [],
    });
});

exports.cleanUpUser = auth.user().onDelete(async (user) => {
    const userGames = await getFirestore().collection(`users/${user.uid}/games`).listDocuments();
    for (const userGame of userGames) {
        await userGame.delete();
    }
    await getFirestore().doc(`users/${user.uid}`).delete();
});

function generateNickName(): string {
    const prefixArr = ['hot', 'shy', 'tall', 'dark', 'heavy', 'quiet', 'loud', 'bright', 'yellow', 'blue'];
    const postfixArr = ['puppy', 'fox', 'lion', 'pit-bull', 'pot-hong', 'giraffe', 'fish', 'whale'];

    const prefix = prefixArr[Math.floor(Math.random() * prefixArr.length)];
    const postfix = postfixArr[Math.floor(Math.random() * postfixArr.length)];
    return `${prefix}-${postfix}`;
}

function generateGameName(): string {
    const prefixArr = ['bess', 'ultra', 'total', 'ultimate', 'brutal'];
    const infixArr = ['game', 'session', 'cyad', 'pedro', 'all-plenty', 'ting'];
    const postfixArr = ['clash', 'beat-down', 'fight', 'lime'];

    const prefix = prefixArr[Math.floor(Math.random() * prefixArr.length)];
    const infix = infixArr[Math.floor(Math.random() * infixArr.length)];
    const postfix = postfixArr[Math.floor(Math.random() * postfixArr.length)];
    return `${prefix}-${infix}-${postfix}`;
}

function cardCountForBetting(playerCount: number): number {
    switch (playerCount) {
        case 4:
            return 9;
        case 5:
            return 6;
        case 6:
            return 4;
        case 7:
            return 3;
        case 8:
            return 2;
        default:
            return 2;
    }
}
