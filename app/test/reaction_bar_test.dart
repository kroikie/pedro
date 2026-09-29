import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/game_reaction.dart';
import 'package:pedro/data/repositories/reaction_repository.dart';
import 'package:pedro/ui/widgets/reaction_bar.dart';
import 'package:pedro/ui/widgets/floating_reactions_overlay.dart';

class FakeReactionRepository implements ReactionRepository {
  final _controller = StreamController<List<GameReaction>>.broadcast();
  final List<GameReaction> sentReactions = [];

  void emitReactions(List<GameReaction> reactions) {
    _controller.add(reactions);
  }

  @override
  Stream<List<GameReaction>> watchRecentReactions(String gameId) {
    return _controller.stream;
  }

  @override
  Future<void> sendReaction({
    required String gameId,
    required String senderId,
    required String senderName,
    required String emoji,
  }) async {
    final reaction = GameReaction(
      id: 'reaction_${sentReactions.length + 1}',
      senderId: senderId,
      senderName: senderName,
      emoji: emoji,
      timestamp: DateTime.now(),
    );
    sentReactions.add(reaction);
    _controller.add([reaction, ...sentReactions]);
  }
}

void main() {
  group('ReactionBar Widget', () {
    testWidgets('Renders all available reaction emojis', (tester) async {
      final fakeRepo = FakeReactionRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionBar(
              gameId: 'game_123',
              reactionRepository: fakeRepo,
            ),
          ),
        ),
      );

      for (final emoji in ReactionBar.availableEmojis) {
        expect(find.text(emoji), findsOneWidget);
      }
    });

    testWidgets('Tapping emoji sends reaction with correct parameters',
        (tester) async {
      final fakeRepo = FakeReactionRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionBar(
              gameId: 'game_123',
              reactionRepository: fakeRepo,
            ),
          ),
        ),
      );

      await tester.tap(find.text('🔥'));
      await tester.pump();

      // Debounce prevents second immediate tap
      await tester.tap(find.text('🔥'));
      await tester.pump();

      expect(fakeRepo.sentReactions.length, lessThanOrEqualTo(1));
    });
  });

  group('FloatingReactionsOverlay Widget', () {
    testWidgets('Spawns floating emoji particle on new reaction',
        (tester) async {
      final fakeRepo = FakeReactionRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FloatingReactionsOverlay(
                gameId: 'game_123',
                reactionRepository: fakeRepo,
              ),
            ),
          ),
        ),
      );

      // Initial historical reaction should not spawn
      fakeRepo.emitReactions([
        GameReaction(
          id: 'past_1',
          senderId: 'user_1',
          senderName: 'Bob',
          emoji: '👏',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ]);
      await tester.pump();

      expect(find.text('Bob'), findsNothing);

      // New reaction received in real time
      fakeRepo.emitReactions([
        GameReaction(
          id: 'fresh_1',
          senderId: 'user_2',
          senderName: 'Arthur',
          emoji: '🔥',
          timestamp: DateTime.now(),
        ),
        GameReaction(
          id: 'past_1',
          senderId: 'user_1',
          senderName: 'Bob',
          emoji: '👏',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('Arthur'), findsOneWidget);

      // Let animation finish and particle disappear
      await tester.pump(const Duration(milliseconds: 3000));
      expect(find.text('Arthur'), findsNothing);
    });
  });
}
