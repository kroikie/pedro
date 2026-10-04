import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/logic/game_point_helper.dart';
import 'package:pedro/data/models/card.dart';

void main() {
  group('Game Point Helper', () {
    test('getCardGameValue returns accurate Pedro game values', () {
      expect(getCardGameValue(const Card(suit: Suit.hearts, rank: Rank.ten)), 10);
      expect(getCardGameValue(const Card(suit: Suit.spades, rank: Rank.ace)), 4);
      expect(getCardGameValue(const Card(suit: Suit.diamonds, rank: Rank.king)), 3);
      expect(getCardGameValue(const Card(suit: Suit.clubs, rank: Rank.queen)), 2);
      expect(getCardGameValue(const Card(suit: Suit.hearts, rank: Rank.jack)), 1);

      // Non-value cards
      expect(getCardGameValue(const Card(suit: Suit.hearts, rank: Rank.five)), 0);
      expect(getCardGameValue(const Card(suit: Suit.spades, rank: Rank.nine)), 0);
      expect(getCardGameValue(const Card(suit: Suit.clubs, rank: Rank.two)), 0);
      expect(getCardGameValue(const Card(suit: Suit.diamonds, rank: Rank.eight)), 0);
    });

    test('calculateGameTotal sums game values accurately', () {
      final cards = [
        const Card(suit: Suit.hearts, rank: Rank.ten), // 10
        const Card(suit: Suit.diamonds, rank: Rank.ace), // 4
        const Card(suit: Suit.spades, rank: Rank.king), // 3
        const Card(suit: Suit.clubs, rank: Rank.queen), // 2
        const Card(suit: Suit.hearts, rank: Rank.jack), // 1
        const Card(suit: Suit.hearts, rank: Rank.five), // 0
      ];

      expect(calculateGameTotal(cards), 20);
    });

    test('calculateGameTotal returns 0 for empty list or cards with no value', () {
      expect(calculateGameTotal([]), 0);
      expect(
        calculateGameTotal([
          const Card(suit: Suit.spades, rank: Rank.two),
          const Card(suit: Suit.hearts, rank: Rank.three),
        ]),
        0,
      );
    });
  });
}
