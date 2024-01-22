import {HttpsError, onCall} from 'firebase-functions/v2/https';
import {auth} from 'firebase-functions/v1';
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";

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
    const owner = await getAuth().getUser(request.auth.uid);
    const gameDoc = await getFirestore().doc(`games/${gameId}`).get();
    const gamePlayers = Array.from(gameDoc.get('players'));
    console.log(`iaw: ${gamePlayers}`);

    if (owner.uid !== gameDoc.get('owner')) {
        throw new HttpsError("failed-precondition", "Only owner can call this");
    }
    if (owner.uid === playerId) {
        console.log("owner can't add themself");
        throw new HttpsError("failed-precondition", "Owner cannot add themself");
    }
    if (gamePlayers.indexOf(playerId) !== -1) {
        console.log('player already in the game');
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
