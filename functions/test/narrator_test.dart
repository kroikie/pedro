import 'package:functions/game/narrator.dart';
import 'package:test/test.dart';

void main() {
  group('Narrator Context Formatting', () {
    const testPlayer = 'arthur thompson';

    group('Point Events', () {
      test('snatching the 9 of trumps matches exact Trinidadian phrasing with player name', () {
        final context = formatPointEventContext(
          playerName: testPlayer,
          pointType: '9',
          isStolen: false,
        );
        expect(
          context,
          'Lardits! arthur thompson just snatch de 9 ah trump! arthur thompson does play card for gramoxone!',
        );
      });

      test('hanging Jack matches dramatic phrasing with player name', () {
        final stolenJackContext = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'Jack',
          isStolen: true,
        );
        expect(
          stolenJackContext,
          'Oh gosh! arthur thompson just hang de man Jack! Massive robbery on de table... arthur thompson does play card for gramoxone!',
        );

        final savedJackContext = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'Jack',
          isStolen: false,
        );
        expect(
          savedJackContext,
          'arthur thompson play and save dey own Jack for 1 point. Safe play.',
        );
      });

      test('grabbing 5 of trumps includes player name', () {
        final context = formatPointEventContext(
          playerName: testPlayer,
          pointType: '5',
          isStolen: false,
        );
        expect(
          context,
          'arthur thompson grab de 5 ah trumps! 5 big points in de bag!',
        );
      });

      test('holding High and dropping Low trump includes player name', () {
        final high = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'High',
          isStolen: false,
        );
        expect(high, 'arthur thompson holding High trump point.');

        final low = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'Low',
          isStolen: false,
        );
        expect(
          low,
          'arthur thompson drop de lowest trump. 1 point safe even if lift lost!',
        );
      });

      test('never contains generic "A player" in any point event', () {
        for (final pointType in ['9', 'Jack', '5', 'High', 'Low']) {
          final contextStolen = formatPointEventContext(
            playerName: testPlayer,
            pointType: pointType,
            isStolen: true,
          );
          expect(contextStolen, isNot(contains('A player')));

          final contextNormal = formatPointEventContext(
            playerName: testPlayer,
            pointType: pointType,
            isStolen: false,
          );
          expect(contextNormal, isNot(contains('A player')));
        }
      });
    });

    group('Bid Events', () {
      test('passing includes player name and previous high bid', () {
        final context = formatBidContext(
          playerName: testPlayer,
          bid: null,
          previousBid: 14,
        );
        expect(
          context,
          'arthur thompson pass. Dey playing it cool (or dey holding ah real bad hand). High bid still on 14.',
        );
      });

      test('all in 20 bid includes player name and Trinidadian exclamation', () {
        final context = formatBidContext(
          playerName: testPlayer,
          bid: 20,
          previousBid: 14,
        );
        expect(
          context,
          'Jah! arthur thompson gone ALL IN with 20! Dat is ah brave bid de arthur thompson, leh we see if dey could back it up!',
        );
      });

      test('jump bid includes player name and pressure remark', () {
        final context = formatBidContext(
          playerName: testPlayer,
          bid: 18,
          previousBid: 10,
        );
        expect(
          context,
          'Lardits! arthur thompson jump de bid from 10 straight to 18! Look pressure on de table!',
        );
      });

      test('normal bid increment includes player name', () {
        final context = formatBidContext(
          playerName: testPlayer,
          bid: 15,
          previousBid: 14,
        );
        expect(
          context,
          'Dat is ah brave bid de arthur thompson! Bid raised to 15.',
        );
      });

      test('never contains generic "A player" in any bid event', () {
        final contexts = [
          formatBidContext(playerName: testPlayer, bid: null, previousBid: 14),
          formatBidContext(playerName: testPlayer, bid: 20, previousBid: 14),
          formatBidContext(playerName: testPlayer, bid: 19, previousBid: 10),
          formatBidContext(playerName: testPlayer, bid: 15, previousBid: 14),
        ];

        for (final ctx in contexts) {
          expect(ctx, isNot(contains('A player')));
        }
      });
    });
  });
}
