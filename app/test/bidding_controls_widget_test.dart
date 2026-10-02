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
  int? lastSubmittedBid;
  bool submitBidCalled = false;

  @override
  Stream<GameSession?> watchGameSession(String gameId) =>
      Stream.value(currentSession);

  @override
  Future<void> playCard(String gameId, pedro.Card card) async {}

  @override
  Future<void> startGame(String gameId) async {}

  @override
  Future<void> submitBid(String gameId, int? bid) async {
    submitBidCalled = true;
    lastSubmittedBid = bid;
  }

  @override
  Future<void> setTrumpSuit(String gameId, pedro.Suit suit) async {}

  @override
  Future<void> callPlayer(String gameId) async {}

  @override
  Future<void> deleteGame(String gameId) async {}
}

class MockPlayerRepo implements PlayerRepository {
  final Map<String, Player> players = {
    'p1': const Player(id: 'p1', screenName: 'Alice'),
    'p2': const Player(id: 'p2', screenName: 'Bob'),
    'p3': const Player(id: 'p3', screenName: 'Charlie'),
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

  group('Bidding Controls Widget Tests', () {
    testWidgets(
        'Opening bid (bidValue == 0): Pass is on left, Pass is disabled, says Place opening bid',
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
          phase: RoundPhase.wadger,
          turnIndex: 0, // p1's turn
          bidValue: 0,
        ),
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      // Heading indicates opening bid
      expect(find.text('Place opening bid (1-20)'), findsOneWidget);

      // Find all ActionChip widgets in the bid controls
      final chips = tester.widgetList<ActionChip>(find.byType(ActionChip)).toList();
      expect(chips.isNotEmpty, isTrue);

      // Pass chip must be the FIRST chip on the left
      final passChipWidget = chips.first;
      final passLabelFinder = find.descendant(
        of: find.byWidget(passChipWidget),
        matching: find.text('Pass'),
      );
      expect(passLabelFinder, findsOneWidget);

      // Pass must be disabled for opening bid
      expect(passChipWidget.onPressed, isNull);

      // Numeric chips 1..20 follow
      expect(find.text('1'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets(
        'Subsequent bid (bidValue > 0): Pass is on left, Pass is enabled, tapping Pass calls submitBid(null)',
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
          phase: RoundPhase.wadger,
          turnIndex: 0, // p1's turn
          bidValue: 5,
          bidWinnerId: 'p2',
        ),
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      expect(find.text('Place your bid (6-20) or Pass'), findsOneWidget);

      final chips = tester.widgetList<ActionChip>(find.byType(ActionChip)).toList();
      final passChipWidget = chips.first;
      expect(passChipWidget.onPressed, isNotNull);

      // Tap Pass
      await tester.tap(find.byWidget(passChipWidget));
      await tester.pumpAndSettle();

      expect(mockGameRepo.submitBidCalled, isTrue);
      expect(mockGameRepo.lastSubmittedBid, isNull);
    });

    testWidgets('Cards replaced badge renders on player seats during playing phase',
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
            cardsDiscarded: 3,
          ),
          const PlayerGameState(
            uid: 'p2',
            hand: [],
            cardsDiscarded: 4,
          ),
          const PlayerGameState(
            uid: 'p3',
            hand: [],
            cardsDiscarded: 0,
          ),
          const PlayerGameState(
            uid: 'p4',
            hand: [],
            cardsDiscarded: 2,
          ),
        ],
        currentRound: const RoundState(
          dealerId: 'p4',
          phase: RoundPhase.playing,
          trumpSuit: pedro.Suit.hearts,
          turnIndex: 0,
          bidValue: 6,
          bidWinnerId: 'p1',
        ),
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      // Local player area shows cards replaced
      expect(find.text('You replaced 3 cards'), findsOneWidget);

      // Other player seats show cards replaced
      expect(find.text('Replaced: 4'), findsOneWidget); // p2
      expect(find.text('Replaced: 0'), findsOneWidget); // p3
      expect(find.text('Replaced: 2'), findsOneWidget); // p4
    });

    testWidgets('Player seat displays Passed chip when player has passed during Wadger',
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
          const PlayerGameState(
            uid: 'p2',
            hand: [],
          ),
          const PlayerGameState(
            uid: 'p3',
            hand: [],
          ),
          const PlayerGameState(
            uid: 'p4',
            hand: [],
          ),
        ],
        currentRound: const RoundState(
          dealerId: 'p4',
          phase: RoundPhase.wadger,
          turnIndex: 0,
          bidValue: 6,
          bidWinnerId: 'p3',
          passedPlayerIds: ['p2'],
        ),
      );

      await tester.pumpWidget(buildTestScreen(session));
      await tester.pumpAndSettle();

      expect(find.text('Passed'), findsOneWidget);
    });
  });
}
