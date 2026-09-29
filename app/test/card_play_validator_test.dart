import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/logic/card_play_validator.dart';
import 'package:pedro/data/models/card.dart';
import 'package:pedro/data/models/game_session.dart';

void main() {
  group('validateCardPlay', () {
    const trumpSuit = Suit.diamonds;
    const cardHeartsAce = Card(suit: Suit.hearts, rank: Rank.ace);
    const cardHeartsTen = Card(suit: Suit.hearts, rank: Rank.ten);
    const cardDiamondsNine = Card(suit: Suit.diamonds, rank: Rank.nine);
    const cardSpadesFive = Card(suit: Suit.spades, rank: Rank.five);
    const cardClubsKing = Card(suit: Suit.clubs, rank: Rank.king);

    final handWithHeartsAndTrump = [
      cardHeartsTen,
      cardDiamondsNine,
      cardSpadesFive,
    ];

    final handVoidOfHearts = [
      cardDiamondsNine,
      cardSpadesFive,
      cardClubsKing,
    ];

    test('rejects when not in playing phase', () {
      final result = validateCardPlay(
        card: cardHeartsTen,
        hand: handWithHeartsAndTrump,
        currentLift: null,
        trumpSuit: trumpSuit,
        phase: RoundPhase.wadger,
        isMyTurn: true,
      );
      expect(result.isLegal, isFalse);
      expect(result.reason, 'Not in playing phase.');
    });

    test('rejects when not player turn', () {
      final result = validateCardPlay(
        card: cardHeartsTen,
        hand: handWithHeartsAndTrump,
        currentLift: null,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: false,
      );
      expect(result.isLegal, isFalse);
      expect(result.reason, 'Not your turn.');
    });

    test('rejects when card is not in player hand', () {
      final result = validateCardPlay(
        card: cardHeartsAce,
        hand: handWithHeartsAndTrump,
        currentLift: null,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: true,
      );
      expect(result.isLegal, isFalse);
      expect(result.reason, 'Card not in hand.');
    });

    test('allows leading any card in hand when current lift has no plays', () {
      const lift = Lift(leadPlayerId: 'p1', plays: {});
      final result = validateCardPlay(
        card: cardSpadesFive,
        hand: handWithHeartsAndTrump,
        currentLift: lift,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: true,
      );
      expect(result.isLegal, isTrue);
      expect(result.reason, isNull);
    });

    test('allows following lead suit when holding it', () {
      const lift = Lift(
        leadPlayerId: 'p1',
        plays: {'p1': cardHeartsAce},
      );
      final result = validateCardPlay(
        card: cardHeartsTen,
        hand: handWithHeartsAndTrump,
        currentLift: lift,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: true,
      );
      expect(result.isLegal, isTrue);
      expect(result.reason, isNull);
    });

    test('allows playing trump when holding lead suit (trumping)', () {
      const lift = Lift(
        leadPlayerId: 'p1',
        plays: {'p1': cardHeartsAce},
      );
      final result = validateCardPlay(
        card: cardDiamondsNine, // Trump
        hand: handWithHeartsAndTrump,
        currentLift: lift,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: true,
      );
      expect(result.isLegal, isTrue);
      expect(result.reason, isNull);
    });

    test('rejects playing off-suit non-trump when holding lead suit', () {
      const lift = Lift(
        leadPlayerId: 'p1',
        plays: {'p1': cardHeartsAce},
      );
      final result = validateCardPlay(
        card: cardSpadesFive, // Off-suit non-trump while holding heartsTen
        hand: handWithHeartsAndTrump,
        currentLift: lift,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: true,
      );
      expect(result.isLegal, isFalse);
      expect(result.reason, 'Must follow suit (hearts) or play Trump.');
    });

    test('allows playing off-suit non-trump when void of lead suit', () {
      const lift = Lift(
        leadPlayerId: 'p1',
        plays: {'p1': cardHeartsAce},
      );
      final result = validateCardPlay(
        card: cardSpadesFive, // Void of hearts
        hand: handVoidOfHearts,
        currentLift: lift,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: true,
      );
      expect(result.isLegal, isTrue);
      expect(result.reason, isNull);
    });

    test(
        'allows leading any card in hand when current lift has winnerId (completed lift)',
        () {
      // Even though heartsAce was played in the completed lift, the winner can lead any card (e.g. spades)
      const completedLift = Lift(
        leadPlayerId: 'p1',
        plays: {
          'p1': cardHeartsAce,
          'p2': cardHeartsTen,
        },
        winnerId: 'p1',
      );
      final result = validateCardPlay(
        card: cardSpadesFive, // Leading a new trick with spades
        hand: handWithHeartsAndTrump,
        currentLift: completedLift,
        trumpSuit: trumpSuit,
        phase: RoundPhase.playing,
        isMyTurn: true,
      );
      expect(result.isLegal, isTrue);
      expect(result.reason, isNull);
    });
  });

  group('getOrderedLiftPlays', () {
    const cardHeartsAce = Card(suit: Suit.hearts, rank: Rank.ace);
    const cardHeartsJack = Card(suit: Suit.hearts, rank: Rank.jack);
    const cardHeartsEight = Card(suit: Suit.hearts, rank: Rank.eight);
    const cardDiamondsNine = Card(suit: Suit.diamonds, rank: Rank.nine);

    final playerStates = [
      const PlayerGameState(uid: 'arthur', hand: []),
      const PlayerGameState(uid: 'gavy', hand: []),
      const PlayerGameState(uid: 'dona', hand: []),
      const PlayerGameState(uid: 'kimoy', hand: []),
    ];

    test('returns empty list when lift has no plays', () {
      const lift = Lift(leadPlayerId: 'gavy', plays: {});
      final result = getOrderedLiftPlays(
        lift: lift,
        playerStates: playerStates,
      );
      expect(result, isEmpty);
    });

    test(
        'orders plays starting with lead player followed by clockwise seating order',
        () {
      // Gavy is lead player; plays are in map in arbitrary order
      const lift = Lift(
        leadPlayerId: 'gavy',
        plays: {
          'kimoy': cardHeartsEight,
          'gavy': cardDiamondsNine,
          'dona': cardHeartsJack,
        },
      );

      final result = getOrderedLiftPlays(
        lift: lift,
        playerStates: playerStates,
      );

      // Order should strictly be: Gavy (lead), Dona (next in clockwise), Kimoy (next in clockwise)
      expect(result.length, 3);
      expect(result[0].key, 'gavy');
      expect(result[0].value, cardDiamondsNine);
      expect(result[1].key, 'dona');
      expect(result[1].value, cardHeartsJack);
      expect(result[2].key, 'kimoy');
      expect(result[2].value, cardHeartsEight);
    });

    test('handles all 4 players having played starting from non-zero lead index',
        () {
      const lift = Lift(
        leadPlayerId: 'dona',
        plays: {
          'arthur': cardHeartsAce,
          'gavy': cardDiamondsNine,
          'dona': cardHeartsJack,
          'kimoy': cardHeartsEight,
        },
      );

      final result = getOrderedLiftPlays(
        lift: lift,
        playerStates: playerStates,
      );

      expect(result.map((e) => e.key).toList(), [
        'dona',
        'kimoy',
        'arthur',
        'gavy',
      ]);
    });

    test('handles single card played by lead player', () {
      const lift = Lift(
        leadPlayerId: 'gavy',
        plays: {'gavy': cardDiamondsNine},
      );

      final result = getOrderedLiftPlays(
        lift: lift,
        playerStates: playerStates,
      );

      expect(result.length, 1);
      expect(result.first.key, 'gavy');
      expect(result.first.value, cardDiamondsNine);
    });

    test('fallback when lead player is not found in playerStates', () {
      const lift = Lift(
        leadPlayerId: 'unknown_lead',
        plays: {
          'other': cardHeartsAce,
          'unknown_lead': cardDiamondsNine,
        },
      );

      final result = getOrderedLiftPlays(
        lift: lift,
        playerStates: playerStates,
      );

      expect(result.first.key, 'unknown_lead');
      expect(result.first.value, cardDiamondsNine);
    });
  });
}
