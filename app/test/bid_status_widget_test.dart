import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart' as pedro;
import 'package:pedro/data/models/game_session.dart';
import 'package:pedro/ui/widgets/bid_status_widget.dart';

void main() {
  group('BidStatusWidget', () {
    testWidgets('Renders bidding in progress during wadger phase when no bid',
        (tester) async {
      const round = RoundState(
        dealerId: 'dealer1',
        phase: RoundPhase.wadger,
        bidValue: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                BidStatusWidget(
                  round: round,
                  targetScore: 35,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bidding...'), findsOneWidget);
      expect(find.text('Target: 35'), findsOneWidget);
    });

    testWidgets('Renders current high bid during wadger phase', (tester) async {
      const round = RoundState(
        dealerId: 'dealer1',
        bidWinnerId: 'player1',
        phase: RoundPhase.wadger,
        bidValue: 8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                BidStatusWidget(
                  round: round,
                  targetScore: 35,
                  bidWinnerName: 'Alice',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bid: 8 (Alice)'), findsOneWidget);
      expect(find.text('Target: 35'), findsOneWidget);
    });

    testWidgets(
        'Renders winning bidder name, trump suit, and point progress in playing phase',
        (tester) async {
      const round = RoundState(
        dealerId: 'dealer1',
        bidWinnerId: 'player1',
        phase: RoundPhase.playing,
        bidValue: 10,
        trumpSuit: pedro.Suit.hearts,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                BidStatusWidget(
                  round: round,
                  targetScore: 35,
                  bidWinnerName: 'Alice',
                  bidWinnerPoints: 4,
                  isLocalBidWinner: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bid: 10'), findsOneWidget);
      expect(find.text('(Alice)'), findsOneWidget);
      expect(find.text('4 / 10 pts'), findsOneWidget);
      expect(find.text(' • Goal: 35'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('Renders (You) when local player is the bid winner',
        (tester) async {
      const round = RoundState(
        dealerId: 'dealer1',
        bidWinnerId: 'local_uid',
        phase: RoundPhase.playing,
        bidValue: 12,
        trumpSuit: pedro.Suit.spades,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                BidStatusWidget(
                  round: round,
                  targetScore: 35,
                  bidWinnerName: 'Bob',
                  bidWinnerPoints: 7,
                  isLocalBidWinner: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bid: 12'), findsOneWidget);
      expect(find.text('(You)'), findsOneWidget);
      expect(find.text('7 / 12 pts'), findsOneWidget);
      expect(find.byIcon(Icons.architecture), findsOneWidget);
    });

    testWidgets(
        'Shows checkmark and goal met styling when target points reached',
        (tester) async {
      const round = RoundState(
        dealerId: 'dealer1',
        bidWinnerId: 'player1',
        phase: RoundPhase.playing,
        bidValue: 10,
        trumpSuit: pedro.Suit.diamonds,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                BidStatusWidget(
                  round: round,
                  targetScore: 35,
                  bidWinnerName: 'Charlie',
                  bidWinnerPoints: 10,
                  isLocalBidWinner: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bid: 10'), findsOneWidget);
      expect(find.text('(Charlie)'), findsOneWidget);
      expect(find.text('10 / 10 pts'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });
  });
}
