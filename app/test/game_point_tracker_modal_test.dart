import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart' as pedro;
import 'package:pedro/data/models/game_session.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/ui/widgets/game_point_tracker_modal.dart';

void main() {
  final player1 = const Player(id: 'p1', screenName: 'Alice');
  final player2 = const Player(id: 'p2', screenName: 'Bob');
  final playerCache = {'p1': player1, 'p2': player2};

  testWidgets('GamePointTrackerModal displays leaderboard and crown for leader',
      (tester) async {
    final session = GameSession(
      gameId: 'game1',
      playerStates: const [
        PlayerGameState(
          uid: 'p1',
          hand: [],
          gameValue: 14,
          capturedValueCards: [
            pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ten),
            pedro.Card(suit: pedro.Suit.spades, rank: pedro.Rank.ace),
          ],
        ),
        PlayerGameState(
          uid: 'p2',
          hand: [],
          gameValue: 6,
          capturedValueCards: [
            pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.king),
            pedro.Card(suit: pedro.Suit.clubs, rank: pedro.Rank.king),
          ],
        ),
      ],
      currentRound: const RoundState(
        dealerId: 'p2',
        phase: RoundPhase.playing,
        gamePointLeaderId: 'p1',
        gamePointLeaderValue: 14,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GamePointTrackerModal(
            session: session,
            currentPlayerId: 'p1',
            playerCache: playerCache,
          ),
        ),
      ),
    );

    expect(find.text('Game Point Race'), findsOneWidget);
    expect(find.text('Captured: 20 / 80 pts'), findsOneWidget);
    expect(find.text('Leader: 14 pts'), findsOneWidget);
    expect(find.text('14 pts'), findsOneWidget);
    expect(find.text('6 pts'), findsOneWidget);
    expect(find.text('👑'), findsOneWidget);
    expect(find.text('Leading Game point'), findsOneWidget);
    expect(find.text('(You)'), findsOneWidget);
  });
}
