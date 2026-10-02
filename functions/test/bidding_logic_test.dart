import 'package:functions/game/deck.dart';
import 'package:functions/game/logic.dart';
import 'package:test/test.dart';

void main() {
  group('Bidding Logic & Turn Progression', () {
    final playerIds = ['p0', 'p1', 'p2', 'p3'];

    test('getNextBidderIndex advances sequentially when no players passed', () {
      expect(
        getNextBidderIndex(
          playerIds: playerIds,
          currentTurnIndex: 0,
          passedPlayerIds: [],
        ),
        1,
      );
      expect(
        getNextBidderIndex(
          playerIds: playerIds,
          currentTurnIndex: 3,
          passedPlayerIds: [],
        ),
        0,
      );
    });

    test('getNextBidderIndex skips passed players', () {
      // p1 has passed; turn after p0 should skip p1 and go to p2
      expect(
        getNextBidderIndex(
          playerIds: playerIds,
          currentTurnIndex: 0,
          passedPlayerIds: ['p1'],
        ),
        2,
      );

      // p1 and p2 have passed; turn after p0 should skip both and go to p3
      expect(
        getNextBidderIndex(
          playerIds: playerIds,
          currentTurnIndex: 0,
          passedPlayerIds: ['p1', 'p2'],
        ),
        3,
      );

      // p1 and p3 have passed; turn after p2 should wrap around, skip p3 and p1, and go to p0
      expect(
        getNextBidderIndex(
          playerIds: playerIds,
          currentTurnIndex: 2,
          passedPlayerIds: ['p1', 'p3'],
        ),
        0,
      );
    });

    test('getNextBidderIndex throws StateError if all players have passed', () {
      expect(
        () => getNextBidderIndex(
          playerIds: playerIds,
          currentTurnIndex: 0,
          passedPlayerIds: ['p0', 'p1', 'p2', 'p3'],
        ),
        throwsStateError,
      );
    });

    test('isBiddingComplete returns false if no bid winner exists', () {
      expect(
        isBiddingComplete(
          totalPlayers: 4,
          passedPlayerIds: ['p1', 'p2', 'p3'],
          bidWinnerId: null,
        ),
        isFalse,
      );
    });

    test('isBiddingComplete returns false if fewer than N - 1 players passed', () {
      expect(
        isBiddingComplete(
          totalPlayers: 4,
          passedPlayerIds: ['p1', 'p2'],
          bidWinnerId: 'p0',
        ),
        isFalse,
      );
    });

    test('isBiddingComplete returns true when N - 1 players passed with a bid winner', () {
      expect(
        isBiddingComplete(
          totalPlayers: 4,
          passedPlayerIds: ['p1', 'p2', 'p3'],
          bidWinnerId: 'p0',
        ),
        isTrue,
      );
    });

    test('Complete 4-player bidding cycle with pass elimination', () {
      // P0 starts bidding, bids 5
      int currentBid = 5;
      String? bidWinnerId = 'p0';
      final passed = <String>[];
      int turn = 0;

      // P1 passes
      turn = getNextBidderIndex(
        playerIds: playerIds,
        currentTurnIndex: turn,
        passedPlayerIds: passed,
      );
      expect(turn, 1);
      passed.add('p1');
      expect(isBiddingComplete(totalPlayers: 4, passedPlayerIds: passed, bidWinnerId: bidWinnerId), isFalse);

      // P2 raises to 7
      turn = getNextBidderIndex(
        playerIds: playerIds,
        currentTurnIndex: turn,
        passedPlayerIds: passed,
      );
      expect(turn, 2);
      currentBid = 7;
      bidWinnerId = 'p2';

      // P3 passes
      turn = getNextBidderIndex(
        playerIds: playerIds,
        currentTurnIndex: turn,
        passedPlayerIds: passed,
      );
      expect(turn, 3);
      passed.add('p3');
      expect(isBiddingComplete(totalPlayers: 4, passedPlayerIds: passed, bidWinnerId: bidWinnerId), isFalse);

      // Next turn: should skip p1 (passed) and p3 (passed) and wrap to p0
      turn = getNextBidderIndex(
        playerIds: playerIds,
        currentTurnIndex: turn,
        passedPlayerIds: passed,
      );
      expect(turn, 0);

      // P0 raises to 8
      currentBid = 8;
      bidWinnerId = 'p0';

      // Next turn: should skip p1 (passed), go to p2 (still active)
      turn = getNextBidderIndex(
        playerIds: playerIds,
        currentTurnIndex: turn,
        passedPlayerIds: passed,
      );
      expect(turn, 2);

      // P2 passes
      passed.add('p2');
      expect(passed.length, 3);
      expect(
        isBiddingComplete(totalPlayers: 4, passedPlayerIds: passed, bidWinnerId: bidWinnerId),
        isTrue,
      );
      expect(bidWinnerId, 'p0');
      expect(currentBid, 8);
    });
  });

  group('Card Discard & Replacement Calculation', () {
    test('calculateDiscardsCount counts non-trump cards', () {
      final hand = [
        Card(suit: Suit.hearts, rank: Rank.ace),
        Card(suit: Suit.hearts, rank: Rank.king),
        Card(suit: Suit.clubs, rank: Rank.ten),
        Card(suit: Suit.spades, rank: Rank.five),
        Card(suit: Suit.diamonds, rank: Rank.two),
      ];

      // Trump is hearts -> 3 non-trump cards discarded
      expect(calculateDiscardsCount(hand: hand, trumpSuit: Suit.hearts), 3);

      // Trump is clubs -> 4 non-trump cards discarded
      expect(calculateDiscardsCount(hand: hand, trumpSuit: Suit.clubs), 4);
    });

    test('calculateDiscardsCount returns 0 when all cards are trump', () {
      final allTrumpHand = [
        Card(suit: Suit.spades, rank: Rank.ace),
        Card(suit: Suit.spades, rank: Rank.nine),
        Card(suit: Suit.spades, rank: Rank.five),
      ];
      expect(calculateDiscardsCount(hand: allTrumpHand, trumpSuit: Suit.spades), 0);
    });

    test('calculateDiscardsCount returns hand length when no cards are trump', () {
      final noTrumpHand = [
        Card(suit: Suit.clubs, rank: Rank.ace),
        Card(suit: Suit.diamonds, rank: Rank.nine),
      ];
      expect(calculateDiscardsCount(hand: noTrumpHand, trumpSuit: Suit.hearts), 2);
    });
  });
}
