import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class MockGameRepo implements GameRepository {
  GameSession? currentSession;

  @override
  Stream<GameSession?> watchGameSession(String gameId) =>
      Stream.value(currentSession);

  @override
  Future<void> playCard(String gameId, pedro.Card card) async {}

  @override
  Future<void> startGame(String gameId) async {}

  @override
  Future<void> submitBid(String gameId, int? bid) async {}

  @override
  Future<void> setTrumpSuit(String gameId, pedro.Suit suit) async {}

  @override
  Future<void> callPlayer(String gameId) async {}

  @override
  Future<void> deleteGame(String gameId) async {}

  @override
  Future<void> joinGameAsViewer(String gameId) async {}

  @override
  Future<void> heartbeatViewer(String gameId) async {}

  @override
  Future<void> leaveGameViewer(String gameId) async {}
}

class MockPlayerRepo implements PlayerRepository {
  final Map<String, Player> players = {
    'p1': const Player(id: 'p1', screenName: 'Alice'),
    'p2': const Player(id: 'p2', screenName: 'Bob'),
    'p3': const Player(id: 'p3', screenName: 'Chantal'),
    'p4': const Player(id: 'p4', screenName: 'Dave'),
  };

  @override
  Future<Player?> getPlayer(
    String uid, {
    Source source = Source.serverAndCache,
    Duration? timeout,
  }) async {
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
  Stream<Player?> watchPlayer(String uid) =>
      Stream.value(players[uid] ?? Player(id: uid, screenName: 'Player $uid'));

  @override
  Stream<List<Player>> watchAllPlayers() =>
      Stream.value(players.values.toList());
}

class MockReactionRepo implements ReactionRepository {
  @override
  Stream<List<GameReaction>> watchRecentReactions(String gameId) =>
      const Stream.empty();

  @override
  Future<void> sendReaction({
    required String gameId,
    required String senderId,
    required String senderName,
    required String emoji,
  }) async {}
}

class MockChatRepo implements ChatRepository {
  @override
  Stream<List<ChatMessage>> watchMessages(String gameId) =>
      const Stream.empty();

  @override
  Future<void> sendMessage({
    required String gameId,
    required String senderId,
    required String senderName,
    required String text,
    bool isAi = false,
  }) async {}

  @override
  Future<void> postNarratorCommentary({
    required String gameId,
    required String commentary,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGameRepo mockGameRepo;
  late MockPlayerRepo mockPlayerRepo;
  late MockChatRepo mockChatRepo;
  late MockReactionRepo mockReactionRepo;

  setUp(() {
    mockGameRepo = MockGameRepo();
    mockPlayerRepo = MockPlayerRepo();
    mockChatRepo = MockChatRepo();
    mockReactionRepo = MockReactionRepo();
  });

  Widget buildTestScreen(GameSession session) {
    mockGameRepo.currentSession = session;
    return MaterialApp(
      home: GameBoardScreen(
        gameId: 'game1',
        currentUserId: 'p1',
        gameRepository: mockGameRepo,
        playerRepository: mockPlayerRepo,
        chatRepository: mockChatRepo,
        reactionRepository: mockReactionRepo,
      ),
    );
  }

  group('Board Visibility and Compact Cards Widget Tests', () {
    testWidgets(
        'Player cards render compact dot pips instead of bloated text chips',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final session = GameSession(
        gameId: 'game1',
        targetScore: 35,
        playerStates: [
          const PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace)],
            totalScore: 10,
          ),
          const PlayerGameState(
            uid: 'p2',
            hand: [],
            totalScore: 8,
            currentRoundPoints: 10,
            earnedPoints: ['High', 'Hang Jack', '5', '9', 'Low'],
            cardsDiscarded: 2,
          ),
          const PlayerGameState(uid: 'p3', hand: []),
          const PlayerGameState(uid: 'p4', hand: []),
        ],
        currentRound: const RoundState(
          dealerId: 'p4',
          phase: RoundPhase.playing,
          trumpSuit: pedro.Suit.hearts,
          turnIndex: 0,
          bidValue: 10,
          bidWinnerId: 'p2',
        ),
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      // p2 is displayed on the table with Bob's name
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Pts: 10 / 10'), findsOneWidget);

      // Verify that full point text strings ('Hang Jack', 'High') do NOT appear directly as chips on table seat
      expect(find.text('Hang Jack'), findsNothing);

      // Verify Replaced badge is displayed
      expect(find.text('Replaced: 2'), findsOneWidget);
    });

    testWidgets(
        'Tapping other player card opens PlayerRoundDetailsModal with rich details',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final session = GameSession(
        gameId: 'game1',
        targetScore: 35,
        playerStates: [
          const PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace)],
            totalScore: 10,
          ),
          const PlayerGameState(
            uid: 'p2',
            hand: [],
            totalScore: 8,
            currentRoundPoints: 10,
            earnedPoints: ['High', 'Hang Jack', '5'],
            cardsDiscarded: 2,
          ),
          const PlayerGameState(uid: 'p3', hand: []),
          const PlayerGameState(uid: 'p4', hand: []),
        ],
        currentRound: const RoundState(
          dealerId: 'p4',
          phase: RoundPhase.playing,
          trumpSuit: pedro.Suit.hearts,
          turnIndex: 0,
          bidValue: 10,
          bidWinnerId: 'p2',
        ),
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      // Tap Bob's player card
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opens
      expect(find.text('Hang Jack'), findsOneWidget);
      expect(find.text('5 of Trump'), findsOneWidget);
      expect(find.text('Bob discarded and replaced 2 cards'), findsOneWidget);
      expect(find.text('Won Lifts'), findsOneWidget);
      expect(find.text('Game Value'), findsOneWidget);
    });

    testWidgets(
        'Tapping center trick area opens enlarged Current Trick modal',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final session = GameSession(
        gameId: 'game1',
        targetScore: 35,
        playerStates: [
          const PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace)],
          ),
          const PlayerGameState(uid: 'p2', hand: []),
          const PlayerGameState(uid: 'p3', hand: []),
          const PlayerGameState(uid: 'p4', hand: []),
        ],
        currentRound: const RoundState(
          dealerId: 'p4',
          phase: RoundPhase.playing,
          trumpSuit: pedro.Suit.hearts,
          turnIndex: 0,
          bidValue: 10,
          bidWinnerId: 'p2',
          currentLift: Lift(
            leadPlayerId: 'p2',
            plays: {
              'p2': pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.jack),
            },
          ),
        ),
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      // Find center trick area with zoom in icon
      final zoomIcon = find.byIcon(Icons.zoom_in);
      expect(zoomIcon, findsOneWidget);

      // Tap the lift area
      await tester.tap(zoomIcon);
      await tester.pumpAndSettle();

      // Modal opens showing Active Trick title
      expect(find.text('Active Trick'), findsOneWidget);
      expect(find.text('Tap anywhere outside to dismiss'), findsOneWidget);
    });
  });
}
