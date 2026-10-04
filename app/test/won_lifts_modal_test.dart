import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart' as pedro;
import 'package:pedro/data/models/game_session.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/ui/widgets/won_lifts_modal.dart';

void main() {
  final player1 = const Player(id: 'p1', screenName: 'Alice');
  final player2 = const Player(id: 'p2', screenName: 'Bob');
  final playerCache = {'p1': player1, 'p2': player2};

  final sampleLift = Lift(
    leadPlayerId: 'p1',
    winnerId: 'p1',
    plays: {
      'p1': const pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.ten),
      'p2': const pedro.Card(suit: pedro.Suit.hearts, rank: pedro.Rank.five),
    },
  );

  testWidgets('WonLiftsModal displays own won lifts with cards and game value',
      (tester) async {
    final session = GameSession(
      gameId: 'game1',
      playerStates: const [
        PlayerGameState(uid: 'p1', hand: []),
        PlayerGameState(uid: 'p2', hand: []),
      ],
      currentRound: RoundState(
        dealerId: 'p2',
        phase: RoundPhase.playing,
        completedLifts: [sampleLift],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WonLiftsModal(
            session: session,
            targetPlayerId: 'p1',
            currentPlayerId: 'p1',
            playerCache: playerCache,
          ),
        ),
      ),
    );

    expect(find.text('Your Won Lifts'), findsOneWidget);
    expect(find.text('1 lift won this round'), findsOneWidget);
    expect(find.text('Lift #1'), findsOneWidget);
    expect(find.text('+10 Game pts'), findsOneWidget);
  });

  testWidgets(
      'WonLiftsModal displays etiquette privacy notice for opponent lifts during active play',
      (tester) async {
    final session = GameSession(
      gameId: 'game1',
      playerStates: const [
        PlayerGameState(uid: 'p1', hand: []),
        PlayerGameState(uid: 'p2', hand: []),
      ],
      currentRound: RoundState(
        dealerId: 'p1',
        phase: RoundPhase.playing,
        completedLifts: [sampleLift],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WonLiftsModal(
            session: session,
            targetPlayerId: 'p1',
            currentPlayerId: 'p2', // Bob inspecting Alice's lifts
            playerCache: playerCache,
          ),
        ),
      ),
    );

    expect(find.text("Alice's Won Lifts"), findsOneWidget);
    expect(find.text('Face-Down Etiquette'), findsOneWidget);
    expect(find.textContaining('opponents\' captured tricks remain face down'),
        findsOneWidget);
    expect(find.text('1 won lift'), findsOneWidget);
  });

  testWidgets(
      'WonLiftsModal displays opponent cards when round is finished',
      (tester) async {
    final session = GameSession(
      gameId: 'game1',
      playerStates: const [
        PlayerGameState(uid: 'p1', hand: []),
        PlayerGameState(uid: 'p2', hand: []),
      ],
      currentRound: RoundState(
        dealerId: 'p1',
        phase: RoundPhase.finished,
        completedLifts: [sampleLift],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WonLiftsModal(
            session: session,
            targetPlayerId: 'p1',
            currentPlayerId: 'p2', // Bob inspecting Alice's lifts after round finished
            playerCache: playerCache,
          ),
        ),
      ),
    );

    expect(find.text("Alice's Won Lifts"), findsOneWidget);
    expect(find.text('Face-Down Etiquette'), findsNothing);
    expect(find.text('Lift #1'), findsOneWidget);
    expect(find.text('+10 Game pts'), findsOneWidget);
  });
}
