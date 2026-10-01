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
import 'package:pedro/ui/widgets/card_widget.dart';

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
    return Stream.value(players[uid] ?? Player(id: uid, screenName: 'Player $uid'));
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

  @override
  Future<void> postNarratorCommentary({
    required String gameId,
    required String text,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameBoardScreen hand sorting & suit spacing', () {
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

    testWidgets('renders player hand grouped by suit and sorted low to high left-to-right',
        (tester) async {
      // Unsorted hand received from session
      final unsortedHand = [
        const pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace),
        const pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.four),
        const pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ten),
        const pedro.Card(suit: pedro.Suit.clubs, rank: pedro.Rank.two),
        const pedro.Card(suit: pedro.Suit.clubs, rank: pedro.Rank.king),
        const pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.three),
      ];

      mockGameRepo.currentSession = GameSession(
        gameId: 'game_sorting_1',
        name: 'Sorting Test Room',
        targetScore: 35,
        playerStates: [
          PlayerGameState(
            uid: 'p1',
            hand: unsortedHand,
            totalScore: 0,
          ),
          const PlayerGameState(
            uid: 'p2',
            hand: [],
            totalScore: 0,
          ),
        ],
        currentRound: const RoundState(
          dealerId: 'p1',
          phase: RoundPhase.playing,
          bidWinnerId: 'p1',
          bidValue: 4,
          trumpSuit: pedro.Suit.spades,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_sorting_1',
            currentUserId: 'p1',
            gameRepository: mockGameRepo,
            playerRepository: mockPlayerRepo,
            reactionRepository: mockReactionRepo,
            chatRepository: mockChatRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all CardWidgets inside the 'Your Hand' section
      final handFinder = find.ancestor(
        of: find.byType(CardWidget),
        matching: find.byWidgetPredicate((widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal),
      );

      final cardWidgetsInHand = tester
          .widgetList<CardWidget>(find.descendant(
            of: handFinder,
            matching: find.byType(CardWidget),
          ))
          .toList();

      expect(cardWidgetsInHand.length, equals(6));

      // Expected sorted order:
      // Clubs: 2, King
      // Diamonds: 3, 10
      // Spades: 4
      // Hearts: Ace
      expect(cardWidgetsInHand[0].card.suit, equals(pedro.Suit.clubs));
      expect(cardWidgetsInHand[0].card.rank, equals(pedro.Rank.two));

      expect(cardWidgetsInHand[1].card.suit, equals(pedro.Suit.clubs));
      expect(cardWidgetsInHand[1].card.rank, equals(pedro.Rank.king));

      expect(cardWidgetsInHand[2].card.suit, equals(pedro.Suit.diamonds));
      expect(cardWidgetsInHand[2].card.rank, equals(pedro.Rank.three));

      expect(cardWidgetsInHand[3].card.suit, equals(pedro.Suit.diamonds));
      expect(cardWidgetsInHand[3].card.rank, equals(pedro.Rank.ten));

      expect(cardWidgetsInHand[4].card.suit, equals(pedro.Suit.spades));
      expect(cardWidgetsInHand[4].card.rank, equals(pedro.Rank.four));

      expect(cardWidgetsInHand[5].card.suit, equals(pedro.Suit.hearts));
      expect(cardWidgetsInHand[5].card.rank, equals(pedro.Rank.ace));

      // Verify suit gap spacing:
      // Index 0 (Clubs 2) to Index 1 (Clubs King) -> same suit -> right padding 6.0
      // Index 1 (Clubs King) to Index 2 (Diamonds 3) -> different suit -> right padding 12.0
      // Index 2 (Diamonds 3) to Index 3 (Diamonds 10) -> same suit -> right padding 6.0
      // Index 3 (Diamonds 10) to Index 4 (Spades 4) -> different suit -> right padding 12.0
      // Index 4 (Spades 4) to Index 5 (Hearts Ace) -> different suit -> right padding 12.0
      final paddingWidgets = tester
          .widgetList<Padding>(find.descendant(
            of: handFinder,
            matching: find.byType(Padding),
          ))
          .where((p) => p.child is CardWidget)
          .toList();

      expect(paddingWidgets.length, equals(6));
      expect((paddingWidgets[0].padding as EdgeInsets).right, equals(6.0));
      expect((paddingWidgets[1].padding as EdgeInsets).right, equals(12.0));
      expect((paddingWidgets[2].padding as EdgeInsets).right, equals(6.0));
      expect((paddingWidgets[3].padding as EdgeInsets).right, equals(12.0));
      expect((paddingWidgets[4].padding as EdgeInsets).right, equals(12.0));
      expect((paddingWidgets[5].padding as EdgeInsets).right, equals(6.0));
    });
  });
}
