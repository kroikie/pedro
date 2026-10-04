import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart' as pedro;
import 'package:pedro/data/models/chat_message.dart';
import 'package:pedro/data/models/game_reaction.dart';
import 'package:pedro/data/models/game_session.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/data/repositories/chat_repository.dart';
import 'package:pedro/data/repositories/game_repository.dart';
import 'package:pedro/data/repositories/player_repository.dart';
import 'package:pedro/data/repositories/reaction_repository.dart';
import 'package:pedro/ui/screens/game_board_screen.dart';

class CountingMockGameRepository implements GameRepository {
  CountingMockGameRepository({required this.sessionStream});

  final Stream<GameSession?> sessionStream;
  int watchGameSessionCallCount = 0;
  int callPlayerCallCount = 0;

  @override
  Stream<GameSession?> watchGameSession(String gameId) {
    watchGameSessionCallCount++;
    return sessionStream;
  }

  @override
  Future<void> playCard(String gameId, pedro.Card card) async {}

  @override
  Future<void> startGame(String gameId) async {}

  @override
  Future<void> submitBid(String gameId, int? bid) async {}

  @override
  Future<void> setTrumpSuit(String gameId, pedro.Suit suit) async {}

  @override
  Future<void> callPlayer(String gameId) async {
    callPlayerCallCount++;
  }

  @override
  Future<void> deleteGame(String gameId) async {}

  @override
  Future<void> joinGameAsViewer(String gameId) async {}

  @override
  Future<void> heartbeatViewer(String gameId) async {}

  @override
  Future<void> leaveGameViewer(String gameId) async {}
}

class CountingMockPlayerRepository implements PlayerRepository {
  final Map<String, int> getPlayerCallCounts = {};
  final Map<String, Player> players = {
    'p1': const Player(id: 'p1', screenName: 'Arthur'),
    'p2': const Player(id: 'p2', screenName: 'Gavy'),
    'p3': const Player(id: 'p3', screenName: 'Dona'),
    'p4': const Player(id: 'p4', screenName: 'Kimoy'),
  };

  @override
  Future<Player?> getPlayer(
    String uid, {
    Source source = Source.serverAndCache,
    Duration? timeout,
  }) async {
    getPlayerCallCounts[uid] = (getPlayerCallCounts[uid] ?? 0) + 1;
    return players[uid] ?? Player(id: uid, screenName: 'Player $uid');
  }

  @override
  Future<Player?> getPlayerFromCache(String uid) async => getPlayer(uid);

  @override
  Future<void> updatePlayer(Player player) async {}

  @override
  Future<void> addFcmToken(String uid, String token, String platform) async {}

  @override
  Future<void> removeFcmToken(String uid, String token) async {}

  @override
  Stream<Player?> watchPlayer(String uid) {
    return Stream.value(players[uid]);
  }

  @override
  Stream<List<Player>> watchAllPlayers() {
    return Stream.value(players.values.toList());
  }
}

class DummyReactionRepository implements ReactionRepository {
  @override
  Stream<List<GameReaction>> watchRecentReactions(String gameId) {
    return const Stream.empty();
  }

  @override
  Future<void> sendReaction({
    required String gameId,
    required String senderId,
    required String senderName,
    required String emoji,
  }) async {}
}

class DummyChatRepository implements ChatRepository {
  @override
  Stream<List<ChatMessage>> watchMessages(String gameId) {
    return const Stream.empty();
  }

  @override
  Future<void> sendMessage({
    required String gameId,
    required String senderId,
    required String senderName,
    required String text,
    bool isAi = false,
  }) async {}
}

GameSession createTestSession({
  DateTime? lastCalledAt,
  RoundPhase phase = RoundPhase.playing,
  int turnIndex = 1,
  Lift? currentLift,
}) {
  return GameSession(
    gameId: 'game_123',
    name: 'Test Pedro Game',
    hostId: 'p1',
    targetScore: 62,
    playerStates: const [
      PlayerGameState(
        uid: 'p1',
        hand: [
          pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace),
          pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.king),
        ],
        totalScore: 10,
        currentRoundPoints: 2,
      ),
      PlayerGameState(
        uid: 'p2',
        hand: [],
        totalScore: 12,
        currentRoundPoints: 0,
      ),
      PlayerGameState(
        uid: 'p3',
        hand: [],
        totalScore: 8,
        currentRoundPoints: 0,
      ),
      PlayerGameState(
        uid: 'p4',
        hand: [],
        totalScore: 14,
        currentRoundPoints: 0,
      ),
    ],
    currentRound: RoundState(
      dealerId: 'p1',
      phase: phase,
      turnIndex: turnIndex,
      bidWinnerId: 'p1',
      bidValue: 10,
      trumpSuit: pedro.Suit.hearts,
      currentLift: currentLift,
      lastCalledAt: lastCalledAt,
    ),
  );
}

void main() {
  group('GameBoardScreen Stream & Flicker Stability', () {
    testWidgets(
        'watchGameSession is memoized and only invoked once on initial mount, not on rebuilds',
        (tester) async {
      final sessionController = StreamController<GameSession?>.broadcast();
      addTearDown(sessionController.close);

      final gameRepo =
          CountingMockGameRepository(sessionStream: sessionController.stream);
      final playerRepo = CountingMockPlayerRepository();

      final initialSession = createTestSession();

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_123',
            currentUserId: 'p1',
            gameRepository: gameRepo,
            playerRepository: playerRepo,
            reactionRepository: DummyReactionRepository(),
            chatRepository: DummyChatRepository(),
          ),
        ),
      );

      expect(gameRepo.watchGameSessionCallCount, equals(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Emit session
      sessionController.add(initialSession);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Test Pedro Game'), findsOneWidget);
      expect(gameRepo.watchGameSessionCallCount, equals(1));

      // Rebuild parent widget tree multiple times (simulating layout/keyboard updates)
      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_123',
            currentUserId: 'p1',
            gameRepository: gameRepo,
            playerRepository: playerRepo,
            reactionRepository: DummyReactionRepository(),
            chatRepository: DummyChatRepository(),
          ),
        ),
      );
      await tester.pump();

      // Ensure stream was NOT resubscribed and no loading indicator flashed
      expect(gameRepo.watchGameSessionCallCount, equals(1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'Lift area retains cached player names and does not flicker to "..." on rebuild',
        (tester) async {
      final sessionController = StreamController<GameSession?>.broadcast();
      addTearDown(sessionController.close);

      final gameRepo =
          CountingMockGameRepository(sessionStream: sessionController.stream);
      final playerRepo = CountingMockPlayerRepository();

      final liftWithPlays = Lift(
        leadPlayerId: 'p2',
        winnerId: 'p3',
        plays: {
          'p2': const pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ten),
          'p3': const pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.queen),
        },
      );

      final session = createTestSession(currentLift: liftWithPlays);

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_123',
            currentUserId: 'p1',
            gameRepository: gameRepo,
            playerRepository: playerRepo,
            reactionRepository: DummyReactionRepository(),
            chatRepository: DummyChatRepository(),
          ),
        ),
      );

      sessionController.add(session);
      await tester.pumpAndSettle();

      // Lift winner and card players should show their screen names
      expect(find.text('Dona'), findsAtLeastNWidgets(1));
      expect(find.text('Gavy'), findsAtLeastNWidgets(1));

      // Trigger subsequent pump (e.g. frame update)
      await tester.pump();

      // Player names should still be visible without any "..." placeholder
      expect(find.text('...'), findsNothing);
      expect(find.text('Dona'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Call countdown updates locally in _WaitingAndCallArea without reloading game stream',
        (tester) async {
      final sessionController = StreamController<GameSession?>.broadcast();
      addTearDown(sessionController.close);

      final gameRepo =
          CountingMockGameRepository(sessionStream: sessionController.stream);
      final playerRepo = CountingMockPlayerRepository();

      // Active player is p2 (turnIndex = 1), last called 5 seconds ago
      final calledSession = createTestSession(
        turnIndex: 1,
        lastCalledAt: DateTime.now().toUtc().subtract(const Duration(seconds: 5)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_123',
            currentUserId: 'p1',
            gameRepository: gameRepo,
            playerRepository: playerRepo,
            reactionRepository: DummyReactionRepository(),
            chatRepository: DummyChatRepository(),
          ),
        ),
      );

      sessionController.add(calledSession);
      await tester.pumpAndSettle();

      // Button should show remaining cooldown around 25s
      expect(find.textContaining('Called ('), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Advance by 1 second for the periodic ticker
      await tester.pump(const Duration(seconds: 1));

      // Countdown ticked without re-fetching game stream or flashing progress indicator
      expect(gameRepo.watchGameSessionCallCount, equals(1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Called ('), findsOneWidget);
    });
  });
}
