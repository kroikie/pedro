import 'package:functions/game/deck.dart';
import 'package:functions/game/narrator.dart';
import 'package:test/test.dart';

void main() {
  group('Narrator Context Formatting', () {
    const testPlayer = 'arthur thompson';

    group('Point Events', () {
      test('snatching the 9 matches exact Trinidadian phrasing with player name without trump suffix', () {
        final context = formatPointEventContext(
          playerName: testPlayer,
          pointType: '9',
          isStolen: false,
        );
        expect(
          context,
          'Lardits! arthur thompson just snatch de 9! 9 big points in de bag!',
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
          'Oh gosh! arthur thompson just hang de man Jack! Daylight robbery on de table!',
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

      test('grabbing 5 includes player name without trump suffix', () {
        final context = formatPointEventContext(
          playerName: testPlayer,
          pointType: '5',
          isStolen: false,
        );
        expect(
          context,
          'arthur thompson grab de 5! 5 big points in de bag!',
        );
      });

      test('holding High and dropping Low includes player name with authentic Pedro banter', () {
        final high = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'High',
          isStolen: false,
        );
        expect(high, 'arthur thompson holding High. High till higher comes!');

        final highRank = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'High',
          isStolen: false,
          cardRank: Rank.king,
        );
        expect(highRank, 'arthur thompson holding High with king. High till higher comes!');

        final highSafe = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'High',
          isStolen: false,
          cardRank: Rank.ace,
          isSafe: true,
        );
        expect(highSafe, 'arthur thompson put down de Ace! High safe, nobody could touch dat!');

        final low = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'Low',
          isStolen: false,
        );
        expect(low, 'arthur thompson drop low. Low till lower comes!');

        final lowRank = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'Low',
          isStolen: false,
          cardRank: Rank.three,
        );
        expect(lowRank, 'arthur thompson drop low with three. Low till lower comes!');

        final lowSafe = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'Low',
          isStolen: false,
          cardRank: Rank.two,
          isSafe: true,
        );
        expect(lowSafe, 'arthur thompson drop de 2! Low safe, nobody could beat dat!');
      });

      test('winning Game point includes player name and card score value', () {
        final context = formatPointEventContext(
          playerName: testPlayer,
          pointType: 'Game',
          isStolen: false,
          scoreValue: 18,
        );
        expect(
          context,
          'arthur thompson win de Game point with 18 card points! Look value in de bag!',
        );
      });

      test('tied Game point indicates tie without winner', () {
        final context = formatPointEventContext(
          playerName: 'Players',
          pointType: 'Game',
          isStolen: true,
          scoreValue: 14,
        );
        expect(
          context,
          'Game point tied! Nobody get de Game point dis round!',
        );
      });

      test('never contains generic "A player" in any point event', () {
        for (final pointType in ['9', 'Jack', '5', 'High', 'Low', 'Game']) {
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

      test('winning contract includes player name and winning bid value', () {
        final context = formatBidWonContext(
          playerName: testPlayer,
          bid: 15,
        );
        expect(
          context,
          'arthur thompson win de bid with 15! Contract set, leh we see what trump dey calling!',
        );
      });

      test('never contains generic "A player" in any bid event', () {
        final contexts = [
          formatBidContext(playerName: testPlayer, bid: null, previousBid: 14),
          formatBidContext(playerName: testPlayer, bid: 20, previousBid: 14),
          formatBidContext(playerName: testPlayer, bid: 19, previousBid: 10),
          formatBidContext(playerName: testPlayer, bid: 15, previousBid: 14),
          formatBidWonContext(playerName: testPlayer, bid: 14),
        ];

        for (final ctx in contexts) {
          expect(ctx, isNot(contains('A player')));
        }
      });
    });

    group('Lift Resolution Events', () {
      test('stolen Jack is formatted as daylight robbery', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
          stoleJack: true,
        );
        expect(
          context,
          'Oh gosh! arthur thompson just hang de man Jack! Daylight robbery on de table!',
        );
      });

      test('stolen Jack and 9 is formatted as combined heist', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
          stoleJack: true,
          wonNine: true,
        );
        expect(
          context,
          'Oh gosh! arthur thompson hang de man Jack and snatch de 9! Daylight robbery on de table!',
        );
      });

      test('stolen Jack with 9 and 5 is formatted as monster robbery', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
          stoleJack: true,
          wonNine: true,
          wonFive: true,
        );
        expect(
          context,
          'Oh gosh! arthur thompson hang de man Jack AND scoop de 9 and 5! Monster robbery on de table!',
        );
      });

      test('capturing both 9 and 5 is formatted as clean 14-point sweep', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
          wonNine: true,
          wonFive: true,
        );
        expect(
          context,
          'Lardits! arthur thompson scoop both de 9 and de 5! 14 big points in one sweep!',
        );
      });

      test('capturing 9 alone is formatted with Pedro points', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
          wonNine: true,
        );
        expect(
          context,
          'Lardits! arthur thompson snatch de 9! 9 big points in de bag!',
        );
      });

      test('capturing 5 alone is formatted with Pedro points', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
          wonFive: true,
        );
        expect(
          context,
          'arthur thompson grab de 5! 5 big points in de bag!',
        );
      });

      test('saving own Jack alone is formatted as safe play', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
          savedJack: true,
        );
        expect(
          context,
          'arthur thompson play and save dey own Jack for 1 point. Safe play.',
        );
      });

      test('empty when no point cards were involved', () {
        final context = formatLiftResolutionContext(
          winnerName: testPlayer,
        );
        expect(context, isEmpty);
      });
    });

    group('Round End & Match Climax Events', () {
      test('made contract formatted with praise', () {
        final context = formatRoundEndContext(
          bidWinnerName: testPlayer,
          bidValue: 14,
          pointsWon: 16,
          bidSuccess: true,
        );
        expect(
          context,
          'arthur thompson make de 14 bid with 16 points! Safe home!',
        );
      });

      test('set contract formatted with picong', () {
        final context = formatRoundEndContext(
          bidWinnerName: testPlayer,
          bidValue: 14,
          pointsWon: 8,
          bidSuccess: false,
        );
        expect(
          context,
          'Lardits! arthur thompson get set! Bid 14 but only take 8 points... minus 14 on dey head!',
        );
      });

      test('includes game point winner details', () {
        final context = formatRoundEndContext(
          bidWinnerName: testPlayer,
          bidValue: 14,
          pointsWon: 16,
          bidSuccess: true,
          gamePointWinnerName: 'Bob',
          gamePointScore: 24,
        );
        expect(
          context,
          'arthur thompson make de 14 bid with 16 points! Safe home! And Bob take de Game point with 24 card points!',
        );
      });

      test('match winner crowns final champion', () {
        final context = formatRoundEndContext(
          bidWinnerName: testPlayer,
          bidValue: 14,
          pointsWon: 16,
          bidSuccess: true,
          matchWinnerName: 'Alice',
        );
        expect(
          context,
          'Game over! Alice reach de target score and take de crown! Total champion on de table!',
        );
      });
    });

    group('Call Player Events', () {
      test('fallbacks include both callerName and slowPlayerName with authentic Trini banter', () {
        final fallbacks = getCallPlayerFallbacks('Alice', 'Bob');
        expect(fallbacks, isNotEmpty);
        expect(fallbacks.length, greaterThanOrEqualTo(6));
        for (final text in fallbacks) {
          expect(text, contains('Alice'));
          expect(text, contains('Bob'));
        }
        expect(
          fallbacks,
          contains('Aye Bob, yuh could stop eating for 2 seconds to play yuh know! Alice waiting on yuh!'),
        );
        expect(
          fallbacks,
          contains('Aye Bob, yuh studying de cards or writing ah CXC exam? Alice waiting on yuh!'),
        );
      });
    });

    group('Model Configuration', () {
      test('narratorModel is configured to gemini-3.5-flash-lite', () {
        expect(narratorModel, equals('gemini-3.5-flash-lite'));
      });
    });
  });
}
