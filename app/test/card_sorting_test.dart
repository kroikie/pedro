import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/logic/card_sorting.dart';
import 'package:pedro/data/models/card.dart';

void main() {
  group('card_sorting tests', () {
    const cardClubs2 = Card(suit: Suit.clubs, rank: Rank.two);
    const cardClubs5 = Card(suit: Suit.clubs, rank: Rank.five);
    const cardClubsJack = Card(suit: Suit.clubs, rank: Rank.jack);
    const cardClubsAce = Card(suit: Suit.clubs, rank: Rank.ace);

    const cardDiamonds3 = Card(suit: Suit.diamonds, rank: Rank.three);
    const cardDiamonds10 = Card(suit: Suit.diamonds, rank: Rank.ten);
    const cardDiamondsKing = Card(suit: Suit.diamonds, rank: Rank.king);

    const cardSpades4 = Card(suit: Suit.spades, rank: Rank.four);
    const cardSpades9 = Card(suit: Suit.spades, rank: Rank.nine);
    const cardSpadesAce = Card(suit: Suit.spades, rank: Rank.ace);

    const cardHearts2 = Card(suit: Suit.hearts, rank: Rank.two);
    const cardHeartsQueen = Card(suit: Suit.hearts, rank: Rank.queen);

    test('returns empty list when input is empty', () {
      expect(sortHand([]), isEmpty);
    });

    test('returns single-item list without modification', () {
      final single = [cardHeartsQueen];
      final result = sortHand(single);
      expect(result, equals([cardHeartsQueen]));
      expect(identical(result, single), isFalse, reason: 'Must return a new list instance');
    });

    test('does not mutate the original list', () {
      final original = [cardSpadesAce, cardClubs2, cardDiamondsKing];
      final originalCopy = List<Card>.from(original);
      final sorted = sortHand(original);

      expect(original, equals(originalCopy));
      expect(sorted, isNot(equals(original)));
    });

    test('groups cards by default alternating suit order (Clubs -> Diamonds -> Spades -> Hearts)', () {
      final unsorted = [
        cardHeartsQueen,
        cardSpades4,
        cardDiamonds3,
        cardClubsJack,
      ];

      final sorted = sortHand(unsorted);

      expect(sorted, [
        cardClubsJack,
        cardDiamonds3,
        cardSpades4,
        cardHeartsQueen,
      ]);
    });

    test('orders cards within each suit from lowest rank (left) to highest rank (right)', () {
      final unsortedClubs = [
        cardClubsAce,
        cardClubs5,
        cardClubs2,
        cardClubsJack,
      ];

      final sorted = sortHand(unsortedClubs);

      expect(sorted, [
        cardClubs2,
        cardClubs5,
        cardClubsJack,
        cardClubsAce,
      ]);
    });

    test('correctly sorts mixed suits and mixed ranks into suit groups with ascending rank', () {
      final mixedHand = [
        cardHeartsQueen,
        cardSpadesAce,
        cardDiamondsKing,
        cardClubsJack,
        cardHearts2,
        cardClubs2,
        cardSpades4,
        cardDiamonds3,
        cardClubsAce,
        cardDiamonds10,
        cardSpades9,
        cardClubs5,
      ];

      final sorted = sortHand(mixedHand);

      expect(sorted, [
        // Clubs: 2, 5, J, A
        cardClubs2,
        cardClubs5,
        cardClubsJack,
        cardClubsAce,
        // Diamonds: 3, 10, K
        cardDiamonds3,
        cardDiamonds10,
        cardDiamondsKing,
        // Spades: 4, 9, A
        cardSpades4,
        cardSpades9,
        cardSpadesAce,
        // Hearts: 2, Q
        cardHearts2,
        cardHeartsQueen,
      ]);
    });

    test('handles hands void of certain suits cleanly', () {
      final handVoidOfDiamondsAndSpades = [
        cardHeartsQueen,
        cardClubsAce,
        cardHearts2,
        cardClubs2,
      ];

      final sorted = sortHand(handVoidOfDiamondsAndSpades);

      expect(sorted, [
        cardClubs2,
        cardClubsAce,
        cardHearts2,
        cardHeartsQueen,
      ]);
    });

    test('TrumpPosition.none keeps stable suit order regardless of trumpSuit', () {
      final hand = [
        cardHeartsQueen,
        cardSpades4,
        cardDiamonds3,
        cardClubs2,
      ];

      final sorted = sortHand(
        hand,
        trumpSuit: Suit.spades,
        trumpPosition: TrumpPosition.none,
      );

      expect(sorted, [
        cardClubs2,
        cardDiamonds3,
        cardSpades4,
        cardHeartsQueen,
      ]);
    });

    test('TrumpPosition.right shifts trump suit to the far right', () {
      final hand = [
        cardHeartsQueen,
        cardSpades4,
        cardDiamonds3,
        cardClubs2,
      ];

      final sorted = sortHand(
        hand,
        trumpSuit: Suit.diamonds,
        trumpPosition: TrumpPosition.right,
      );

      // Remaining suits in order: Clubs, Spades, Hearts; then Trump: Diamonds
      expect(sorted, [
        cardClubs2,
        cardSpades4,
        cardHeartsQueen,
        cardDiamonds3,
      ]);
    });

    test('TrumpPosition.left shifts trump suit to the far left', () {
      final hand = [
        cardHeartsQueen,
        cardSpades4,
        cardDiamonds3,
        cardClubs2,
      ];

      final sorted = sortHand(
        hand,
        trumpSuit: Suit.hearts,
        trumpPosition: TrumpPosition.left,
      );

      // Trump: Hearts first, then remaining: Clubs, Diamonds, Spades
      expect(sorted, [
        cardHeartsQueen,
        cardClubs2,
        cardDiamonds3,
        cardSpades4,
      ]);
    });

    test('CardSortingX extension sortedHand works identically to sortHand', () {
      final hand = [
        cardHeartsQueen,
        cardClubsAce,
        cardHearts2,
        cardClubs2,
      ];

      final sorted = hand.sortedHand();

      expect(sorted, [
        cardClubs2,
        cardClubsAce,
        cardHearts2,
        cardHeartsQueen,
      ]);
    });
  });
}
