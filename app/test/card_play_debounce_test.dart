import 'dart:async';
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

class FakeGameRepository implements GameRepository {
  final _sessionController = StreamController<GameSession?>.broadcast();
  final List<pedro.Card> playedCardsHistory = [];
  Completer<void>? playCardCompleter;
  bool shouldThrowError = false;

  void emitSession(GameSession? session) {
    _sessionController.add(session);
  }

  @override
  Stream<GameSession?> watchGameSession(String gameId) {
    return _sessionController.stream;
  }

  @override
  Future<void> playCard(String gameId, pedro.Card card) async {
    playedCardsHistory.add(card);
    if (shouldThrowError) {
      throw Exception('Network error during play');
    }
    if (playCardCompleter != null) {
      await playCardCompleter!.future;
    }
  }

  @override
  Future<void> startGame(String gameId) async {}

  @override
  Future<void> submitBid(String gameId, int? bid) async {}

  @override
  Future<void> setTrumpSuit(String gameId, pedro.Suit suit) async {}

  @override
  Future<void> callPlayer(String gameId) async {}
}

class FakePlayerRepository implements PlayerRepository {
  @override
  Future<Player?> getPlayer(String uid) async {
    return Player(id: uid, screenName: 'Player $uid');
  }

  @override
  Future<void> updatePlayer(Player player) async {}

  @override
  Future<void> addFcmToken(String uid, String token, String platform) async {}

  @override
  Future<void> removeFcmToken(String uid, String token) async {}

  @override
  Stream<List<Player>> watchAllPlayers() {
    return const Stream.empty();
  }
}

class FakeReactionRepository implements ReactionRepository {
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

class FakeChatRepository implements ChatRepository {
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
    required String commentary,
  }) async {}
}

GameSession createTestSession({
  required int turnIndex,
  required List<pedro.Card> playerHand,
  pedro.Suit trumpSuit = pedro.Suit.spades,
}) {
  return GameSession(
    gameId: 'test_game',
    targetScore: 35,
    playerStates: [
      PlayerGameState(
        uid: 'p1',
        hand: playerHand,
        totalScore: 0,
        currentRoundPoints: 0,
      ),
      PlayerGameState(
        uid: 'p2',
        hand: const [pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ten)],
        totalScore: 0,
        currentRoundPoints: 0,
      ),
    ],
    currentRound: RoundState(
      dealerId: 'p1',
      bidWinnerId: 'p1',
      bidValue: 10,
      phase: RoundPhase.playing,
      turnIndex: turnIndex,
      trumpSuit: trumpSuit,
      currentLift: const Lift(
        leadPlayerId: 'p1',
        plays: {},
      ),
    ),
  );
}

void main() {
  group('CardWidget Submission State & Feedback', () {
    testWidgets('renders normally with full opacity when not submitting',
        (tester) async {
      bool tapped = false;
      const card = pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              isSubmitting: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 1.0);

      await tester.tap(find.byType(CardWidget));
      expect(tapped, isTrue);
    });

    testWidgets('renders dimmed and blocks taps when isSubmitting is true',
        (tester) async {
      bool tapped = false;
      const card = pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: card,
              isSubmitting: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 0.45);

      await tester.tap(find.byType(CardWidget));
      expect(tapped, isFalse);
    });
  });

  group('GameBoardScreen Card Debouncing & Duplicate Prevention', () {
    testWidgets('rapid double tap only submits card once', (tester) async {
      final fakeGameRepo = FakeGameRepository();
      final fakePlayerRepo = FakePlayerRepository();
      final fakeReactionRepo = FakeReactionRepository();
      final fakeChatRepo = FakeChatRepository();

      const cardToPlay = pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.king);
      final initialSession = createTestSession(
        turnIndex: 0,
        playerHand: [cardToPlay],
      );

      // Keep playCard in flight to verify debouncing
      fakeGameRepo.playCardCompleter = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'test_game',
            currentUserId: 'p1',
            gameRepository: fakeGameRepo,
            playerRepository: fakePlayerRepo,
            reactionRepository: fakeReactionRepo,
            chatRepository: fakeChatRepo,
          ),
        ),
      );

      fakeGameRepo.emitSession(initialSession);
      await tester.pumpAndSettle();

      // Tap card once
      await tester.tap(find.byType(CardWidget).first);
      await tester.pump();

      // Rapidly tap the card again
      await tester.tap(find.byType(CardWidget).first);
      await tester.pump();

      // Third tap
      await tester.tap(find.byType(CardWidget).first);
      await tester.pump();

      // Only 1 call should have been dispatched to repository
      expect(fakeGameRepo.playedCardsHistory.length, 1);
      expect(fakeGameRepo.playedCardsHistory.first, cardToPlay);

      // Complete in-flight call
      fakeGameRepo.playCardCompleter!.complete();
      await tester.pump();

      // Even after completion, if hand still contains the card and it's p1 turn, lock prevents second submission
      await tester.tap(find.byType(CardWidget).first);
      await tester.pump();
      expect(fakeGameRepo.playedCardsHistory.length, 1);

      // Now emit updated session where card is played and it is p2's turn
      final updatedSession = createTestSession(
        turnIndex: 1,
        playerHand: [],
      );
      fakeGameRepo.emitSession(updatedSession);
      await tester.pumpAndSettle();
    });

    testWidgets('server error releases submission lock to allow retry',
        (tester) async {
      final fakeGameRepo = FakeGameRepository();
      fakeGameRepo.shouldThrowError = true;
      final fakePlayerRepo = FakePlayerRepository();
      final fakeReactionRepo = FakeReactionRepository();
      final fakeChatRepo = FakeChatRepository();

      const cardToPlay = pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.king);
      final initialSession = createTestSession(
        turnIndex: 0,
        playerHand: [cardToPlay],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'test_game',
            currentUserId: 'p1',
            gameRepository: fakeGameRepo,
            playerRepository: fakePlayerRepo,
            reactionRepository: fakeReactionRepo,
            chatRepository: fakeChatRepo,
          ),
        ),
      );

      fakeGameRepo.emitSession(initialSession);
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.byType(CardWidget).first);
      await tester.pumpAndSettle();

      // Error snackbar should be displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(fakeGameRepo.playedCardsHistory.length, 1);

      // Fix the error and tap again (after 500ms debounce interval)
      fakeGameRepo.shouldThrowError = false;
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(CardWidget).first);
      await tester.pump();

      expect(fakeGameRepo.playedCardsHistory.length, 2);
    });
  });
}
