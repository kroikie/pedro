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
  });
}
