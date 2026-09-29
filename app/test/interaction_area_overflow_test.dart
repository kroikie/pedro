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
}

class MockPlayerRepo implements PlayerRepository {
  final Map<String, Player> players = {
    'p1': const Player(id: 'p1', screenName: 'Arthur Thompson'),
    'p2': const Player(id: 'p2', screenName: 'arthur thompson'),
    'p3': const Player(id: 'p3', screenName: 'Kimoy'),
    'p4': const Player(id: 'p4', screenName: 'Dona'),
  };

  @override
  Future<Player?> getPlayer(String uid) async {
    return players[uid] ?? Player(id: uid, screenName: 'Player $uid');
  }

  @override
  Future<void> updatePlayer(Player player) async {}

  @override
  Future<void> addFcmToken(String uid, String token, String platform) async {}

  @override
  Future<void> removeFcmToken(String uid, String token) async {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Row above player cards does not overflow with long name and call player button on 393px screen', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = MockGameRepo();
    final mockPlayer = MockPlayerRepo();

    mockGame.currentSession = const GameSession(
      gameId: 'game_test',
      name: 'Pedro Championship',
      targetScore: 35,
      playerStates: [
        PlayerGameState(
          uid: 'p1',
          hand: [
            pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.seven),
            pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.nine),
            pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.ten),
          ],
          currentRoundPoints: 0,
          totalScore: 24,
        ),
        PlayerGameState(
          uid: 'p2',
          hand: [],
          currentRoundPoints: 0,
          totalScore: 25,
          earnedPoints: ['High', 'Low', 'Hang Jack', '9'],
        ),
        PlayerGameState(
          uid: 'p3',
          hand: [],
          currentRoundPoints: 0,
          totalScore: 1,
        ),
        PlayerGameState(
          uid: 'p4',
          hand: [],
          currentRoundPoints: 0,
          totalScore: 17,
        ),
      ],
      currentRound: RoundState(
        dealerId: 'p3',
        bidWinnerId: 'p1', // Local player is bidder: "YOU BID 4"
        bidValue: 4,
        trumpSuit: pedro.Suit.diamonds,
        phase: RoundPhase.playing,
        turnIndex: 1, // Turn is on p2: "arthur thompson"
        currentLift: Lift(
          leadPlayerId: 'p3',
          winnerId: 'p2',
          plays: {
            'p3': pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ten),
            'p2': pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.king),
          },
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
          reactionRepository: MockReactionRepo(),
          chatRepository: MockChatRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YOU BID 4'), findsOneWidget);
    expect(find.text('Target: 0 / 4 pts'), findsOneWidget);
    expect(find.text('Total: 24'), findsOneWidget);
    expect(find.text('Call Player'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Row above player cards on narrow screen (360px and 320px)', (tester) async {
    for (final width in [360.0, 320.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;

      final mockGame = MockGameRepo();
      final mockPlayer = MockPlayerRepo();

      mockGame.currentSession = const GameSession(
        gameId: 'game_test',
        name: 'Pedro Championship',
        targetScore: 35,
        playerStates: [
          PlayerGameState(
            uid: 'p1',
            hand: [
              pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.seven),
            ],
            currentRoundPoints: 0,
            totalScore: 24,
          ),
          PlayerGameState(
            uid: 'p2',
            hand: [],
            totalScore: 25,
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p2',
          bidWinnerId: 'p1',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
          phase: RoundPhase.playing,
          turnIndex: 1, // waiting for p2
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_test',
            currentUserId: 'p1',
            gameRepository: mockGame,
            playerRepository: mockPlayer,
            reactionRepository: MockReactionRepo(),
            chatRepository: MockChatRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at width $width');
    }
  });

  testWidgets('Row above cards with active cooldown and text scaling does not overflow', (tester) async {
    for (final width in [320.0, 360.0, 393.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;

      final mockGame = MockGameRepo();
      final mockPlayer = MockPlayerRepo();

      mockGame.currentSession = GameSession(
        gameId: 'game_cooldown',
        name: 'Cooldown Pedro',
        targetScore: 35,
        playerStates: const [
          PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.seven)],
            currentRoundPoints: 2,
            totalScore: 18,
          ),
          PlayerGameState(
            uid: 'p2',
            hand: [],
            totalScore: 20,
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p2',
          bidWinnerId: 'p1',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
          phase: RoundPhase.playing,
          turnIndex: 1, // waiting on p2
          lastCalledAt: DateTime.now().toUtc(), // Cooldown active!
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: GameBoardScreen(
              gameId: 'game_cooldown',
              currentUserId: 'p1',
              gameRepository: mockGame,
              playerRepository: mockPlayer,
              reactionRepository: MockReactionRepo(),
              chatRepository: MockChatRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Called ('), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Failed during cooldown at width $width');
    }
  });

  testWidgets('isMyTurn text gracefully scales and does not overflow on narrow screens', (tester) async {
    for (final width in [320.0, 360.0, 393.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;

      final mockGame = MockGameRepo();
      final mockPlayer = MockPlayerRepo();

      mockGame.currentSession = const GameSession(
        gameId: 'game_my_turn',
        name: 'My Turn Pedro',
        targetScore: 35,
        playerStates: [
          PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.seven)],
            currentRoundPoints: 4,
            totalScore: 30,
            earnedPoints: ['High', 'Low', 'Jack', '10 of Trump'],
          ),
          PlayerGameState(
            uid: 'p2',
            hand: [],
            totalScore: 20,
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p2',
          bidWinnerId: 'p1',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
          phase: RoundPhase.playing,
          turnIndex: 0, // isMyTurn == true
          currentLift: Lift(
            leadPlayerId: 'p1',
            winnerId: 'p1',
            plays: {},
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_my_turn',
            currentUserId: 'p1',
            gameRepository: mockGame,
            playerRepository: mockPlayer,
            reactionRepository: MockReactionRepo(),
            chatRepository: MockChatRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'REVIEWING LIFT...' || w.data == 'YOUR TURN TO LEAD' || w.data == 'YOUR TURN'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'Failed during isMyTurn at width $width');
    }
  });

  testWidgets('Wide screen layout uses horizontal side-by-side Row in waiting area', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockGame = MockGameRepo();
    final mockPlayer = MockPlayerRepo();

    mockGame.currentSession = const GameSession(
      gameId: 'game_wide',
      name: 'Desktop Pedro',
      targetScore: 35,
      playerStates: [
        PlayerGameState(
          uid: 'p1',
          hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.seven)],
          totalScore: 10,
        ),
        PlayerGameState(
          uid: 'p2',
          hand: [],
          totalScore: 15,
        ),
      ],
      currentRound: RoundState(
        dealerId: 'p1',
        phase: RoundPhase.playing,
        turnIndex: 1, // waiting for p2
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameBoardScreen(
          gameId: 'game_wide',
          currentUserId: 'p1',
          gameRepository: mockGame,
          playerRepository: mockPlayer,
          reactionRepository: MockReactionRepo(),
          chatRepository: MockChatRepo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Call Player'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
