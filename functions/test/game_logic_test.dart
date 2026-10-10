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

    test('ace of trumps beats nine and five of trumps', () {
      final winner = evaluateLiftWinner(
        plays: {
          'p1': Card(suit: Suit.diamonds, rank: Rank.ace),
          'p2': Card(suit: Suit.diamonds, rank: Rank.five),
          'p3': Card(suit: Suit.diamonds, rank: Rank.nine),
          'p4': Card(suit: Suit.diamonds, rank: Rank.king),
        },
        leadSuit: Suit.diamonds,
        trumpSuit: Suit.diamonds,
      );
      expect(winner, 'p1');
    });
  });

  group('Lift Card Play Validation (Follow Suit & Under Trump)', () {
    const trumpSuit = Suit.spades;

    test('rejects off-suit non-trump when player holds lead suit', () {
      final error = validateLiftCardPlay(
        card: Card(suit: Suit.hearts, rank: Rank.four),
        hand: [
          Card(suit: Suit.hearts, rank: Rank.four),
          Card(suit: Suit.clubs, rank: Rank.seven),
        ],
        currentPlays: {
          'p1': Card(suit: Suit.clubs, rank: Rank.ten),
        },
        leadSuit: Suit.clubs,
        trumpSuit: trumpSuit,
      );
      expect(error, 'Must follow suit (clubs) or play Trump.');
    });

    test('rejects under-trump when non-trump suit was led and player holds non-trump cards', () {
      // P1 leads 10 of clubs, P2 plays 3 of clubs, P3 plays 5 of trump (spades), P4 plays 2 of trump
      final currentPlays = {
        'p1': Card(suit: Suit.clubs, rank: Rank.ten),
        'p2': Card(suit: Suit.clubs, rank: Rank.three),
        'p3': Card(suit: Suit.spades, rank: Rank.five),
      };

      final errorWithOffSuit = validateLiftCardPlay(
        card: Card(suit: Suit.spades, rank: Rank.two),
        hand: [
          Card(suit: Suit.spades, rank: Rank.two),
          Card(suit: Suit.hearts, rank: Rank.eight),
        ],
        currentPlays: currentPlays,
        leadSuit: Suit.clubs,
        trumpSuit: trumpSuit,
      );
      expect(
        errorWithOffSuit,
        'Cannot under-trump (five of spades) while holding non-trump cards.',
      );

      final errorWithLeadSuit = validateLiftCardPlay(
        card: Card(suit: Suit.spades, rank: Rank.two),
        hand: [
          Card(suit: Suit.spades, rank: Rank.two),
          Card(suit: Suit.clubs, rank: Rank.eight),
        ],
        currentPlays: currentPlays,
        leadSuit: Suit.clubs,
        trumpSuit: trumpSuit,
      );
      expect(
        errorWithLeadSuit,
        'Cannot under-trump (five of spades) while holding non-trump cards.',
      );
    });

    test('allows under-trump when player only has trump cards left in hand', () {
      final currentPlays = {
        'p1': Card(suit: Suit.clubs, rank: Rank.ten),
        'p2': Card(suit: Suit.clubs, rank: Rank.three),
        'p3': Card(suit: Suit.spades, rank: Rank.five),
      };

      final error = validateLiftCardPlay(
        card: Card(suit: Suit.spades, rank: Rank.two),
        hand: [
          Card(suit: Suit.spades, rank: Rank.two),
          Card(suit: Suit.spades, rank: Rank.king),
        ],
        currentPlays: currentPlays,
        leadSuit: Suit.clubs,
        trumpSuit: trumpSuit,
      );
      expect(error, isNull);
    });

    test('allows over-trumping when holding non-trump cards', () {
      final currentPlays = {
        'p1': Card(suit: Suit.clubs, rank: Rank.ten),
        'p2': Card(suit: Suit.clubs, rank: Rank.three),
        'p3': Card(suit: Suit.spades, rank: Rank.five),
      };

      final error = validateLiftCardPlay(
        card: Card(suit: Suit.spades, rank: Rank.nine),
        hand: [
          Card(suit: Suit.spades, rank: Rank.nine),
          Card(suit: Suit.clubs, rank: Rank.seven),
        ],
        currentPlays: currentPlays,
        leadSuit: Suit.clubs,
        trumpSuit: trumpSuit,
      );
      expect(error, isNull);
    });

    test('requires beating the highest trump when multiple trumps are played in a lift', () {
      final currentPlays = {
        'p1': Card(suit: Suit.clubs, rank: Rank.ten),
        'p2': Card(suit: Suit.spades, rank: Rank.five),
        'p3': Card(suit: Suit.spades, rank: Rank.nine),
      };

      final error = validateLiftCardPlay(
        card: Card(suit: Suit.spades, rank: Rank.seven),
        hand: [
          Card(suit: Suit.spades, rank: Rank.seven),
          Card(suit: Suit.diamonds, rank: Rank.four),
        ],
        currentPlays: currentPlays,
        leadSuit: Suit.clubs,
        trumpSuit: trumpSuit,
      );
      expect(
        error,
        'Cannot under-trump (nine of spades) while holding non-trump cards.',
      );
    });

    test('allows playing a lower trump when trump is the lead suit', () {
      final currentPlays = {
        'p1': Card(suit: Suit.spades, rank: Rank.ten),
      };

      final error = validateLiftCardPlay(
        card: Card(suit: Suit.spades, rank: Rank.two),
        hand: [
          Card(suit: Suit.spades, rank: Rank.two),
          Card(suit: Suit.clubs, rank: Rank.ace),
        ],
        currentPlays: currentPlays,
        leadSuit: Suit.spades,
        trumpSuit: trumpSuit,
      );
      expect(error, isNull);
    });
  });

  group('High & Low Trump Evaluation', () {
    const trump = Suit.hearts;

    test('non-trump card does not change high or low', () {
      final result = evaluateHighLowTrump(
        playedCard: Card(suit: Suit.spades, rank: Rank.ace),
        trumpSuit: trump,
        playerId: 'p1',
        currentHighCard: null,
        currentHighPlayerId: null,
        currentLowCard: null,
        currentLowPlayerId: null,
      );
      expect(result.highChanged, isFalse);
      expect(result.lowChanged, isFalse);
    });

    test('first trump played becomes both High and Low till higher/lower comes', () {
      final card = Card(suit: trump, rank: Rank.seven);
      final result = evaluateHighLowTrump(
        playedCard: card,
        trumpSuit: trump,
        playerId: 'p1',
        currentHighCard: null,
        currentHighPlayerId: null,
        currentLowCard: null,
        currentLowPlayerId: null,
      );
      expect(result.highChanged, isTrue);
      expect(result.oldHighPlayerId, isNull);
      expect(result.newHighPlayerId, 'p1');
      expect(result.newHighCard?.rank, Rank.seven);
      expect(result.isHighSafe, isFalse);

      expect(result.lowChanged, isTrue);
      expect(result.oldLowPlayerId, isNull);
      expect(result.newLowPlayerId, 'p1');
      expect(result.newLowCard?.rank, Rank.seven);
      expect(result.isLowSafe, isFalse);
    });

    test('first trump played as Ace is marked safe for High', () {
      final card = Card(suit: trump, rank: Rank.ace);
      final result = evaluateHighLowTrump(
        playedCard: card,
        trumpSuit: trump,
        playerId: 'p1',
        currentHighCard: null,
        currentHighPlayerId: null,
        currentLowCard: null,
        currentLowPlayerId: null,
      );
      expect(result.highChanged, isTrue);
      expect(result.isHighSafe, isTrue);
      expect(result.lowChanged, isTrue);
      expect(result.isLowSafe, isFalse);
    });

    test('first trump played as 2 is marked safe for Low', () {
      final card = Card(suit: trump, rank: Rank.two);
      final result = evaluateHighLowTrump(
        playedCard: card,
        trumpSuit: trump,
        playerId: 'p1',
        currentHighCard: null,
        currentHighPlayerId: null,
        currentLowCard: null,
        currentLowPlayerId: null,
      );
      expect(result.highChanged, isTrue);
      expect(result.isHighSafe, isFalse);
      expect(result.lowChanged, isTrue);
      expect(result.isLowSafe, isTrue);
    });

    test('higher trump beats current high across lifts', () {
      final currentHigh = Card(suit: trump, rank: Rank.eight);
      final currentLow = Card(suit: trump, rank: Rank.five);
      final played = Card(suit: trump, rank: Rank.jack);

      final result = evaluateHighLowTrump(
        playedCard: played,
        trumpSuit: trump,
        playerId: 'p2',
        currentHighCard: currentHigh,
        currentHighPlayerId: 'p1',
        currentLowCard: currentLow,
        currentLowPlayerId: 'p1',
      );
      expect(result.highChanged, isTrue);
      expect(result.oldHighPlayerId, 'p1');
      expect(result.newHighPlayerId, 'p2');
      expect(result.newHighCard?.rank, Rank.jack);
      expect(result.lowChanged, isFalse);
    });

    test('lower trump beats current low across lifts', () {
      final currentHigh = Card(suit: trump, rank: Rank.king);
      final currentLow = Card(suit: trump, rank: Rank.four);
      final played = Card(suit: trump, rank: Rank.three);

      final result = evaluateHighLowTrump(
        playedCard: played,
        trumpSuit: trump,
        playerId: 'p3',
        currentHighCard: currentHigh,
        currentHighPlayerId: 'p1',
        currentLowCard: currentLow,
        currentLowPlayerId: 'p2',
      );
      expect(result.lowChanged, isTrue);
      expect(result.oldLowPlayerId, 'p2');
      expect(result.newLowPlayerId, 'p3');
      expect(result.newLowCard?.rank, Rank.three);
      expect(result.highChanged, isFalse);
    });

    test('intermediate trump changes neither high nor low', () {
      final currentHigh = Card(suit: trump, rank: Rank.queen);
      final currentLow = Card(suit: trump, rank: Rank.four);
      final played = Card(suit: trump, rank: Rank.eight);

      final result = evaluateHighLowTrump(
        playedCard: played,
        trumpSuit: trump,
        playerId: 'p4',
        currentHighCard: currentHigh,
        currentHighPlayerId: 'p1',
        currentLowCard: currentLow,
        currentLowPlayerId: 'p2',
      );
      expect(result.highChanged, isFalse);
      expect(result.lowChanged, isFalse);
    });

    test('same player improving own high trump preserves identity', () {
      final currentHigh = Card(suit: trump, rank: Rank.ten);
      final played = Card(suit: trump, rank: Rank.ace);

      final result = evaluateHighLowTrump(
        playedCard: played,
        trumpSuit: trump,
        playerId: 'p1',
        currentHighCard: currentHigh,
        currentHighPlayerId: 'p1',
        currentLowCard: Card(suit: trump, rank: Rank.two),
        currentLowPlayerId: 'p2',
      );
      expect(result.highChanged, isTrue);
      expect(result.oldHighPlayerId, 'p1');
      expect(result.newHighPlayerId, 'p1');
      expect(result.isHighSafe, isTrue);
      expect(result.lowChanged, isFalse);
    });

    test('multi-lift progression maintains High and Low across distinct lifts', () {
      Card? roundHighCard;
      String? roundHighPlayerId;
      Card? roundLowCard;
      String? roundLowPlayerId;

      // Lift 1, Play 1: P1 plays 7 of hearts
      var r = evaluateHighLowTrump(
        playedCard: Card(suit: trump, rank: Rank.seven),
        trumpSuit: trump,
        playerId: 'p1',
        currentHighCard: roundHighCard,
        currentHighPlayerId: roundHighPlayerId,
        currentLowCard: roundLowCard,
        currentLowPlayerId: roundLowPlayerId,
      );
      roundHighCard = r.newHighCard;
      roundHighPlayerId = r.newHighPlayerId;
      roundLowCard = r.newLowCard;
      roundLowPlayerId = r.newLowPlayerId;
      expect(roundHighPlayerId, 'p1');
      expect(roundLowPlayerId, 'p1');

      // Lift 1, Play 2: P2 plays 10 of hearts
      r = evaluateHighLowTrump(
        playedCard: Card(suit: trump, rank: Rank.ten),
        trumpSuit: trump,
        playerId: 'p2',
        currentHighCard: roundHighCard,
        currentHighPlayerId: roundHighPlayerId,
        currentLowCard: roundLowCard,
        currentLowPlayerId: roundLowPlayerId,
      );
      if (r.highChanged) {
        roundHighCard = r.newHighCard;
        roundHighPlayerId = r.newHighPlayerId;
      }
      if (r.lowChanged) {
        roundLowCard = r.newLowCard;
        roundLowPlayerId = r.newLowPlayerId;
      }
      expect(roundHighPlayerId, 'p2');
      expect(roundLowPlayerId, 'p1');

      // Lift 2, Play 1: P3 plays 3 of hearts (Low transfers to P3, P2 keeps High!)
      r = evaluateHighLowTrump(
        playedCard: Card(suit: trump, rank: Rank.three),
        trumpSuit: trump,
        playerId: 'p3',
        currentHighCard: roundHighCard,
        currentHighPlayerId: roundHighPlayerId,
        currentLowCard: roundLowCard,
        currentLowPlayerId: roundLowPlayerId,
      );
      if (r.highChanged) {
        roundHighCard = r.newHighCard;
        roundHighPlayerId = r.newHighPlayerId;
      }
      if (r.lowChanged) {
        roundLowCard = r.newLowCard;
        roundLowPlayerId = r.newLowPlayerId;
      }
      expect(roundHighPlayerId, 'p2');
      expect(roundLowPlayerId, 'p3');

      // Lift 3, Play 1: P4 plays Ace of hearts (High transfers to P4, P3 keeps Low!)
      r = evaluateHighLowTrump(
        playedCard: Card(suit: trump, rank: Rank.ace),
        trumpSuit: trump,
        playerId: 'p4',
        currentHighCard: roundHighCard,
        currentHighPlayerId: roundHighPlayerId,
        currentLowCard: roundLowCard,
        currentLowPlayerId: roundLowPlayerId,
      );
      if (r.highChanged) {
        roundHighCard = r.newHighCard;
        roundHighPlayerId = r.newHighPlayerId;
      }
      if (r.lowChanged) {
        roundLowCard = r.newLowCard;
        roundLowPlayerId = r.newLowPlayerId;
      }
      expect(roundHighPlayerId, 'p4');
      expect(r.isHighSafe, isTrue);
      expect(roundLowPlayerId, 'p3');

      // Lift 4, Play 1: P1 plays 2 of hearts (Low transfers to P1, P4 keeps High!)
      r = evaluateHighLowTrump(
        playedCard: Card(suit: trump, rank: Rank.two),
        trumpSuit: trump,
        playerId: 'p1',
        currentHighCard: roundHighCard,
        currentHighPlayerId: roundHighPlayerId,
        currentLowCard: roundLowCard,
        currentLowPlayerId: roundLowPlayerId,
      );
      if (r.highChanged) {
        roundHighCard = r.newHighCard;
        roundHighPlayerId = r.newHighPlayerId;
      }
      if (r.lowChanged) {
        roundLowCard = r.newLowCard;
        roundLowPlayerId = r.newLowPlayerId;
      }
      expect(roundHighPlayerId, 'p4');
      expect(roundLowPlayerId, 'p1');
      expect(r.isLowSafe, isTrue);

      // Lift 5: Non-trump cards played -> High and Low remain sealed
      r = evaluateHighLowTrump(
        playedCard: Card(suit: Suit.clubs, rank: Rank.king),
        trumpSuit: trump,
        playerId: 'p2',
        currentHighCard: roundHighCard,
        currentHighPlayerId: roundHighPlayerId,
        currentLowCard: roundLowCard,
        currentLowPlayerId: roundLowPlayerId,
      );
      expect(r.highChanged, isFalse);
      expect(r.lowChanged, isFalse);
      expect(roundHighPlayerId, 'p4');
      expect(roundLowPlayerId, 'p1');
    });
  });

  group('Game Point & Value Cards Logic', () {
    test('getCardGameValue correctly values Pedro game cards', () {
      expect(getCardGameValue(Card(suit: Suit.hearts, rank: Rank.ten)), 10);
      expect(getCardGameValue(Card(suit: Suit.spades, rank: Rank.ace)), 4);
      expect(getCardGameValue(Card(suit: Suit.diamonds, rank: Rank.king)), 3);
      expect(getCardGameValue(Card(suit: Suit.clubs, rank: Rank.queen)), 2);
      expect(getCardGameValue(Card(suit: Suit.hearts, rank: Rank.jack)), 1);

      // Non-value cards must yield 0
      expect(getCardGameValue(Card(suit: Suit.hearts, rank: Rank.nine)), 0);
      expect(getCardGameValue(Card(suit: Suit.hearts, rank: Rank.five)), 0);
      expect(getCardGameValue(Card(suit: Suit.hearts, rank: Rank.two)), 0);
      expect(getCardGameValue(Card(suit: Suit.clubs, rank: Rank.seven)), 0);
    });

    test('calculateGameTotal sums total card value in hand or captured lifts', () {
      final cards = [
        Card(suit: Suit.hearts, rank: Rank.ten), // 10
        Card(suit: Suit.spades, rank: Rank.ace), // 4
        Card(suit: Suit.clubs, rank: Rank.king), // 3
        Card(suit: Suit.diamonds, rank: Rank.nine), // 0
        Card(suit: Suit.hearts, rank: Rank.five), // 0
      ];
      expect(calculateGameTotal(cards), 17);
    });

    test('evaluateGamePointLeader returns unique highest player', () {
      final playerStates = [
        {'uid': 'p1', 'gameValue': 14},
        {'uid': 'p2', 'gameValue': 11},
        {'uid': 'p3', 'gameValue': 0},
        {'uid': 'p4', 'gameValue': 4},
      ];
      final leader = evaluateGamePointLeader(playerStates);
      expect(leader.leaderUid, 'p1');
      expect(leader.highestValue, 14);
      expect(leader.isTied, isFalse);
    });

    test('evaluateGamePointLeader returns null leaderUid when tied', () {
      final playerStates = [
        {'uid': 'p1', 'gameValue': 14},
        {'uid': 'p2', 'gameValue': 14},
        {'uid': 'p3', 'gameValue': 4},
      ];
      final leader = evaluateGamePointLeader(playerStates);
      expect(leader.leaderUid, isNull);
      expect(leader.highestValue, 14);
      expect(leader.isTied, isTrue);
    });

    test('evaluateGamePointWinner awards game point to unique highest player', () {
      final playerStates = [
        {'uid': 'p1', 'gameValue': 18},
        {'uid': 'p2', 'gameValue': 14},
        {'uid': 'p3', 'gameValue': 8},
      ];
      final winner = evaluateGamePointWinner(playerStates);
      expect(winner, isNotNull);
      expect(winner!['uid'], 'p1');
    });

    test('evaluateGamePointWinner returns null when highest game points are tied', () {
      final playerStates = [
        {'uid': 'p1', 'gameValue': 14},
        {'uid': 'p2', 'gameValue': 14},
        {'uid': 'p3', 'gameValue': 8},
      ];
      final winner = evaluateGamePointWinner(playerStates);
      expect(winner, isNull);
    });
  });

  group('Sleeping Trump Cards Evaluation', () {
    test('returns empty list when Jack, 5, and 9 of trump were all played', () {
      final sleeping = evaluateSleepingCards(
        trumpSuit: Suit.spades,
        playedCards: [
          Card(suit: Suit.spades, rank: Rank.jack),
          Card(suit: Suit.spades, rank: Rank.five),
          Card(suit: Suit.spades, rank: Rank.nine),
          Card(suit: Suit.hearts, rank: Rank.ace),
        ],
      );
      expect(sleeping, isEmpty);
    });

    test('identifies single sleeping trump card when Jack remained in deck', () {
      final sleeping = evaluateSleepingCards(
        trumpSuit: Suit.hearts,
        playedCards: [
          Card(suit: Suit.hearts, rank: Rank.five),
          Card(suit: Suit.hearts, rank: Rank.nine),
          Card(suit: Suit.spades, rank: Rank.jack), // off-suit Jack does not count
          Card(suit: Suit.hearts, rank: Rank.ace),
        ],
      );
      expect(
        sleeping,
        equals([Card(suit: Suit.hearts, rank: Rank.jack)]),
      );
    });

    test('identifies all three major trump cards (Jack, 5, 9) when none were played', () {
      final sleeping = evaluateSleepingCards(
        trumpSuit: Suit.diamonds,
        playedCards: [
          Card(suit: Suit.diamonds, rank: Rank.ace),
          Card(suit: Suit.diamonds, rank: Rank.two),
          Card(suit: Suit.diamonds, rank: Rank.ten),
          Card(suit: Suit.clubs, rank: Rank.jack),
          Card(suit: Suit.clubs, rank: Rank.five),
          Card(suit: Suit.clubs, rank: Rank.nine),
        ],
      );
      expect(
        sleeping,
        equals([
          Card(suit: Suit.diamonds, rank: Rank.jack),
          Card(suit: Suit.diamonds, rank: Rank.five),
          Card(suit: Suit.diamonds, rank: Rank.nine),
        ]),
      );
    });
  });
}



