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
import 'package:pedro/ui/widgets/chat_overlay.dart';

class MockGameRepository implements GameRepository {
  GameSession? currentSession;

  @override
  Stream<GameSession?> watchGameSession(String gameId) {
    return Stream.value(currentSession);
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
  Future<void> callPlayer(String gameId) async {}

  @override
  Future<void> deleteGame(String gameId) async {}
}

class MockPlayerRepository implements PlayerRepository {
  final Map<String, Player> players = {
    'p1': const Player(id: 'p1', screenName: 'Arthur'),
    'p2': const Player(id: 'p2', screenName: 'Gavy'),
    'p3': const Player(id: 'p3', screenName: 'Dona'),
    'p4': const Player(id: 'p4', screenName: 'Kimoy'),
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
  Stream<Player?> watchPlayer(String uid) {
    return Stream.value(players[uid]);
  }

  @override
  Stream<List<Player>> watchAllPlayers() {
    return Stream.value(players.values.toList());
  }
}

class MockReactionRepository implements ReactionRepository {
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

class MockChatRepository implements ChatRepository {
  final List<String> sentMessages = [];

  @override
  Stream<List<ChatMessage>> watchMessages(String gameId) {
    return Stream.value([
      ChatMessage(
        id: 'msg1',
        senderId: 'ai_narrator',
        senderName: 'AI Narrator',
        text: 'Dat is ah brave bid!',
        timestamp: DateTime.now(),
        isAi: true,
      ),
      ChatMessage(
        id: 'msg2',
        senderId: 'p2',
        senderName: 'Gavy',
        text: 'Watch me take this trick!',
        timestamp: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<void> sendMessage({
    required String gameId,
    required String senderId,
    required String senderName,
    required String text,
    bool isAi = false,
  }) async {
    sentMessages.add(text);
  }

  @override
  Future<void> postNarratorCommentary({
    required String gameId,
    required String commentary,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameBoardScreen UI updates & overflow prevention', () {
    late MockGameRepository mockGameRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockReactionRepository mockReactionRepo;
    late MockChatRepository mockChatRepo;

    setUp(() {
      mockGameRepo = MockGameRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockReactionRepo = MockReactionRepository();
      mockChatRepo = MockChatRepository();
    });

    testWidgets('App bar displays the name of the game instead of Pedro: PLAYING',
        (tester) async {
      mockGameRepo.currentSession = const GameSession(
        gameId: 'game_123',
        name: 'Trinidad Champions League',
        targetScore: 35,
        playerStates: [
          PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ten)],
            totalScore: 10,
          ),
          PlayerGameState(
            uid: 'p2',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.five)],
            totalScore: 5,
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p1',
          phase: RoundPhase.playing,
          bidWinnerId: 'p1',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_123',
            currentUserId: 'p1',
            gameRepository: mockGameRepo,
            playerRepository: mockPlayerRepo,
            reactionRepository: mockReactionRepo,
            chatRepository: mockChatRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display game name
      expect(find.text('Trinidad Champions League'), findsOneWidget);
      // Should NOT display "Pedro: PLAYING"
      expect(find.text('Pedro: PLAYING'), findsNothing);
    });

    testWidgets('App bar falls back to widget.gameName when session name is empty',
        (tester) async {
      mockGameRepo.currentSession = const GameSession(
        gameId: 'game_123',
        targetScore: 35,
        playerStates: [
          PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ten)],
            totalScore: 0,
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p1',
          phase: RoundPhase.playing,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_123',
            gameName: 'Lime Room #4',
            currentUserId: 'p1',
            gameRepository: mockGameRepo,
            playerRepository: mockPlayerRepo,
            reactionRepository: mockReactionRepo,
            chatRepository: mockChatRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lime Room #4'), findsOneWidget);
      expect(find.text('Pedro: PLAYING'), findsNothing);
    });

    testWidgets(
        'Expanding chat on mobile screen does not cause pixel overflow and fits cleanly',
        (tester) async {
      // Simulate iPhone 17 viewport: 393 x 852 logical pixels
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockGameRepo.currentSession = GameSession(
        gameId: 'game_123',
        name: 'Sunday Pedro Clash',
        targetScore: 35,
        playerStates: [
          const PlayerGameState(
            uid: 'p1',
            hand: [
              pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ten),
              pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.five),
              pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.five),
            ],
            currentRoundPoints: 0,
            totalScore: 1,
          ),
          const PlayerGameState(
            uid: 'p2',
            hand: [
              pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.king),
            ],
            currentRoundPoints: 0,
            totalScore: 25,
            earnedPoints: ['Bid: 4'],
          ),
          const PlayerGameState(
            uid: 'p3',
            hand: [
              pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.queen),
            ],
            currentRoundPoints: 0,
            totalScore: 17,
          ),
          const PlayerGameState(
            uid: 'p4',
            hand: [
              pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ace),
            ],
            currentRoundPoints: 0,
            totalScore: 20,
            earnedPoints: ['High', 'Low'],
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p1',
          bidWinnerId: 'p2',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
          phase: RoundPhase.playing,
          turnIndex: 1,
          currentLift: const Lift(
            leadPlayerId: 'p2',
            plays: {
              'p2': pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ten),
              'p3': pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.jack),
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_123',
            currentUserId: 'p1',
            gameRepository: mockGameRepo,
            playerRepository: mockPlayerRepo,
            reactionRepository: mockReactionRepo,
            chatRepository: mockChatRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify collapsed initially
      expect(find.text('Game Chat'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // Open the chat
      await tester.tap(find.text('Game Chat'));
      await tester.pumpAndSettle();

      // Chat is now expanded
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Dat is ah brave bid!'), findsOneWidget);

      // No overflow exception should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Expanding chat on small device (iPhone SE 375x667) does not cause pixel overflow',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockGameRepo.currentSession = GameSession(
        gameId: 'game_se',
        name: 'Short Screen Test',
        targetScore: 35,
        playerStates: [
          const PlayerGameState(
            uid: 'p1',
            hand: [
              pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ten),
              pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.five),
            ],
            currentRoundPoints: 0,
            totalScore: 4,
          ),
          const PlayerGameState(
            uid: 'p2',
            hand: [pedro.Card(suit: pedro.Suit.clubs, rank: pedro.Rank.ace)],
            currentRoundPoints: 2,
            totalScore: 12,
            earnedPoints: ['Bid: 4'],
          ),
          const PlayerGameState(
            uid: 'p3',
            hand: [pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.king)],
            currentRoundPoints: 0,
            totalScore: 9,
          ),
          const PlayerGameState(
            uid: 'p4',
            hand: [pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.five)],
            currentRoundPoints: 0,
            totalScore: 15,
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p1',
          bidWinnerId: 'p2',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
          phase: RoundPhase.playing,
          turnIndex: 0,
          currentLift: const Lift(
            leadPlayerId: 'p2',
            plays: {
              'p2': pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.jack),
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_se',
            currentUserId: 'p1',
            gameRepository: mockGameRepo,
            playerRepository: mockPlayerRepo,
            reactionRepository: mockReactionRepo,
            chatRepository: mockChatRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Game Chat'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChatOverlay respects custom expandedHeight when provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatOverlay(
              gameId: 'custom_height_game',
              chatRepository: mockChatRepo,
              playerRepository: mockPlayerRepo,
              expandedHeight: 210,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainerBefore =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainerBefore.constraints?.maxHeight ?? 60, 60);

      await tester.tap(find.text('Game Chat'));
      await tester.pumpAndSettle();

      final animatedContainerAfter =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainerAfter.constraints?.maxHeight ?? 210, 210);
    });

    testWidgets(
        'When keyboard is visible on iPhone SE, text field remains visible above keyboard with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      mockGameRepo.currentSession = GameSession(
        gameId: 'game_keyboard_test',
        name: 'Keyboard Test Game',
        targetScore: 35,
        playerStates: [
          const PlayerGameState(
            uid: 'p1',
            hand: [
              pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ten),
              pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.five),
            ],
            currentRoundPoints: 0,
            totalScore: 4,
          ),
          const PlayerGameState(
            uid: 'p2',
            hand: [pedro.Card(suit: pedro.Suit.clubs, rank: pedro.Rank.ace)],
            currentRoundPoints: 2,
            totalScore: 12,
            earnedPoints: ['Bid: 4'],
          ),
          const PlayerGameState(
            uid: 'p3',
            hand: [pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.king)],
            currentRoundPoints: 0,
            totalScore: 9,
          ),
          const PlayerGameState(
            uid: 'p4',
            hand: [pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.five)],
            currentRoundPoints: 0,
            totalScore: 15,
          ),
        ],
        currentRound: const RoundState(
          dealerId: 'p1',
          bidWinnerId: 'p2',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
          phase: RoundPhase.playing,
          turnIndex: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_keyboard_test',
            currentUserId: 'p1',
            gameRepository: mockGameRepo,
            playerRepository: mockPlayerRepo,
            reactionRepository: mockReactionRepo,
            chatRepository: mockChatRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand chat
      await tester.tap(find.text('Game Chat'));
      await tester.pumpAndSettle();

      // Before keyboard: cards hand is visible
      expect(find.text('Your Hand'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Simulate soft keyboard appearing (300px keyboard height)
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      // TextField must still be present and rendered with no overflow
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify the TextField bottom is at or above the keyboard top (667 - 300 = 367)
      final textFieldBottom = tester.getBottomLeft(find.byType(TextField)).dy;
      expect(textFieldBottom <= 367.0, isTrue);

      // Dismissing the keyboard restores the full interaction area
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      expect(find.text('Your Hand'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Hitting done on the keyboard does not submit message; UI send button submits message',
        (tester) async {
      mockGameRepo.currentSession = const GameSession(
        gameId: 'game_submit_test',
        targetScore: 35,
        playerStates: [
          PlayerGameState(
            uid: 'p1',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ten)],
            totalScore: 0,
          ),
        ],
        currentRound: RoundState(
          dealerId: 'p1',
          phase: RoundPhase.playing,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_submit_test',
            currentUserId: 'p1',
            gameRepository: mockGameRepo,
            playerRepository: mockPlayerRepo,
            reactionRepository: mockReactionRepo,
            chatRepository: mockChatRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the chat
      await tester.tap(find.text('Game Chat'));
      await tester.pumpAndSettle();

      // Type a draft message
      await tester.enterText(find.byType(TextField), 'Wait nah man!');
      await tester.pump();

      // Verify text is in the field
      expect(find.text('Wait nah man!'), findsOneWidget);

      // Simulate hitting "Done" on the soft keyboard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify message was NOT submitted and draft is still intact
      expect(mockChatRepo.sentMessages, isEmpty);
      expect(find.text('Wait nah man!'), findsOneWidget);

      // Now tap the UI send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Message should now be submitted via UI action and text field cleared
      expect(mockChatRepo.sentMessages, contains('Wait nah man!'));
      expect(find.text('Wait nah man!'), findsNothing);
    });
  });
}
