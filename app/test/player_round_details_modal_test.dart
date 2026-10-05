import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart' as pedro;
import 'package:pedro/data/models/game_session.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/ui/widgets/player_round_details_modal.dart';

void main() {
  group('PlayerRoundDetailsModal', () {
    final session = GameSession(
      gameId: 'game-123',
      targetScore: 35,
      playerStates: [
        const PlayerGameState(
          uid: 'p1',
          hand: [],
          totalScore: 12,
          currentRoundPoints: 8,
          cardsDiscarded: 3,
          earnedPoints: ['High', 'Hang Jack', '5'],
          gameValue: 25,
        ),
        const PlayerGameState(
          uid: 'p2',
          hand: [],
          totalScore: 4,
          currentRoundPoints: 1,
          cardsDiscarded: 1,
          earnedPoints: ['Low'],
          gameValue: 10,
        ),
      ],
      currentRound: const RoundState(
        dealerId: 'p2',
        phase: RoundPhase.playing,
        trumpSuit: pedro.Suit.hearts,
        turnIndex: 0,
        bidValue: 7,
        bidWinnerId: 'p1',
        completedLifts: [
          Lift(leadPlayerId: 'p1', winnerId: 'p1'),
          Lift(leadPlayerId: 'p1', winnerId: 'p1'),
          Lift(leadPlayerId: 'p2', winnerId: 'p2'),
        ],
      ),
    );

    final playerCache = {
      'p1': const Player(id: 'p1', screenName: 'Alice'),
      'p2': const Player(id: 'p2', screenName: 'Bob'),
    };

    testWidgets('renders player info, bidder badge, earned points, and discards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PlayerRoundDetailsModal.show(
                  context: context,
                  session: session,
                  targetPlayerId: 'p1',
                  currentPlayerId: 'p1',
                  playerCache: playerCache,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check player name & score
      expect(find.text('You'), findsOneWidget);
      expect(find.textContaining('Total Score: 12'), findsOneWidget);

      // Check bidder contract info
      expect(find.text('BIDDER: 7'), findsOneWidget);
      expect(find.textContaining('Round Points: 8 / 7'), findsOneWidget);

      // Check earned points badges & descriptions
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Highest trump played (1 pt)'), findsOneWidget);

      expect(find.text('Hang Jack'), findsOneWidget);
      expect(find.text('Stole opponent\'s Jack of trump (3 pts)'), findsOneWidget);

      expect(find.text('5 of Trump'), findsOneWidget);
      expect(find.text('5 of trump captured (5 pts)'), findsOneWidget);

      // Check discards
      expect(
          find.text('You discarded and replaced 3 cards'), findsOneWidget);

      // Check buttons for Won Lifts and Game Points
      expect(find.text('Won Lifts'), findsOneWidget);
      expect(find.text('2 lifts'), findsOneWidget);
      expect(find.text('Game Value'), findsOneWidget);
      expect(find.text('25 pts'), findsOneWidget);
    });

    testWidgets('renders non-bidder player details correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PlayerRoundDetailsModal.show(
                  context: context,
                  session: session,
                  targetPlayerId: 'p2',
                  currentPlayerId: 'p1',
                  playerCache: playerCache,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check player name & score
      expect(find.text('Bob'), findsOneWidget);
      expect(find.textContaining('Total Score: 4'), findsOneWidget);
      expect(find.textContaining('BIDDER'), findsNothing);

      // Check points
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Lowest trump played (1 pt)'), findsOneWidget);

      // Check discards
      expect(
          find.text('Bob discarded and replaced 1 card'), findsOneWidget);
      expect(find.text('Won Lifts'), findsOneWidget);
      expect(find.text('1 lift'), findsOneWidget);
      expect(find.text('Game Value'), findsOneWidget);
      expect(find.text('10 pts'), findsOneWidget);
    });
  });
}
