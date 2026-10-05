// ignore_for_file: non_const_argument_for_const_parameter, non_constant_identifier_names

import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:functions/game/deck.dart';
import 'package:functions/game/logic.dart';
import 'package:functions/game/narrator.dart';
import 'package:functions/game/messaging_helper.dart';

Future<String> _getPlayerName(Firestore firestore, String? uid) async {
  if (uid == null) return 'Player';
  try {
    final userDoc = await firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();
    return (userData?['screenName'] ?? userData?['displayName'] ?? 'Player') as String;
  } catch (_) {
    return 'Player';
  }
}

final GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

void main(List<String> args) {
  FirebaseApp.initializeApp();

  runFunctions((firebase) {
    // 1. createGame
    firebase.https.onCall(
      name: 'createGame',
      options: CallableOptions(secrets: [GEMINI_API_KEY]),
      (request, response) async {
      final auth = request.auth;
      if (auth == null) {
        throw UnauthenticatedError('User must be logged in.');
      }

      final data = request.data as Map<String, dynamic>;
      final roomName = data['roomName'] as String?;
      final targetScore = (data['targetScore'] as num?)?.toInt() ?? 35;

      if (roomName == null || roomName.isEmpty) {
        throw InvalidArgumentError('Room name is required.');
      }

      final uid = auth.uid;
      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc();

      final gameData = {
        'hostId': uid,
        'name': roomName,
        'targetScore': targetScore,
        'playerIds': [uid],
        'invitedPlayerIds': [],
        'viewerIds': [],
        'viewerHeartbeats': {},
        'isOpen': false,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp,
        'updatedAt': FieldValue.serverTimestamp,
      };

      await gameRef.set(gameData);

      narrateWelcome(gameRef.id, roomName).catchError((e) => print('Narration error: $e'));

      return CallableResult({'gameId': gameRef.id});
    });

    // deleteGame
    firebase.https.onCall(name: 'deleteGame', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String?;
      if (gameId == null || gameId.isEmpty) {
        throw InvalidArgumentError('gameId is required.');
      }

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['hostId'] != auth.uid) {
        throw PermissionDeniedError('Only the game creator can delete this game.');
      }

      try {
        final messages = await gameRef.collection('messages').get();
        for (final doc in messages.docs) {
          await doc.ref.delete();
        }
      } catch (_) {}

      try {
        final reactions = await gameRef.collection('reactions').get();
        for (final doc in reactions.docs) {
          await doc.ref.delete();
        }
      } catch (_) {}

      await gameRef.delete();

      return CallableResult({'success': true});
    });

    // 2. invitePlayer
    firebase.https.onCall(name: 'invitePlayer', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final targetPlayerId = data['targetPlayerId'] as String;

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['hostId'] != auth.uid) {
        throw PermissionDeniedError('Only the host can invite players.');
      }

      await gameRef.update({
        'invitedPlayerIds': FieldValue.arrayUnion([targetPlayerId]),
        'updatedAt': FieldValue.serverTimestamp,
      });

      final hostName = await _getPlayerName(firestore, auth.uid);
      final roomName = (gameData['name'] ?? 'Pedro') as String;
      sendGameNotification(
        adminApp: firebase.adminApp,
        firestore: firestore,
        recipientUids: [targetPlayerId],
        title: 'Pedro: Game Invite',
        body: '$hostName invited you to join $roomName!',
        data: {'gameId': gameId, 'type': 'invite'},
      ).catchError((e) => print('FCM error: $e'));

      return CallableResult({'success': true});
    });

    // 3. uninvitePlayer
    firebase.https.onCall(name: 'uninvitePlayer', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final targetPlayerId = data['targetPlayerId'] as String;

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['hostId'] != auth.uid) {
        throw PermissionDeniedError('Only the host can uninvite players.');
      }

      await gameRef.update({
        'invitedPlayerIds': FieldValue.arrayRemove([targetPlayerId]),
        'updatedAt': FieldValue.serverTimestamp,
      });

      return CallableResult({'success': true});
    });

    // 4. joinGame
    firebase.https.onCall(name: 'joinGame', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['status'] != 'waiting') {
        throw FailedPreconditionError('Game has already started.');
      }

      final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
      if (playerIds.length >= 8) {
        throw FailedPreconditionError('Game room is full.');
      }

      if (playerIds.contains(auth.uid)) return CallableResult({'success': true});

      final invitedPlayerIds = List<String>.from((gameData['invitedPlayerIds'] ?? []) as Iterable);
      final isInvited = invitedPlayerIds.contains(auth.uid);

      if (!isInvited && gameData['hostId'] != auth.uid) {
        throw PermissionDeniedError('You are not invited to this game.');
      }

      await gameRef.update({
        'playerIds': FieldValue.arrayUnion([auth.uid]),
        'invitedPlayerIds': FieldValue.arrayRemove([auth.uid]),
        'updatedAt': FieldValue.serverTimestamp,
      });

      return CallableResult({'success': true});
    });

    // 5. startGame
    firebase.https.onCall(name: 'startGame', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['hostId'] != auth.uid) {
        throw PermissionDeniedError('Only the host can start.');
      }

      final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
      if (playerIds.length < 4) {
        throw FailedPreconditionError('Need at least 4 players.');
      }

      int cardsPerPlayer = 0;
      switch (playerIds.length) {
        case 4:
          cardsPerPlayer = 9;
          break;
        case 5:
          cardsPerPlayer = 6;
          break;
        case 6:
          cardsPerPlayer = 4;
          break;
        case 7:
          cardsPerPlayer = 3;
          break;
        case 8:
          cardsPerPlayer = 2;
          break;
      }

      final deck = shuffle(createDeck());
      final playerHands = <String, List<Card>>{};

      var deckPointer = 0;
      for (final pid in playerIds) {
        playerHands[pid] = deck.sublist(deckPointer, deckPointer + cardsPerPlayer);
        deckPointer += cardsPerPlayer;
      }
      final remainingDeck = deck.sublist(deckPointer);

      final sessionData = {
        'status': 'playing',
        'isOpen': true,
        'updatedAt': FieldValue.serverTimestamp,
        'currentRound': {
          'dealerId': auth.uid,
          'phase': 'wadger',
          'deck': remainingDeck.map((c) => c.toJson()).toList(),
          'playerStates':
              playerIds
                  .map(
                    (pid) => {
                      'uid': pid,
                      'hand': playerHands[pid]!.map((c) => c.toJson()).toList(),
                      'currentRoundPoints': 0,
                      'totalScore': 0,
                      'capturedValueCards': [],
                      'gameValue': 0,
                      'earnedPoints': [],
                      'cardsDiscarded': null,
                    },
                  )
                  .toList(),
          'bidWinnerId': null,
          'bidValue': 0,
          'turnIndex': (playerIds.indexOf(auth.uid) + 1) % playerIds.length,
          'consecutivePasses': 0,
          'passedPlayerIds': [],
          'playedCards': [],
          'completedLifts': [],
          'gamePointLeaderId': null,
          'gamePointLeaderValue': 0,
          'highTrumpPlayerId': null,
          'highTrumpPlayedCard': null,
          'lowTrumpPlayerId': null,
          'lowTrumpPlayedCard': null,
        },
      };

      await gameRef.update(sessionData);

      final roomName = (gameData['name'] ?? 'Pedro') as String;
      final firstTurnIndex = (playerIds.indexOf(auth.uid) + 1) % playerIds.length;
      final firstTurnPlayerId = playerIds[firstTurnIndex];

      sendGameNotification(
        adminApp: firebase.adminApp,
        firestore: firestore,
        recipientUids: [firstTurnPlayerId],
        title: 'Pedro: Game Started!',
        body: "It's your turn to bid in $roomName!",
        data: {'gameId': gameId, 'type': 'turn'},
      ).catchError((e) => print('FCM error: $e'));

      final otherPlayerIds = playerIds.where((pid) => pid != firstTurnPlayerId && pid != auth.uid).toList();
      if (otherPlayerIds.isNotEmpty) {
        sendGameNotification(
          adminApp: firebase.adminApp,
          firestore: firestore,
          recipientUids: otherPlayerIds,
          title: 'Pedro: Game Started!',
          body: '$roomName has started! Wager phase has begun.',
          data: {'gameId': gameId, 'type': 'turn'},
        ).catchError((e) => print('FCM error: $e'));
      }

      return CallableResult({'success': true});
    });

    // 6. submitBid
    firebase.https.onCall(
      name: 'submitBid',
      options: CallableOptions(secrets: [GEMINI_API_KEY]),
      (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final bid = (data['bid'] as num?)?.toInt();

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      final round = gameData['currentRound'] as Map<String, dynamic>;
      if (round['phase'] != 'wadger') throw FailedPreconditionError('Not in wadger phase.');

      final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
      final turnIndex = (round['turnIndex'] as num).toInt();

      if (auth.uid != playerIds[turnIndex]) throw FailedPreconditionError('Not your turn.');

      final playerStates = List<Map<String, dynamic>>.from(round['playerStates'] as Iterable);
      final playerState = playerStates.firstWhere((p) => p['uid'] == auth.uid);

      final currentBidValue = (round['bidValue'] as num?)?.toInt() ?? 0;
      if (bid == null && currentBidValue == 0) {
        throw InvalidArgumentError('The initial bid cannot be a pass.');
      }

      final passedPlayerIds = List<String>.from((round['passedPlayerIds'] ?? []) as Iterable);
      if (passedPlayerIds.contains(auth.uid)) {
        throw FailedPreconditionError('You have already passed this round.');
      }

      int newBidValue = currentBidValue;
      String? newBidWinnerId = round['bidWinnerId'] as String?;
      int newConsecutivePasses = (round['consecutivePasses'] as num?)?.toInt() ?? 0;

      if (bid == null) {
        passedPlayerIds.add(auth.uid);
        newConsecutivePasses++;
        playerState['earnedPoints'] = ['Pass'];
      } else {
        if (bid <= newBidValue) throw InvalidArgumentError('Bid must be higher.');
        newBidValue = bid;
        newBidWinnerId = auth.uid;
        newConsecutivePasses = 0;
        playerState['earnedPoints'] = ['Bid: $bid'];
      }

      final numPlayers = playerIds.length;
      String nextPhase = 'wadger';
      int nextTurnIndex = turnIndex;

      if (isBiddingComplete(
        totalPlayers: numPlayers,
        passedPlayerIds: passedPlayerIds,
        bidWinnerId: newBidWinnerId,
      )) {
        nextPhase = 'discarding';
        nextTurnIndex = playerIds.indexOf(newBidWinnerId!);
        for (final ps in playerStates) {
          ps['earnedPoints'] = [];
        }
      } else {
        nextTurnIndex = getNextBidderIndex(
          playerIds: playerIds,
          currentTurnIndex: turnIndex,
          passedPlayerIds: passedPlayerIds,
        );
      }

      await gameRef.update({
        'updatedAt': FieldValue.serverTimestamp,
        'currentRound.bidValue': newBidValue,
        'currentRound.bidWinnerId': newBidWinnerId,
        'currentRound.consecutivePasses': newConsecutivePasses,
        'currentRound.passedPlayerIds': passedPlayerIds,
        'currentRound.phase': nextPhase,
        'currentRound.turnIndex': nextTurnIndex,
        'currentRound.playerStates': playerStates,
      });

      final playerName = await _getPlayerName(firestore, auth.uid);

      final isBidWon = nextPhase == 'discarding' && newBidWinnerId != null;
      final prevBid = (round['bidValue'] as num).toInt();
      final isAllIn = bid == 20;
      final isJumpBid = bid != null && ((bid - prevBid) >= 4 || bid >= 16);

      if (isBidWon) {
        _getPlayerName(firestore, newBidWinnerId).then((winnerName) {
          narrateBidWon(
            gameId,
            winnerName,
            newBidValue,
          ).catchError((e) => print('Narration error: $e'));
        });
      } else if (isAllIn || isJumpBid) {
        narrateBid(
          gameId,
          playerName,
          bid,
          prevBid,
        ).catchError((e) => print('Narration error: $e'));
      }

      final roomName = (gameData['name'] ?? 'Pedro') as String;
      if (nextPhase == 'discarding' && newBidWinnerId != null) {
        sendGameNotification(
          adminApp: firebase.adminApp,
          firestore: firestore,
          recipientUids: [newBidWinnerId],
          title: 'Pedro: You Won the Bid!',
          body: 'Choose the trump suit in $roomName.',
          data: {'gameId': gameId, 'type': 'turn'},
        ).catchError((e) => print('FCM error: $e'));
      } else if (nextPhase == 'wadger') {
        final nextPlayerId = playerIds[nextTurnIndex];
        sendGameNotification(
          adminApp: firebase.adminApp,
          firestore: firestore,
          recipientUids: [nextPlayerId],
          title: 'Pedro: Your Turn to Bid',
          body: "It's your turn to place a bid in $roomName.",
          data: {'gameId': gameId, 'type': 'turn'},
        ).catchError((e) => print('FCM error: $e'));
      }

      return CallableResult({'success': true});
    });

    // 7. setTrumpSuit
    firebase.https.onCall(name: 'setTrumpSuit', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final suitName = data['suit'] as String;
      final suit = Suit.values.byName(suitName);

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      final round = gameData['currentRound'] as Map<String, dynamic>;
      if (round['phase'] != 'discarding') throw FailedPreconditionError('Not in discarding phase.');
      if (auth.uid != round['bidWinnerId']) throw PermissionDeniedError('Only bid winner.');

      final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
      final playerStates = List<Map<String, dynamic>>.from(round['playerStates'] as Iterable);
      final discardedCards = <Card>[];

      for (final ps in playerStates) {
        final hand =
            (ps['hand'] as Iterable).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();
        final keep = hand.where((c) => c.suit == suit).toList();
        final discard = hand.where((c) => c.suit != suit).toList();
        ps['cardsDiscarded'] = discard.length;
        ps['hand'] = keep.map((c) => c.toJson()).toList();
        discardedCards.addAll(discard);
      }

      final deck =
          (round['deck'] as Iterable).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();
      deck.addAll(shuffle(discardedCards));

      final bidWinnerIndex = playerIds.indexOf(auth.uid);
      for (var i = 0; i < playerIds.length; i++) {
        final pid = playerIds[(bidWinnerIndex + i) % playerIds.length];
        final ps = playerStates.firstWhere((p) => p['uid'] == pid);
        final hand =
            (ps['hand'] as Iterable).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();
        while (hand.length < 6 && deck.isNotEmpty) {
          hand.add(deck.removeAt(0));
        }
        ps['hand'] = hand.map((c) => c.toJson()).toList();
      }

      await gameRef.update({
        'updatedAt': FieldValue.serverTimestamp,
        'currentRound.trumpSuit': suit.name,
        'currentRound.phase': 'playing',
        'currentRound.playerStates': playerStates,
        'currentRound.deck': deck.map((c) => c.toJson()).toList(),
        'currentRound.turnIndex': bidWinnerIndex,
        'currentRound.currentLift': {'leadPlayerId': auth.uid, 'plays': {}, 'winnerId': null},
        'currentRound.completedLifts': [],
        'currentRound.gamePointLeaderId': null,
        'currentRound.gamePointLeaderValue': 0,
        'currentRound.highTrumpPlayerId': null,
        'currentRound.highTrumpPlayedCard': null,
        'currentRound.lowTrumpPlayerId': null,
        'currentRound.lowTrumpPlayedCard': null,
      });

      final roomName = (gameData['name'] ?? 'Pedro') as String;
      final suitNameUpper = suit.name.toUpperCase();
      postCommentary(
        gameId,
        'Trump is $suitNameUpper! All players returned their non-trump cards for replacement.',
      ).catchError((e) => print('Narration commentary error: $e'));

      final otherPlayerIds = playerIds.where((pid) => pid != auth.uid).toList();
      if (otherPlayerIds.isNotEmpty) {
        sendGameNotification(
          adminApp: firebase.adminApp,
          firestore: firestore,
          recipientUids: otherPlayerIds,
          title: 'Pedro: Trump is $suitNameUpper',
          body: 'Play has begun in $roomName!',
          data: {'gameId': gameId, 'type': 'turn'},
        ).catchError((e) => print('FCM error: $e'));
      }

      return CallableResult({'success': true});
    });

    // 8. playCard
    firebase.https.onCall(
      name: 'playCard',
      options: CallableOptions(secrets: [GEMINI_API_KEY]),
      (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final cardData = data['card'] as Map<String, dynamic>;
      final card = Card.fromJson(cardData);

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      final round = gameData['currentRound'] as Map<String, dynamic>;
      if (round['phase'] != 'playing') throw FailedPreconditionError('Not in playing phase.');

      final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
      final turnIndex = (round['turnIndex'] as num).toInt();
      if (auth.uid != playerIds[turnIndex]) {
        final currentLift = Map<String, dynamic>.from(round['currentLift'] as Map? ?? {});
        final plays = Map<String, dynamic>.from(currentLift['plays'] as Map? ?? {});
        final existingPlay = plays[auth.uid];
        if (existingPlay != null) {
          final playedCard = Card.fromJson(Map<String, dynamic>.from(existingPlay as Map));
          if (playedCard.suit == card.suit && playedCard.rank == card.rank) {
            return CallableResult({'status': 'already_played', 'success': true});
          }
        }
        final lastLift = Map<String, dynamic>.from(round['lastLift'] as Map? ?? {});
        final lastPlays = Map<String, dynamic>.from(lastLift['plays'] as Map? ?? {});
        final lastPlay = lastPlays[auth.uid];
        if (lastPlay != null) {
          final lastPlayedCard = Card.fromJson(Map<String, dynamic>.from(lastPlay as Map));
          if (lastPlayedCard.suit == card.suit && lastPlayedCard.rank == card.rank) {
            return CallableResult({'status': 'already_played', 'success': true});
          }
        }
        throw FailedPreconditionError('Not your turn.');
      }

      final playerStates = List<Map<String, dynamic>>.from(round['playerStates'] as Iterable);
      final playerState = playerStates.firstWhere((p) => p['uid'] == auth.uid);
      final hand =
          (playerState['hand'] as Iterable)
              .map((c) => Card.fromJson(c as Map<String, dynamic>))
              .toList();

      final cardIndex = hand.indexWhere((c) => c.suit == card.suit && c.rank == card.rank);
      if (cardIndex == -1) throw InvalidArgumentError('Card not in hand.');

      final currentLift = Map<String, dynamic>.from(round['currentLift'] as Map? ?? {});
      var plays = Map<String, dynamic>.from(currentLift['plays'] as Map? ?? {});
      final trumpSuit = Suit.values.byName(round['trumpSuit'] as String);

      // Check if previous lift completed and this play is the winner leading a new lift
      final isNewLiftAfterCompletion = currentLift['winnerId'] != null ||
          (plays.length == playerIds.length);

      if (isNewLiftAfterCompletion) {
        // Archive the completed lift to lastLift
        round['lastLift'] = Map<String, dynamic>.from(currentLift);
        // Reset currentLift for the new trick
        currentLift['leadPlayerId'] = auth.uid;
        currentLift['plays'] = <String, dynamic>{};
        currentLift['winnerId'] = null;
        plays = <String, dynamic>{};
      }

      final isLeader = plays.isEmpty;
      if (!isLeader) {
        final leadPlayerId = currentLift['leadPlayerId'] as String;
        final leadCard = Card.fromJson(plays[leadPlayerId] as Map<String, dynamic>);
        final leadSuit = leadCard.suit;
        if (card.suit != trumpSuit && card.suit != leadSuit) {
          final hasLeadSuit = hand.any((c) => c.suit == leadSuit);
          if (hasLeadSuit) {
            throw InvalidArgumentError('Must follow suit (${leadSuit.name}) or play Trump.');
          }
        }
      }

      hand.removeAt(cardIndex);
      playerState['hand'] = hand.map((c) => c.toJson()).toList();
      plays[auth.uid] = card.toJson();
      currentLift['plays'] = plays;
      currentLift['leadPlayerId'] = currentLift['leadPlayerId'] ?? auth.uid;

      final playedCards = List<dynamic>.from(round['playedCards'] ?? []);
      playedCards.add(card.toJson());

      // Helper to evaluate High/Low trumps for any card played by pId
      void processCardHighLow(Card c, String pId) {
        if (c.suit != trumpSuit) return;
        final highTrumpPlayedCardData = round['highTrumpPlayedCard'] as Map<String, dynamic>?;
        final highTrumpPlayedCard =
            highTrumpPlayedCardData != null ? Card.fromJson(highTrumpPlayedCardData) : null;
        final currentHighPlayerId = round['highTrumpPlayerId'] as String?;

        final lowTrumpPlayedCardData = round['lowTrumpPlayedCard'] as Map<String, dynamic>?;
        final lowTrumpPlayedCard =
            lowTrumpPlayedCardData != null ? Card.fromJson(lowTrumpPlayedCardData) : null;
        final currentLowPlayerId = round['lowTrumpPlayerId'] as String?;

        final hlResult = evaluateHighLowTrump(
          playedCard: c,
          trumpSuit: trumpSuit,
          playerId: pId,
          currentHighCard: highTrumpPlayedCard,
          currentHighPlayerId: currentHighPlayerId,
          currentLowCard: lowTrumpPlayedCard,
          currentLowPlayerId: currentLowPlayerId,
        );

        final pState = playerStates.firstWhere((p) => p['uid'] == pId);

        if (hlResult.highChanged) {
          if (hlResult.oldHighPlayerId != null && hlResult.oldHighPlayerId != pId) {
            final oldHolder = playerStates.firstWhere((p) => p['uid'] == hlResult.oldHighPlayerId);
            oldHolder['currentRoundPoints'] = ((oldHolder['currentRoundPoints'] as num?)?.toInt() ?? 0) - 1;
            final ep = List<String>.from(oldHolder['earnedPoints'] as Iterable? ?? []);
            ep.remove('High');
            oldHolder['earnedPoints'] = ep;
          }
          if (hlResult.oldHighPlayerId != pId) {
            pState['currentRoundPoints'] = ((pState['currentRoundPoints'] as num?)?.toInt() ?? 0) + 1;
            final ep = List<String>.from(pState['earnedPoints'] as Iterable? ?? []);
            if (!ep.contains('High')) ep.add('High');
            pState['earnedPoints'] = ep;
          }
          round['highTrumpPlayerId'] = hlResult.newHighPlayerId;
          round['highTrumpPlayedCard'] = hlResult.newHighCard!.toJson();
          if (hlResult.isHighSafe) {
            _getPlayerName(firestore, pId).then((name) {
              narratePointEvent(
                gameId,
                name,
                "High",
                false,
                cardRank: c.rank,
                isSafe: true,
              ).catchError((e) => print('Narration error: $e'));
            });
          }
        }

        if (hlResult.lowChanged) {
          if (hlResult.oldLowPlayerId != null && hlResult.oldLowPlayerId != pId) {
            final oldHolder = playerStates.firstWhere((p) => p['uid'] == hlResult.oldLowPlayerId);
            oldHolder['currentRoundPoints'] = ((oldHolder['currentRoundPoints'] as num?)?.toInt() ?? 0) - 1;
            final ep = List<String>.from(oldHolder['earnedPoints'] as Iterable? ?? []);
            ep.remove('Low');
            oldHolder['earnedPoints'] = ep;
          }
          if (hlResult.oldLowPlayerId != pId) {
            pState['currentRoundPoints'] = ((pState['currentRoundPoints'] as num?)?.toInt() ?? 0) + 1;
            final ep = List<String>.from(pState['earnedPoints'] as Iterable? ?? []);
            if (!ep.contains('Low')) ep.add('Low');
            pState['earnedPoints'] = ep;
          }
          round['lowTrumpPlayerId'] = hlResult.newLowPlayerId;
          round['lowTrumpPlayedCard'] = hlResult.newLowCard!.toJson();
          if (hlResult.isLowSafe) {
            _getPlayerName(firestore, pId).then((name) {
              narratePointEvent(
                gameId,
                name,
                "Low",
                false,
                cardRank: c.rank,
                isSafe: true,
              ).catchError((e) => print('Narration error: $e'));
            });
          }
        }
      }

      // Track High/Low Trumps dynamically for the leader's card
      processCardHighLow(card, auth.uid);

      // Leader-Triggered Final Lift Auto-Resolution:
      // If the leader is playing into the final lift (where every player has only 1 card left),
      // play all remaining players' solitary cards at once in exact anti-clockwise table order.
      final leaderIndex = playerIds.indexOf(auth.uid);
      final isFinalLift = isLeader && playerStates.every((p) => p['uid'] == auth.uid ? hand.isEmpty : (p['hand'] as Iterable).length == 1);
      if (isFinalLift) {
        for (int i = 1; i < playerIds.length; i++) {
          final pid = playerIds[(leaderIndex + i) % playerIds.length];
          final ps = playerStates.firstWhere((p) => p['uid'] == pid);
          final pHand = (ps['hand'] as Iterable)
              .map((c) => Card.fromJson(c as Map<String, dynamic>))
              .toList();
          if (pHand.isNotEmpty) {
            final pCard = pHand.removeAt(0);
            ps['hand'] = pHand.map((c) => c.toJson()).toList();
            plays[pid] = pCard.toJson();
            playedCards.add(pCard.toJson());
            processCardHighLow(pCard, pid);
          }
        }
      }

      int nextTurnIndex = (turnIndex + 1) % playerIds.length;

      if (plays.length == playerIds.length) {
        final leadPlayerId = currentLift['leadPlayerId'] as String;
        final leadSuit = Card.fromJson(plays[leadPlayerId] as Map<String, dynamic>).suit;

        final typedPlays = <String, Card>{};
        plays.forEach((k, v) => typedPlays[k] = Card.fromJson(v as Map<String, dynamic>));

        final winnerId = evaluateLiftWinner(
          plays: typedPlays,
          leadSuit: leadSuit,
          trumpSuit: trumpSuit,
        );
        currentLift['winnerId'] = winnerId;

        final winnerState = playerStates.firstWhere((p) => p['uid'] == winnerId);
        int liftPoints = 0;
        bool stoleJack = false;
        bool savedJack = false;
        bool wonNine = false;
        bool wonFive = false;

        final winnerName = await _getPlayerName(firestore, winnerId);

        for (final entry in typedPlays.entries) {
          final pId = entry.key;
          final playedCard = entry.value;

          if (playedCard.suit == trumpSuit) {
            if (playedCard.rank == Rank.five) {
              liftPoints += 5;
              wonFive = true;
              winnerState['earnedPoints'] = List<String>.from(
                winnerState['earnedPoints'] as Iterable? ?? [],
              )..add('5');
            }
            if (playedCard.rank == Rank.nine) {
              liftPoints += 9;
              wonNine = true;
              winnerState['earnedPoints'] = List<String>.from(
                winnerState['earnedPoints'] as Iterable? ?? [],
              )..add('9');
            }
            if (playedCard.rank == Rank.jack) {
              final isStolen = pId != winnerId;
              liftPoints += isStolen ? 3 : 1;
              if (isStolen) {
                stoleJack = true;
              } else {
                savedJack = true;
              }
              winnerState['earnedPoints'] = List<String>.from(
                winnerState['earnedPoints'] as Iterable? ?? [],
              )..add(isStolen ? 'Hang Jack' : 'Jack');
            }
          }

          final val = getCardGameValue(playedCard);
          if (val > 0) {
            final cvc = List<Map<String, dynamic>>.from(
              winnerState['capturedValueCards'] as Iterable? ?? [],
            );
            cvc.add(playedCard.toJson());
            winnerState['capturedValueCards'] = cvc;
            winnerState['gameValue'] = ((winnerState['gameValue'] as num?)?.toInt() ?? 0) + val;
          }
        }
        winnerState['currentRoundPoints'] = ((winnerState['currentRoundPoints'] as num?)?.toInt() ?? 0) + liftPoints;

        if (stoleJack || wonNine || wonFive || savedJack) {
          narrateLiftResolution(
            gameId: gameId,
            winnerName: winnerName,
            stoleJack: stoleJack,
            savedJack: savedJack,
            wonNine: wonNine,
            wonFive: wonFive,
            cardPoints: liftPoints,
          ).catchError((e) => print('Narration error: $e'));
        }

        // Evaluate live Game point leader
        final leaderRes = evaluateGamePointLeader(playerStates);
        round['gamePointLeaderId'] = leaderRes.leaderUid;
        round['gamePointLeaderValue'] = leaderRes.highestValue;

        // Append to completedLifts history
        final completedLifts = List<Map<String, dynamic>>.from(
          round['completedLifts'] as Iterable? ?? [],
        );
        completedLifts.add(Map<String, dynamic>.from(currentLift));
        round['completedLifts'] = completedLifts;

        final allHandsEmpty = playerStates.every((p) => (p['hand'] as Iterable).isEmpty);
        if (allHandsEmpty) {
          await gameRef.update({
            'updatedAt': FieldValue.serverTimestamp,
            'currentRound.playerStates': playerStates,
            'currentRound.currentLift': currentLift,
            'currentRound.completedLifts': completedLifts,
            'currentRound.gamePointLeaderId': leaderRes.leaderUid,
            'currentRound.gamePointLeaderValue': leaderRes.highestValue,
            'currentRound.turnIndex': playerIds.indexOf(winnerId!),
            'currentRound.highTrumpPlayerId': round['highTrumpPlayerId'],
            'currentRound.highTrumpPlayedCard': round['highTrumpPlayedCard'],
            'currentRound.lowTrumpPlayerId': round['lowTrumpPlayerId'],
            'currentRound.lowTrumpPlayedCard': round['lowTrumpPlayedCard'],
            'currentRound.playedCards': playedCards,
          });
          await Future.delayed(const Duration(seconds: 4));
          await finalizeRound(
            firebase.adminApp,
            firestore,
            gameRef,
            gameData,
            playerStates,
            round,
          );
          return CallableResult({'success': true});
        } else {
          nextTurnIndex = playerIds.indexOf(winnerId!);
        }
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp,
        'currentRound.playerStates': playerStates,
        'currentRound.currentLift': currentLift,
        'currentRound.completedLifts': round['completedLifts'] ?? [],
        'currentRound.gamePointLeaderId': round['gamePointLeaderId'],
        'currentRound.gamePointLeaderValue': round['gamePointLeaderValue'] ?? 0,
        'currentRound.turnIndex': nextTurnIndex,
        'currentRound.highTrumpPlayerId': round['highTrumpPlayerId'],
        'currentRound.highTrumpPlayedCard': round['highTrumpPlayedCard'],
        'currentRound.lowTrumpPlayerId': round['lowTrumpPlayerId'],
        'currentRound.lowTrumpPlayedCard': round['lowTrumpPlayedCard'],
        'currentRound.playedCards': playedCards,
      };
      if (round['lastLift'] != null) {
        updateData['currentRound.lastLift'] = round['lastLift'];
      }

      await gameRef.update(updateData);

      final roomName = (gameData['name'] ?? 'Pedro') as String;
      final nextPlayerId = playerIds[nextTurnIndex];
      if (nextPlayerId != auth.uid) {
        final isNextTrickLead = plays.length == playerIds.length;
        sendGameNotification(
          adminApp: firebase.adminApp,
          firestore: firestore,
          recipientUids: [nextPlayerId],
          title: isNextTrickLead ? 'Pedro: You Won the Trick!' : "Pedro: It's Your Turn",
          body: isNextTrickLead
              ? 'Lead the next card in $roomName.'
              : 'Play a card in $roomName.',
          data: {'gameId': gameId, 'type': 'turn'},
        ).catchError((e) => print('FCM error: $e'));
      }

      return CallableResult({'success': true});
    });

    // 9. call-player
    firebase.https.onCall(
      name: 'call-player',
      options: CallableOptions(secrets: [GEMINI_API_KEY]),
      (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String?;
      if (gameId == null || gameId.isEmpty) {
        throw InvalidArgumentError('Game ID is required.');
      }

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();
      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['status'] != 'playing') {
        throw FailedPreconditionError('Game is not currently active.');
      }

      final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
      if (!playerIds.contains(auth.uid)) {
        throw PermissionDeniedError('You are not a player in this game.');
      }

      final round = gameData['currentRound'] as Map<String, dynamic>?;
      if (round == null) throw FailedPreconditionError('No active round.');

      final turnIndex = (round['turnIndex'] as num?)?.toInt() ?? 0;
      if (turnIndex < 0 || turnIndex >= playerIds.length) {
        throw FailedPreconditionError('Invalid turn state.');
      }

      final targetPlayerId = playerIds[turnIndex];
      if (targetPlayerId == auth.uid) {
        throw FailedPreconditionError('You cannot call yourself.');
      }

      // Check cooldown (30 seconds)
      final lastCalledAt = round['lastCalledAt'];
      if (lastCalledAt != null) {
        DateTime? lastTime;
        if (lastCalledAt is Timestamp) {
          lastTime = lastCalledAt.toDate();
        } else if (lastCalledAt is DateTime) {
          lastTime = lastCalledAt;
        } else if (lastCalledAt is String) {
          lastTime = DateTime.tryParse(lastCalledAt);
        }
        if (lastTime != null) {
          final diff = DateTime.now().toUtc().difference(lastTime.toUtc());
          if (diff.inSeconds < 30) {
            throw FailedPreconditionError(
              'Please wait ${30 - diff.inSeconds} seconds before calling again.',
            );
          }
        }
      }

      await gameRef.update({
        'updatedAt': FieldValue.serverTimestamp,
        'currentRound.lastCalledAt': FieldValue.serverTimestamp,
      });

      final callerName = await _getPlayerName(firestore, auth.uid);
      final slowPlayerName = await _getPlayerName(firestore, targetPlayerId);

      // Trigger AI Narrator in Trini dialect to generate banter & post to chat
      final banter = await narrateCallPlayer(
        gameId: gameId,
        callerName: callerName,
        slowPlayerName: slowPlayerName,
      );

      // Send high-priority FCM notification to the slow player
      await sendGameNotification(
        adminApp: firebase.adminApp,
        firestore: firestore,
        recipientUids: [targetPlayerId],
        title: '⏰ Pedro: Play yuh card nah!',
        body: banter,
        data: {
          'gameId': gameId,
          'type': 'call',
        },
      );

      return CallableResult({'success': true, 'banter': banter});
    });

    // joinGameAsViewer
    firebase.https.onCall(name: 'joinGameAsViewer', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String?;
      if (gameId == null || gameId.isEmpty) {
        throw InvalidArgumentError('gameId is required.');
      }

      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['status'] != 'playing' && gameData['status'] != 'finished') {
        throw FailedPreconditionError('Game is not active.');
      }
      if (gameData['isOpen'] != true && gameData['status'] == 'playing') {
        throw PermissionDeniedError('Game is not open to spectators.');
      }

      final uid = auth.uid;
      final playerIds = List<String>.from((gameData['playerIds'] ?? []) as Iterable);
      if (playerIds.contains(uid)) {
        return CallableResult({'success': true, 'isPlayer': true});
      }

      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      await gameRef.update({
        'viewerIds': FieldValue.arrayUnion([uid]),
        'viewerHeartbeats.$uid': nowMillis,
      });

      return CallableResult({'success': true, 'isPlayer': false});
    });

    // heartbeatViewer
    firebase.https.onCall(name: 'heartbeatViewer', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String?;
      if (gameId == null || gameId.isEmpty) {
        throw InvalidArgumentError('gameId is required.');
      }

      final uid = auth.uid;
      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);

      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      await gameRef.update({
        'viewerHeartbeats.$uid': nowMillis,
      });

      return CallableResult({'success': true});
    });

    // leaveGameViewer
    firebase.https.onCall(name: 'leaveGameViewer', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String?;
      if (gameId == null || gameId.isEmpty) {
        throw InvalidArgumentError('gameId is required.');
      }

      final uid = auth.uid;
      final firestore = firebase.adminApp.firestore();
      final gameRef = firestore.collection('games').doc(gameId);

      await gameRef.update({
        'viewerIds': FieldValue.arrayRemove([uid]),
        'viewerHeartbeats.$uid': FieldValue.delete,
      });

      return CallableResult({'success': true});
    });
  });
}

Future<void> finalizeRound(
  FirebaseApp adminApp,
  Firestore firestore,
  DocumentReference gameRef,
  Map<String, dynamic> gameData,
  List<Map<String, dynamic>> playerStates,
  Map<String, dynamic> round,
) async {
  final gamePointWinner = evaluateGamePointWinner(playerStates);
  int bestValue = 0;
  for (final ps in playerStates) {
    final v = (ps['gameValue'] as num?)?.toInt() ?? 0;
    if (v > bestValue) bestValue = v;
  }

  String? gamePointWinnerName;
  if (gamePointWinner != null) {
    gamePointWinner['currentRoundPoints'] = ((gamePointWinner['currentRoundPoints'] as num?)?.toInt() ?? 0) + 1;
    gamePointWinner['earnedPoints'] = List<String>.from(
      gamePointWinner['earnedPoints'] as Iterable? ?? [],
    )..add('Game');
    gamePointWinnerName = await _getPlayerName(firestore, gamePointWinner['uid'] as String);
  }

  final bidWinnerId = round['bidWinnerId'] as String;
  final bidValue = (round['bidValue'] as num).toInt();

  for (final ps in playerStates) {
    final crp = (ps['currentRoundPoints'] as num?)?.toInt() ?? 0;
    if (ps['uid'] == bidWinnerId) {
      if (crp >= bidValue) {
        ps['totalScore'] = ((ps['totalScore'] as num?)?.toInt() ?? 0) + crp;
      } else {
        ps['totalScore'] = ((ps['totalScore'] as num?)?.toInt() ?? 0) - bidValue;
      }
    } else {
      ps['totalScore'] = ((ps['totalScore'] as num?)?.toInt() ?? 0) + crp;
    }
  }

  final roundNum = (gameData['roundNumber'] as num?)?.toInt() ?? 1;
  final bidWinnerState = playerStates.firstWhere((p) => p['uid'] == bidWinnerId);
  final bidSuccess = ((bidWinnerState['currentRoundPoints'] as num?)?.toInt() ?? 0) >= bidValue;
  final completedLifts = List<Map<String, dynamic>>.from(round['completedLifts'] as Iterable? ?? []);

  final lastRoundSummary = {
    'roundNumber': roundNum,
    'trumpSuit': round['trumpSuit'],
    'bidWinnerId': bidWinnerId,
    'bidValue': bidValue,
    'bidSuccess': bidSuccess,
    'highTrumpPlayerId': round['highTrumpPlayerId'],
    'highTrumpPlayedCard': round['highTrumpPlayedCard'],
    'lowTrumpPlayerId': round['lowTrumpPlayerId'],
    'lowTrumpPlayedCard': round['lowTrumpPlayedCard'],
    'gameWinnerId': gamePointWinner?['uid'],
    'gameWinningScore': bestValue > 0 ? bestValue : 0,
    'isGameTied': gamePointWinner == null && bestValue > 0,
    'playerSummaries': playerStates.map((ps) => {
      'uid': ps['uid'],
      'roundPoints': ps['currentRoundPoints'],
      'earnedPoints': ps['earnedPoints'],
      'totalScore': ps['totalScore'],
      'gameValue': ps['gameValue'] ?? 0,
      'capturedValueCards': ps['capturedValueCards'] ?? [],
      'wonLiftsCount': completedLifts.where((l) => l['winnerId'] == ps['uid']).length,
    }).toList(),
    'completedLifts': completedLifts,
  };

  final targetScore = (gameData['targetScore'] as num?)?.toInt() ?? 35;
  final winner = playerStates.firstWhere(
    (ps) => ((ps['totalScore'] as num?)?.toInt() ?? 0) >= targetScore,
    orElse: () => <String, dynamic>{},
  );

  final bidWinnerName = await _getPlayerName(firestore, bidWinnerId);
  final pointsWon = (bidWinnerState['currentRoundPoints'] as num?)?.toInt() ?? 0;
  String? matchWinnerName;
  if (winner.isNotEmpty) {
    matchWinnerName = await _getPlayerName(firestore, winner['uid'] as String);
  }

  narrateRoundEnd(
    gameId: gameRef.id,
    bidWinnerName: bidWinnerName,
    bidValue: bidValue,
    pointsWon: pointsWon,
    bidSuccess: bidSuccess,
    gamePointWinnerName: gamePointWinnerName,
    gamePointScore: bestValue > 0 ? bestValue : null,
    isGameTied: gamePointWinner == null && bestValue > 0,
    matchWinnerName: matchWinnerName,
  ).catchError((e) => print('Narration error: $e'));

  if (winner.isNotEmpty) {
    await gameRef.update({
      'updatedAt': FieldValue.serverTimestamp,
      'status': 'finished',
      'currentRound.playerStates': playerStates,
      'currentRound.phase': 'finished',
      'winnerId': winner['uid'],
      'lastRoundSummary': lastRoundSummary,
    });

    final winnerUid = winner['uid'] as String;
    final winnerName = matchWinnerName ?? await _getPlayerName(firestore, winnerUid);
    final winnerScore = winner['totalScore'];
    final roomName = (gameData['name'] ?? 'Pedro') as String;
    final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
    sendGameNotification(
      adminApp: adminApp,
      firestore: firestore,
      recipientUids: playerIds,
      title: 'Pedro: Game Over!',
      body: '$winnerName won $roomName with $winnerScore points!',
      data: {'gameId': gameRef.id, 'type': 'game_over'},
    ).catchError((e) => print('FCM error: $e'));
  } else {
    // Publish completed round summary state so clients display Round Summary modal
    await gameRef.update({
      'updatedAt': FieldValue.serverTimestamp,
      'currentRound.playerStates': playerStates,
      'currentRound.phase': 'finished',
      'lastRoundSummary': lastRoundSummary,
    });

    // Intermission window for players to review final trick and round outcome
    await Future.delayed(const Duration(seconds: 6));

    final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
    final oldDealerId = round['dealerId'] as String;
    final oldDealerIndex = playerIds.indexOf(oldDealerId);
    final newDealerId = playerIds[(oldDealerIndex + 1) % playerIds.length];

    int cardsPerPlayer = 0;
    switch (playerIds.length) {
      case 4:
        cardsPerPlayer = 9;
        break;
      case 5:
        cardsPerPlayer = 6;
        break;
      case 6:
        cardsPerPlayer = 4;
        break;
      case 7:
        cardsPerPlayer = 3;
        break;
      case 8:
        cardsPerPlayer = 2;
        break;
    }

    final deck = shuffle(createDeck());
    final playerHands = <String, List<Card>>{};
    var deckPointer = 0;
    for (final pid in playerIds) {
      playerHands[pid] = deck.sublist(deckPointer, deckPointer + cardsPerPlayer);
      deckPointer += cardsPerPlayer;
    }
    final remainingDeck = deck.sublist(deckPointer);

    final nextRound = {
      'dealerId': newDealerId,
      'phase': 'wadger',
      'deck': remainingDeck.map((c) => c.toJson()).toList(),
      'playerStates':
          playerIds.map((pid) {
            final prev = playerStates.firstWhere((p) => p['uid'] == pid);
            return {
              'uid': pid,
              'hand': playerHands[pid]!.map((c) => c.toJson()).toList(),
              'currentRoundPoints': 0,
              'totalScore': (prev['totalScore'] as num?)?.toInt() ?? 0,
              'capturedValueCards': [],
              'gameValue': 0,
              'earnedPoints': [],
              'cardsDiscarded': null,
            };
          }).toList(),
      'bidWinnerId': null,
      'bidValue': 0,
      'turnIndex': (playerIds.indexOf(newDealerId) + 1) % playerIds.length,
      'consecutivePasses': 0,
      'passedPlayerIds': [],
      'playedCards': [],
      'completedLifts': [],
      'gamePointLeaderId': null,
      'gamePointLeaderValue': 0,
      'highTrumpPlayerId': null,
      'highTrumpPlayedCard': null,
      'lowTrumpPlayerId': null,
      'lowTrumpPlayedCard': null,
    };
    await gameRef.update({
      'updatedAt': FieldValue.serverTimestamp,
      'roundNumber': roundNum + 1,
      'currentRound': nextRound,
      'lastRoundSummary': lastRoundSummary,
    });

    final firstBidderId = playerIds[(playerIds.indexOf(newDealerId) + 1) % playerIds.length];
    final roomName = (gameData['name'] ?? 'Pedro') as String;
    sendGameNotification(
      adminApp: adminApp,
      firestore: firestore,
      recipientUids: [firstBidderId],
      title: 'Pedro: New Round Started',
      body: "It's your turn to bid in $roomName!",
      data: {'gameId': gameRef.id, 'type': 'turn'},
    ).catchError((e) => print('FCM error: $e'));
  }
}
