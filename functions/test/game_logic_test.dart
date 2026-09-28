import 'package:functions/game/deck.dart';
import 'package:functions/game/logic.dart';
import 'package:test/test.dart';

void main() {
  group('Deck & Cards', () {
    test('createDeck creates standard 52-card deck', () {
      final deck = createDeck();
      expect(deck.length, 52);

      for (final suit in Suit.values) {
        final cardsInSuit = deck.where((c) => c.suit == suit);
        expect(cardsInSuit.length, 13);
      }
    });

    test('Card json serialization and deserialization', () {
      final card = Card(suit: Suit.hearts, rank: Rank.ace);
      final json = card.toJson();
      expect(json, {'suit': 'hearts', 'rank': 'ace'});

      final fromJson = Card.fromJson(json);
      expect(fromJson.suit, Suit.hearts);
      expect(fromJson.rank, Rank.ace);
      expect(fromJson.toString(), 'ace of hearts');
    });

    test('shuffle preserves total count and elements', () {
      final deck = createDeck();
      final shuffled = shuffle(deck);
      expect(shuffled.length, deck.length);
      expect(shuffled.toSet().length, deck.length);
    });
  });

  group('Lift Winner Evaluation', () {
    test('lead suit highest card wins when no trumps played', () {
      final winner = evaluateLiftWinner(
        plays: {
          'p1': Card(suit: Suit.clubs, rank: Rank.ten),
          'p2': Card(suit: Suit.clubs, rank: Rank.king),
          'p3': Card(suit: Suit.hearts, rank: Rank.ace),
          'p4': Card(suit: Suit.clubs, rank: Rank.seven),
        },
        leadSuit: Suit.clubs,
        trumpSuit: Suit.spades,
      );
      expect(winner, 'p2');
    });

    test('trump card beats any non-trump lead card', () {
      final winner = evaluateLiftWinner(
        plays: {
          'p1': Card(suit: Suit.clubs, rank: Rank.ace),
          'p2': Card(suit: Suit.spades, rank: Rank.two),
          'p3': Card(suit: Suit.clubs, rank: Rank.king),
          'p4': Card(suit: Suit.clubs, rank: Rank.three),
        },
        leadSuit: Suit.clubs,
        trumpSuit: Suit.spades,
      );
      expect(winner, 'p2');
    });

    test('higher trump beats lower trump', () {
      final winner = evaluateLiftWinner(
        plays: {
          'p1': Card(suit: Suit.clubs, rank: Rank.ace),
          'p2': Card(suit: Suit.spades, rank: Rank.two),
          'p3': Card(suit: Suit.spades, rank: Rank.jack),
          'p4': Card(suit: Suit.spades, rank: Rank.five),
        },
        leadSuit: Suit.clubs,
        trumpSuit: Suit.spades,
      );
      expect(winner, 'p3');
    });

    test('off-suit card cannot win over lead card', () {
      final winner = evaluateLiftWinner(
        plays: {
          'p1': Card(suit: Suit.clubs, rank: Rank.two),
          'p2': Card(suit: Suit.diamonds, rank: Rank.ace),
          'p3': Card(suit: Suit.hearts, rank: Rank.king),
        },
        leadSuit: Suit.clubs,
        trumpSuit: Suit.spades,
      );
      expect(winner, 'p1');
    });
  });
}
