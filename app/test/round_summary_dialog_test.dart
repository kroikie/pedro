import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart' as pedro;
import 'package:pedro/data/models/game_session.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/ui/widgets/round_summary_dialog.dart';

void main() {
  final player1 = const Player(id: 'p1', screenName: 'Alice');
  final player2 = const Player(id: 'p2', screenName: 'Bob');
  final playerCache = {'p1': player1, 'p2': player2};

  final sampleSummary = RoundSummary(
    roundNumber: 1,
    trumpSuit: pedro.Suit.hearts,
    bidWinnerId: 'p1',
    bidValue: 10,
    bidSuccess: true,
    highTrumpPlayerId: 'p1',
    highTrumpPlayedCard: const pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ace),
    lowTrumpPlayerId: 'p2',
    lowTrumpPlayedCard: const pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.two),
    gameWinnerId: 'p1',
    gameWinningScore: 24,
    isGameTied: false,
    playerSummaries: const [
      PlayerRoundSummary(
        uid: 'p1',
        roundPoints: 11,
        earnedPoints: ['High', 'Pedro (5)', 'Game'],
        totalScore: 11,
        gameValue: 24,
        wonLiftsCount: 4,
      ),
      PlayerRoundSummary(
        uid: 'p2',
        roundPoints: 1,
        earnedPoints: ['Low'],
        totalScore: 1,
        gameValue: 8,
        wonLiftsCount: 2,
      ),
    ],
  );

  testWidgets('RoundSummaryDialog displays contract, points, and triggers onContinue',
      (tester) async {
    bool continued = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundSummaryDialog(
            summary: sampleSummary,
            currentPlayerId: 'p1',
            playerCache: playerCache,
            onContinue: () {
              continued = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Round 1 Recap'), findsOneWidget);
    expect(find.text("Alice's Contract"), findsOneWidget);
    expect(find.text('MADE'), findsOneWidget);
    expect(find.text('High: '), findsOneWidget);
    expect(find.text('Low: '), findsOneWidget);
    expect(find.text('Game: '), findsOneWidget);
    expect(find.text('Alice (24 pts)'), findsOneWidget);
    expect(find.text('Player Standings'), findsOneWidget);
    expect(find.text('Sleeping Cards: '), findsNothing);

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(continued, isTrue);
  });

  testWidgets('RoundSummaryDialog displays sleeping cards when present',
      (tester) async {
    final summaryWithSleeping = RoundSummary(
      roundNumber: 2,
      trumpSuit: pedro.Suit.hearts,
      bidWinnerId: 'p1',
      bidValue: 8,
      bidSuccess: false,
      highTrumpPlayerId: 'p1',
      highTrumpPlayedCard: const pedro.Card(
        suit: pedro.Suit.hearts,
        rank: pedro.Rank.ace,
      ),
      lowTrumpPlayerId: 'p2',
      lowTrumpPlayedCard: const pedro.Card(
        suit: pedro.Suit.hearts,
        rank: pedro.Rank.two,
      ),
      gameWinnerId: 'p1',
      gameWinningScore: 20,
      isGameTied: false,
      playerSummaries: sampleSummary.playerSummaries,
      sleepingCards: const [
        pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.jack),
        pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.nine),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundSummaryDialog(
            summary: summaryWithSleeping,
            currentPlayerId: 'p1',
            playerCache: playerCache,
            onContinue: () {},
          ),
        ),
      ),
    );

    expect(find.text('Round 2 Recap'), findsOneWidget);
    expect(find.text('SET'), findsOneWidget);
    expect(find.text('Sleeping Cards: '), findsOneWidget);
    expect(find.text('Jack ♥'), findsOneWidget);
    expect(find.text('9 ♥'), findsOneWidget);
    expect(find.text('5 ♥'), findsNothing);
  });
}

