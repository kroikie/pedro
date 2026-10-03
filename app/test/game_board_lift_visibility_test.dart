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
import 'package:pedro/ui/widgets/card_widget.dart';

class MockGameRepo implements GameRepository {
  GameSession? currentSession;

  @override
  Stream<GameSession?> watchGameSession(String gameId) => Stream.value(currentSession);

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
}

class MockPlayerRepo implements PlayerRepository {
  final Map<String, Player> players = {
    'p1': const Player(id: 'p1', screenName: 'Frances'),
    'p2': const Player(id: 'p2', screenName: 'Jr'),
    'p3': const Player(id: 'p3', screenName: 'Wiggy'),
    'p4': const Player(id: 'p4', screenName: 'Garvi'),
    'p5': const Player(id: 'p5', screenName: 'Renee'),
    'p6': const Player(id: 'p6', screenName: 'Chantal'),
    'p7': const Player(id: 'p7', screenName: 'Shiv'),
    'p8': const Player(id: 'p8', screenName: 'Arthur'),
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
  Stream<List<Player>> watchAllPlayers() => Stream.value(players.values.toList());
}

class MockReactionRepo implements ReactionRepository {
  @override
  Stream<List<GameReaction>> watchRecentReactions(String gameId) => const Stream.empty();

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
  Stream<List<ChatMessage>> watchMessages(String gameId) => const Stream.empty();

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

GameSession createSessionWithPlayers(int numPlayers, {bool includeLift = true}) {
  final playerStates = List.generate(numPlayers, (i) {
    final uid = 'p${i + 1}';
    return PlayerGameState(
      uid: uid,
      hand: [
        pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.queen),
      ],
      currentRoundPoints: 0,
      totalScore: 10,
    );
  });

  final plays = <String, pedro.Card>{};
  final ranks = [
    pedro.Rank.three,
    pedro.Rank.nine,
    pedro.Rank.king,
    pedro.Rank.eight,
    pedro.Rank.jack,
    pedro.Rank.four,
    pedro.Rank.seven,
    pedro.Rank.ten,
  ];

  for (int i = 0; i < numPlayers; i++) {
    plays['p${i + 1}'] = pedro.Card(suit: pedro.Suit.spades, rank: ranks[i % ranks.length]);
  }

  return GameSession(
    gameId: 'game_test',
    name: 'Pedro Championship',
    targetScore: 35,
    playerStates: playerStates,
    currentRound: RoundState(
      dealerId: 'p1',
      bidWinnerId: 'p1',
      bidValue: 9,
      trumpSuit: pedro.Suit.spades,
      phase: RoundPhase.playing,
      turnIndex: 0,
      currentLift: includeLift
          ? Lift(
              leadPlayerId: 'p1',
              winnerId: 'p2',
              plays: plays,
            )
          : null,
      lastLift: includeLift
          ? Lift(
              leadPlayerId: 'p1',
              winnerId: 'p2',
              plays: plays,
            )
          : null,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('4 players game renders lift plays in 1 row without overlap', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = MockGameRepo();
    final mockPlayer = MockPlayerRepo();
    mockGame.currentSession = createSessionWithPlayers(4);

    await tester.pumpWidget(
      MaterialApp(
        home: GameBoardScreen(
          gameId: 'game_test',
          currentUserId: 'p1',
          gameRepository: mockGame,
          playerRepository: mockPlayer,
          chatRepository: MockChatRepo(),
          reactionRepository: MockReactionRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lift Won by '), findsOneWidget);
    // In 4 players, 4 cards in lift + 1 in hand = 5 CardWidgets total
    expect(find.byType(CardWidget), findsNWidgets(5));
    expect(find.text('LEAD'), findsOneWidget);
    expect(find.text('WINNER'), findsOneWidget);
  });

  testWidgets('5 players game renders lift plays in 2 rows without blocking cards', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = MockGameRepo();
    final mockPlayer = MockPlayerRepo();
    mockGame.currentSession = createSessionWithPlayers(5);

    await tester.pumpWidget(
      MaterialApp(
        home: GameBoardScreen(
          gameId: 'game_test',
          currentUserId: 'p1',
          gameRepository: mockGame,
          playerRepository: mockPlayer,
          chatRepository: MockChatRepo(),
          reactionRepository: MockReactionRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lift Won by '), findsOneWidget);
    // 5 cards in lift + 1 in hand = 6 CardWidgets
    expect(find.byType(CardWidget), findsNWidgets(6));

    // Verify side player badge bounding boxes do NOT overlap trick cards
    final p2Finder = find.text('Jr'); // p2 at (0.92, -0.26)
    final p5Finder = find.text('Renee'); // p5 at (-0.92, -0.26)
    expect(p2Finder, findsWidgets);
    expect(p5Finder, findsWidgets);

    // Verify all 5 player names in lift are present
    expect(find.text('Frances'), findsWidgets);
    expect(find.text('Wiggy'), findsWidgets);
    expect(find.text('Garvi'), findsWidgets);
  });

  testWidgets('6 players game renders 2 rows of 3 cards and avoids side badges', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = MockGameRepo();
    final mockPlayer = MockPlayerRepo();
    mockGame.currentSession = createSessionWithPlayers(6);

    await tester.pumpWidget(
      MaterialApp(
        home: GameBoardScreen(
          gameId: 'game_test',
          currentUserId: 'p1',
          gameRepository: mockGame,
          playerRepository: mockPlayer,
          chatRepository: MockChatRepo(),
          reactionRepository: MockReactionRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lift Won by '), findsOneWidget);
    // 6 cards in lift + 1 in hand = 7 CardWidgets
    expect(find.byType(CardWidget), findsNWidgets(7));
  });

  testWidgets('8 players game on narrow screen (360x640) renders cleanly with 0 overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = MockGameRepo();
    final mockPlayer = MockPlayerRepo();
    mockGame.currentSession = createSessionWithPlayers(8);

    await tester.pumpWidget(
      MaterialApp(
        home: GameBoardScreen(
          gameId: 'game_test',
          currentUserId: 'p1',
          gameRepository: mockGame,
          playerRepository: mockPlayer,
          chatRepository: MockChatRepo(),
          reactionRepository: MockReactionRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Zero overflows and all 8 cards in trick + 1 in hand
    expect(find.byType(CardWidget), findsNWidgets(9));
    expect(find.text('WINNER'), findsOneWidget);
    expect(find.text('LEAD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Previous Trick modal renders 8 cards in 2 rows without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = MockGameRepo();
    final mockPlayer = MockPlayerRepo();
    // In progress lift with plays so clock icon appears
    final session = createSessionWithPlayers(8);
    // modify currentLift to be active and incomplete
    final activePlays = Map<String, pedro.Card>.from(session.currentRound.currentLift!.plays);
    activePlays.remove('p8');
    mockGame.currentSession = session.copyWith(
      currentRound: session.currentRound.copyWith(
        currentLift: session.currentRound.currentLift!.copyWith(
          winnerId: null,
          plays: activePlays,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameBoardScreen(
          gameId: 'game_test',
          currentUserId: 'p1',
          gameRepository: mockGame,
          playerRepository: mockPlayer,
          chatRepository: MockChatRepo(),
          reactionRepository: MockReactionRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the previous lift icon
    final historyIcon = find.byIcon(Icons.history);
    expect(historyIcon, findsOneWidget);
    await tester.tap(historyIcon);
    await tester.pumpAndSettle();

    expect(find.text('Previous Trick'), findsOneWidget);
    expect(find.text('Won by Jr'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
