import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:functions/game/deck.dart';
import 'package:functions/game/logic.dart';
import 'package:functions/game/narrator.dart';

void main(List<String> args) {
  runFunctions((firebase) {
    // 1. createGame
    firebase.https.onCall(name: 'createGame', (request, response) async {
      final auth = request.auth;
      if (auth == null) {
        throw UnauthenticatedError('User must be logged in.');
      }

      final data = request.data as Map<String, dynamic>;
      final roomName = data['roomName'] as String?;
      final targetScore = data['targetScore'] as int? ?? 35;

      if (roomName == null || roomName.isEmpty) {
        throw InvalidArgumentError('Room name is required.');
      }

      final uid = auth.uid;
      final firestore = FirebaseApp.initializeApp().firestore();
      final gameRef = firestore.collection('games').doc();

      final gameData = {
        'hostId': uid,
        'name': roomName,
        'targetScore': targetScore,
        'playerIds': [uid],
        'invitedPlayerIds': [],
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp,
      };

      await gameRef.set(gameData);

      narrateWelcome(gameRef.id, roomName).catchError((e) => print('Narration error: $e'));

      return CallableResult({'gameId': gameRef.id});
    });

    // 2. invitePlayer
    firebase.https.onCall(name: 'invitePlayer', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final targetPlayerId = data['targetPlayerId'] as String;

      final firestore = FirebaseApp.initializeApp().firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['hostId'] != auth.uid) {
        throw PermissionDeniedError('Only the host can invite players.');
      }

      await gameRef.update({
        'invitedPlayerIds': FieldValue.arrayUnion([targetPlayerId]),
      });

      return CallableResult({'success': true});
    });

    // 3. uninvitePlayer
    firebase.https.onCall(name: 'uninvitePlayer', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final targetPlayerId = data['targetPlayerId'] as String;

      final firestore = FirebaseApp.initializeApp().firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      if (gameData['hostId'] != auth.uid) {
        throw PermissionDeniedError('Only the host can uninvite players.');
      }

      await gameRef.update({
        'invitedPlayerIds': FieldValue.arrayRemove([targetPlayerId]),
      });

      return CallableResult({'success': true});
    });

    // 4. joinGame
    firebase.https.onCall(name: 'joinGame', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;

      final firestore = FirebaseApp.initializeApp().firestore();
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
      });

      return CallableResult({'success': true});
    });

    // 5. startGame
    firebase.https.onCall(name: 'startGame', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;

      final firestore = FirebaseApp.initializeApp().firestore();
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
        case 4: cardsPerPlayer = 9; break;
        case 5: cardsPerPlayer = 6; break;
        case 6: cardsPerPlayer = 4; break;
        case 7: cardsPerPlayer = 3; break;
        case 8: cardsPerPlayer = 2; break;
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
        'currentRound': {
          'dealerId': auth.uid,
          'phase': 'wadger',
          'deck': remainingDeck.map((c) => c.toJson()).toList(),
          'playerStates': playerIds.map((pid) => {
            'uid': pid,
            'hand': playerHands[pid]!.map((c) => c.toJson()).toList(),
            'currentRoundPoints': 0,
            'totalScore': 0,
            'capturedValueCards': [],
            'earnedPoints': []
          }).toList(),
          'bidWinnerId': null,
          'bidValue': 0,
          'turnIndex': (playerIds.indexOf(auth.uid) + 1) % playerIds.length,
          'consecutivePasses': 0,
          'playedCards': []
        }
      };

      await gameRef.update(sessionData);
      return CallableResult({'success': true});
    });

    // 6. submitBid
    firebase.https.onCall(name: 'submitBid', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final bid = data['bid'] as int?;

      final firestore = FirebaseApp.initializeApp().firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      final round = gameData['currentRound'] as Map<String, dynamic>;
      if (round['phase'] != 'wadger') throw FailedPreconditionError('Not in wadger phase.');

      final playerIds = List<String>.from(round['playerIds'] as Iterable);
      final turnIndex = round['turnIndex'] as int;

      if (auth.uid != playerIds[turnIndex]) throw FailedPreconditionError('Not your turn.');

      final playerStates = List<Map<String, dynamic>>.from(round['playerStates'] as Iterable);
      final playerState = playerStates.firstWhere((p) => p['uid'] == auth.uid);

      int newBidValue = round['bidValue'] as int;
      String? newBidWinnerId = round['bidWinnerId'] as String?;
      int newConsecutivePasses = round['consecutivePasses'] as int? ?? 0;

      if (bid == null) {
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
      int nextTurnIndex = (turnIndex + 1) % numPlayers;

      if (newConsecutivePasses == numPlayers - 1 && newBidWinnerId != null) {
        nextPhase = 'discarding';
        nextTurnIndex = playerIds.indexOf(newBidWinnerId);
        for (final ps in playerStates) ps['earnedPoints'] = [];
      } else if (newConsecutivePasses == numPlayers) {
        newBidValue = 1;
        newBidWinnerId = round['dealerId'] as String;
        nextPhase = 'discarding';
        nextTurnIndex = playerIds.indexOf(newBidWinnerId);
        for (final ps in playerStates) ps['earnedPoints'] = [];
      }

      await gameRef.update({
        'currentRound.bidValue': newBidValue,
        'currentRound.bidWinnerId': newBidWinnerId,
        'currentRound.consecutivePasses': newConsecutivePasses,
        'currentRound.phase': nextPhase,
        'currentRound.turnIndex': nextTurnIndex,
        'currentRound.playerStates': playerStates
      });

      final userDoc = await firestore.collection('users').doc(auth.uid).get();
      final userData = userDoc.data();
      final playerName = (userData?['screenName'] ?? userData?['displayName'] ?? "A player") as String;

      final shouldNarrate = bid != null || (newConsecutivePasses == 1 || nextPhase != 'wadger');
      if (shouldNarrate) {
        narrateBid(gameId, playerName, bid, round['bidValue'] as int)
          .catchError((e) => print('Narration error: $e'));
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

      final firestore = FirebaseApp.initializeApp().firestore();
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
        final hand = (ps['hand'] as Iterable).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();
        final keep = hand.where((c) => c.suit == suit).toList();
        final discard = hand.where((c) => c.suit != suit).toList();
        ps['hand'] = keep.map((c) => c.toJson()).toList();
        discardedCards.addAll(discard);
      }

      final deck = (round['deck'] as Iterable).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();
      deck.addAll(shuffle(discardedCards));

      final bidWinnerIndex = playerIds.indexOf(auth.uid);
      for (var i = 0; i < playerIds.length; i++) {
        final pid = playerIds[(bidWinnerIndex + i) % playerIds.length];
        final ps = playerStates.firstWhere((p) => p['uid'] == pid);
        final hand = (ps['hand'] as Iterable).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();
        while (hand.length < 6 && deck.isNotEmpty) {
          hand.add(deck.removeAt(0));
        }
        ps['hand'] = hand.map((c) => c.toJson()).toList();
      }

      await gameRef.update({
        'currentRound.trumpSuit': suit.name,
        'currentRound.phase': 'playing',
        'currentRound.playerStates': playerStates,
        'currentRound.deck': deck.map((c) => c.toJson()).toList(),
        'currentRound.turnIndex': bidWinnerIndex,
        'currentRound.currentLift': { 'leadPlayerId': auth.uid, 'plays': {}, 'winnerId': null },
        'currentRound.highTrumpPlayerId': null,
        'currentRound.lowTrumpPlayerId': null
      });

      return CallableResult({'success': true});
    });

    // 8. playCard
    firebase.https.onCall(name: 'playCard', (request, response) async {
      final auth = request.auth;
      if (auth == null) throw UnauthenticatedError('User must be logged in.');

      final data = request.data as Map<String, dynamic>;
      final gameId = data['gameId'] as String;
      final cardData = data['card'] as Map<String, dynamic>;
      final card = Card.fromJson(cardData);

      final firestore = FirebaseApp.initializeApp().firestore();
      final gameRef = firestore.collection('games').doc(gameId);
      final gameDoc = await gameRef.get();

      if (!gameDoc.exists) throw NotFoundError('Game not found.');

      final gameData = gameDoc.data()!;
      final round = gameData['currentRound'] as Map<String, dynamic>;
      if (round['phase'] != 'playing') throw FailedPreconditionError('Not in playing phase.');

      final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
      final turnIndex = round['turnIndex'] as int;
      if (auth.uid != playerIds[turnIndex]) throw FailedPreconditionError('Not your turn.');

      final playerStates = List<Map<String, dynamic>>.from(round['playerStates'] as Iterable);
      final playerState = playerStates.firstWhere((p) => p['uid'] == auth.uid);
      final hand = (playerState['hand'] as Iterable).map((c) => Card.fromJson(c as Map<String, dynamic>)).toList();

      final cardIndex = hand.indexWhere((c) => c.suit == card.suit && c.rank == card.rank);
      if (cardIndex == -1) throw InvalidArgumentError('Card not in hand.');

      final currentLift = round['currentLift'] as Map<String, dynamic>;
      final plays = Map<String, dynamic>.from(currentLift['plays'] as Map);
      final trumpSuit = Suit.values.byName(round['trumpSuit'] as String);

      final isLeader = plays.isEmpty;
      if (!isLeader) {
        final leadPlayerId = currentLift['leadPlayerId'] as String;
        final leadCard = Card.fromJson(plays[leadPlayerId] as Map<String, dynamic>);
        final leadSuit = leadCard.suit;
        if (card.suit != trumpSuit && card.suit != leadSuit) {
          final hasLeadSuit = hand.any((c) => c.suit == leadSuit);
          if (hasLeadSuit) throw InvalidArgumentError('Must follow suit (${leadSuit.name}) or play Trump.');
        }
      }

      hand.removeAt(cardIndex);
      playerState['hand'] = hand.map((c) => c.toJson()).toList();
      plays[auth.uid] = card.toJson();
      currentLift['plays'] = plays;

      final playedCards = List<dynamic>.from(round['playedCards'] ?? []);
      playedCards.add(card.toJson());

      // Track High/Low Trumps
      if (card.suit == trumpSuit) {
        // High Trump logic
        final highTrumpPlayedCardData = round['highTrumpPlayedCard'] as Map<String, dynamic>?;
        final highTrumpPlayedCard = highTrumpPlayedCardData != null ? Card.fromJson(highTrumpPlayedCardData) : null;
        
        if (highTrumpPlayedCard == null || rankValues[card.rank]! > rankValues[highTrumpPlayedCard.rank]!) {
          final oldHolderId = round['highTrumpPlayerId'] as String?;
          if (oldHolderId != null) {
            final oldHolder = playerStates.firstWhere((p) => p['uid'] == oldHolderId);
            oldHolder['currentRoundPoints'] = (oldHolder['currentRoundPoints'] as int) - 1;
            final ep = List<String>.from(oldHolder['earnedPoints'] as Iterable? ?? []);
            ep.remove('High');
            oldHolder['earnedPoints'] = ep;
          }
          playerState['currentRoundPoints'] = (playerState['currentRoundPoints'] as int) + 1;
          playerState['earnedPoints'] = List<String>.from(playerState['earnedPoints'] as Iterable? ?? [])..add('High');
          round['highTrumpPlayerId'] = auth.uid;
          round['highTrumpPlayedCard'] = card.toJson();
          narratePointEvent(gameId, "A player", "High", false).catchError((e) => print('Narration error: $e'));
        }

        // Low Trump logic
        final lowTrumpPlayedCardData = round['lowTrumpPlayedCard'] as Map<String, dynamic>?;
        final lowTrumpPlayedCard = lowTrumpPlayedCardData != null ? Card.fromJson(lowTrumpPlayedCardData) : null;

        if (lowTrumpPlayedCard == null || rankValues[card.rank]! < rankValues[lowTrumpPlayedCard.rank]!) {
          final oldHolderId = round['lowTrumpPlayerId'] as String?;
          if (oldHolderId != null) {
            final oldHolder = playerStates.firstWhere((p) => p['uid'] == oldHolderId);
            oldHolder['currentRoundPoints'] = (oldHolder['currentRoundPoints'] as int) - 1;
            final ep = List<String>.from(oldHolder['earnedPoints'] as Iterable? ?? []);
            ep.remove('Low');
            oldHolder['earnedPoints'] = ep;
          }
          playerState['currentRoundPoints'] = (playerState['currentRoundPoints'] as int) + 1;
          playerState['earnedPoints'] = List<String>.from(playerState['earnedPoints'] as Iterable? ?? [])..add('Low');
          round['lowTrumpPlayerId'] = auth.uid;
          round['lowTrumpPlayedCard'] = card.toJson();
          narratePointEvent(gameId, "A player", "Low", false).catchError((e) => print('Narration error: $e'));
        }
      }

      int nextTurnIndex = (turnIndex + 1) % playerIds.length;

      if (plays.length == playerIds.length) {
        final leadPlayerId = currentLift['leadPlayerId'] as String;
        final leadSuit = Card.fromJson(plays[leadPlayerId] as Map<String, dynamic>).suit;
        
        final typedPlays = <String, Card>{};
        plays.forEach((k, v) => typedPlays[k] = Card.fromJson(v as Map<String, dynamic>));

        final winnerId = evaluateLiftWinner(plays: typedPlays, leadSuit: leadSuit, trumpSuit: trumpSuit);
        currentLift['winnerId'] = winnerId;

        final winnerState = playerStates.firstWhere((p) => p['uid'] == winnerId);
        int liftPoints = 0;

        for (final entry in typedPlays.entries) {
          final pId = entry.key;
          final playedCard = entry.value;

          if (playedCard.suit == trumpSuit) {
            if (playedCard.rank == Rank.five) {
              liftPoints += 5;
              winnerState['earnedPoints'] = List<String>.from(winnerState['earnedPoints'] as Iterable? ?? [])..add('5');
              narratePointEvent(gameId, "A player", "5", false).catchError((e) => print('Narration error: $e'));
            }
            if (playedCard.rank == Rank.nine) {
              liftPoints += 9;
              winnerState['earnedPoints'] = List<String>.from(winnerState['earnedPoints'] as Iterable? ?? [])..add('9');
              narratePointEvent(gameId, "A player", "9", false).catchError((e) => print('Narration error: $e'));
            }
            if (playedCard.rank == Rank.jack) {
              final isStolen = pId != winnerId;
              liftPoints += isStolen ? 3 : 1;
              winnerState['earnedPoints'] = List<String>.from(winnerState['earnedPoints'] as Iterable? ?? [])..add(isStolen ? 'Hang Jack' : 'Jack');
              narratePointEvent(gameId, "A player", "Jack", isStolen).catchError((e) => print('Narration error: $e'));
            }
          }

          final valueMap = { Rank.ten: 10, Rank.jack: 1, Rank.queen: 2, Rank.king: 3, Rank.ace: 4 };
          if (valueMap.containsKey(playedCard.rank)) {
            final cvc = List<Map<String, dynamic>>.from(winnerState['capturedValueCards'] as Iterable? ?? []);
            cvc.add(playedCard.toJson());
            winnerState['capturedValueCards'] = cvc;
          }
        }
        winnerState['currentRoundPoints'] = (winnerState['currentRoundPoints'] as int) + liftPoints;

        final allHandsEmpty = playerStates.every((p) => (p['hand'] as Iterable).isEmpty);
        if (allHandsEmpty) {
          await finalizeRound(gameRef, gameData, playerStates, round);
          return CallableResult({'success': true});
        } else {
          currentLift['leadPlayerId'] = winnerId;
          currentLift['plays'] = {};
          currentLift['winnerId'] = null;
          nextTurnIndex = playerIds.indexOf(winnerId!);
        }
      }

      await gameRef.update({
        'currentRound.playerStates': playerStates,
        'currentRound.currentLift': currentLift,
        'currentRound.turnIndex': nextTurnIndex,
        'currentRound.highTrumpPlayerId': round['highTrumpPlayerId'],
        'currentRound.highTrumpPlayedCard': round['highTrumpPlayedCard'],
        'currentRound.lowTrumpPlayerId': round['lowTrumpPlayerId'],
        'currentRound.lowTrumpPlayedCard': round['lowTrumpPlayedCard'],
        'currentRound.playedCards': playedCards
      });

      return CallableResult({'success': true});
    });
  });
}

Future<void> finalizeRound(DocumentReference gameRef, Map<String, dynamic> gameData, List<Map<String, dynamic>> playerStates, Map<String, dynamic> round) async {
  final valueMap = { 'ten': 10, 'jack': 1, 'queen': 2, 'king': 3, 'ace': 4 };
  int bestValue = -1;
  Map<String, dynamic>? gamePointWinner;

  for (final ps in playerStates) {
    int totalValue = 0;
    final cvc = List<dynamic>.from(ps['capturedValueCards'] as Iterable? ?? []);
    for (final c in cvc) {
      final rank = c['rank'] as String;
      if (valueMap.containsKey(rank)) totalValue += valueMap[rank]!;
    }
    if (totalValue > bestValue) {
      bestValue = totalValue;
      gamePointWinner = ps;
    } else if (totalValue == bestValue) {
      gamePointWinner = null;
    }
  }

  if (gamePointWinner != null) {
    gamePointWinner['currentRoundPoints'] = (gamePointWinner['currentRoundPoints'] as int) + 1;
    gamePointWinner['earnedPoints'] = List<String>.from(gamePointWinner['earnedPoints'] as Iterable? ?? [])..add('Game');
  }

  final bidWinnerId = round['bidWinnerId'] as String;
  final bidValue = round['bidValue'] as int;

  for (final ps in playerStates) {
    final crp = ps['currentRoundPoints'] as int;
    if (ps['uid'] == bidWinnerId) {
      if (crp >= bidValue) {
        ps['totalScore'] = (ps['totalScore'] as int) + crp;
      } else {
        ps['totalScore'] = (ps['totalScore'] as int) - bidValue;
      }
    } else {
      ps['totalScore'] = (ps['totalScore'] as int) + crp;
    }
  }

  final targetScore = gameData['targetScore'] as int;
  final winner = playerStates.firstWhere((ps) => (ps['totalScore'] as int) >= targetScore, orElse: () => <String, dynamic>{});

  if (winner.isNotEmpty) {
    await gameRef.update({
      'status': 'finished',
      'currentRound.playerStates': playerStates,
      'currentRound.phase': 'finished',
      'winnerId': winner['uid']
    });
  } else {
    final playerIds = List<String>.from(gameData['playerIds'] as Iterable);
    final oldDealerId = round['dealerId'] as String;
    final oldDealerIndex = playerIds.indexOf(oldDealerId);
    final newDealerId = playerIds[(oldDealerIndex + 1) % playerIds.length];

    int cardsPerPlayer = 0;
    switch (playerIds.length) {
      case 4: cardsPerPlayer = 9; break;
      case 5: cardsPerPlayer = 6; break;
      case 6: cardsPerPlayer = 4; break;
      case 7: cardsPerPlayer = 3; break;
      case 8: cardsPerPlayer = 2; break;
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
      'playerStates': playerIds.map((pid) {
        final prev = playerStates.firstWhere((p) => p['uid'] == pid);
        return {
          'uid': pid,
          'hand': playerHands[pid]!.map((c) => c.toJson()).toList(),
          'currentRoundPoints': 0,
          'totalScore': prev['totalScore'],
          'capturedValueCards': [],
          'earnedPoints': []
        };
      }).toList(),
      'bidWinnerId': null,
      'bidValue': 0,
      'turnIndex': (playerIds.indexOf(newDealerId) + 1) % playerIds.length,
      'consecutivePasses': 0,
      'playedCards': []
    };
    await gameRef.update({ 'currentRound': nextRound });
  }
}
