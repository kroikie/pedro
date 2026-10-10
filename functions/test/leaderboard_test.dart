import 'package:functions/game/leaderboard.dart';
import 'package:test/test.dart';

void main() {
  group('ISO Week Calculation', () {
    test('calculates standard ISO week and period ID', () {
      final dt = DateTime.utc(2026, 10, 8, 20, 39); // Thursday in W41 of 2026
      expect(getIsoWeekId(dt), equals('2026-W41'));
      expect(getWeeklyPeriodId(dt), equals('weekly_2026-W41'));
    });

    test('handles ISO year boundary correctly', () {
      // Jan 1, 2026 is a Thursday -> 2026-W01
      expect(getIsoWeekId(DateTime.utc(2026, 1, 1)), equals('2026-W01'));
      // Jan 1, 2027 is a Friday -> belongs to 2026-W53
      expect(getIsoWeekId(DateTime.utc(2027, 1, 1)), equals('2026-W53'));
    });
  });

  group('analyzeRoundLifts', () {
    test('detects hung Jack, stolen 9, and stolen 5 with both winners and victims', () {
      final completedLifts = <Map<String, dynamic>>[
        {
          'leadPlayerId': 'p1',
          'winnerId': 'p3',
          'plays': {
            'p1': {'suit': 'spades', 'rank': 'jack'}, // p1's Jack hung by p3
            'p2': {'suit': 'hearts', 'rank': 'jack'}, // non-trump Jack ignored
            'p3': {'suit': 'spades', 'rank': 'queen'},
            'p4': {'suit': 'spades', 'rank': 'five'}, // p4's 5 stolen by p3
          },
        },
        {
          'leadPlayerId': 'p3',
          'winnerId': 'p2',
          'plays': {
            'p3': {'suit': 'spades', 'rank': 'nine'}, // p3's 9 stolen by p2
            'p4': {'suit': 'spades', 'rank': 'two'},
            'p1': {'suit': 'clubs', 'rank': 'nine'}, // non-trump 9 ignored
            'p2': {'suit': 'spades', 'rank': 'ace'},
          },
        },
      ];

      final analysis = analyzeRoundLifts(
        completedLifts: completedLifts,
        trumpSuit: 'spades',
      );

      expect(analysis.hangJackWinnerId, equals('p3'));
      expect(analysis.jackHungVictimId, equals('p1'));
      expect(analysis.savedJackWinnerId, isNull);
      expect(analysis.fiveTrumpWinnerId, equals('p3'));
      expect(analysis.fiveTrumpLoserId, equals('p4'));
      expect(analysis.nineTrumpWinnerId, equals('p2'));
      expect(analysis.nineTrumpLoserId, equals('p3'));
      expect(analysis.sleepingCards, isEmpty);
    });

    test('detects saved Jack and self-won 9 and 5 without recording a victim', () {
      final completedLifts = <Map<String, dynamic>>[
        {
          'leadPlayerId': 'p1',
          'winnerId': 'p1',
          'plays': {
            'p1': {'suit': 'hearts', 'rank': 'jack'},
            'p2': {'suit': 'clubs', 'rank': 'two'},
            'p3': {'suit': 'diamonds', 'rank': 'three'},
            'p4': {'suit': 'spades', 'rank': 'four'},
          },
        },
        {
          'leadPlayerId': 'p2',
          'winnerId': 'p2',
          'plays': {
            'p2': {'suit': 'hearts', 'rank': 'nine'},
            'p3': {'suit': 'clubs', 'rank': 'six'},
            'p4': {'suit': 'diamonds', 'rank': 'seven'},
            'p1': {'suit': 'spades', 'rank': 'eight'},
          },
        },
        {
          'leadPlayerId': 'p4',
          'winnerId': 'p4',
          'plays': {
            'p4': {'suit': 'hearts', 'rank': 'five'},
            'p1': {'suit': 'clubs', 'rank': 'ten'},
            'p2': {'suit': 'diamonds', 'rank': 'queen'},
            'p3': {'suit': 'spades', 'rank': 'king'},
          },
        },
      ];

      final analysis = analyzeRoundLifts(
        completedLifts: completedLifts,
        trumpSuit: 'hearts',
      );

      expect(analysis.savedJackWinnerId, equals('p1'));
      expect(analysis.hangJackWinnerId, isNull);
      expect(analysis.jackHungVictimId, isNull);
      expect(analysis.nineTrumpWinnerId, equals('p2'));
      expect(analysis.nineTrumpLoserId, isNull);
      expect(analysis.fiveTrumpWinnerId, equals('p4'));
      expect(analysis.fiveTrumpLoserId, isNull);
      expect(analysis.sleepingCards, isEmpty);
    });

    test('identifies sleeping Jack, 5, and 9 when they remain undealt in the deck', () {
      final completedLifts = <Map<String, dynamic>>[
        {
          'leadPlayerId': 'p1',
          'winnerId': 'p1',
          'plays': {
            'p1': {'suit': 'clubs', 'rank': 'ace'},
            'p2': {'suit': 'clubs', 'rank': 'five'}, // 5 of clubs played
            'p3': {'suit': 'hearts', 'rank': 'jack'}, // non-trump Jack ignored
            'p4': {'suit': 'spades', 'rank': 'nine'}, // non-trump 9 ignored
          },
        },
      ];

      final analysis = analyzeRoundLifts(
        completedLifts: completedLifts,
        trumpSuit: 'clubs',
      );

      expect(analysis.fiveTrumpWinnerId, equals('p1'));
      expect(analysis.savedJackWinnerId, isNull);
      expect(analysis.hangJackWinnerId, isNull);
      expect(analysis.nineTrumpWinnerId, isNull);
      expect(
        analysis.sleepingCards,
        equals([
          {'suit': 'clubs', 'rank': 'jack'},
          {'suit': 'clubs', 'rank': 'nine'},
        ]),
      );
    });
  });

  group('extractPlayerRoundStatDeltas & extractRivalryDeltas', () {
    final profiles = <String, PlayerProfileInfo>{
      'p1': const PlayerProfileInfo(uid: 'p1', screenName: 'Alice'),
      'p2': const PlayerProfileInfo(uid: 'p2', screenName: 'Bob'),
      'p3': const PlayerProfileInfo(uid: 'p3', screenName: 'Charlie'),
      'p4': const PlayerProfileInfo(uid: 'p4', screenName: 'Diana'),
    };

    test('computes Triumphs, Hall of Shame, and directed Rivalries accurately', () {
      final completedLifts = <Map<String, dynamic>>[
        {
          'leadPlayerId': 'p1',
          'winnerId': 'p3',
          'plays': {
            'p1': {'suit': 'spades', 'rank': 'jack'}, // p3 hangs p1's Jack (+3)
            'p2': {'suit': 'spades', 'rank': 'nine'}, // p3 steals p2's 9 (+9)
            'p3': {'suit': 'spades', 'rank': 'ace'},
            'p4': {'suit': 'spades', 'rank': 'two'},
          },
        },
        {
          'leadPlayerId': 'p3',
          'winnerId': 'p3',
          'plays': {
            'p3': {'suit': 'spades', 'rank': 'king'},
            'p4': {'suit': 'spades', 'rank': 'five'}, // p3 steals p4's 5 (+5)
            'p1': {'suit': 'hearts', 'rank': 'two'},
            'p2': {'suit': 'clubs', 'rank': 'three'},
          },
        },
      ];

      final liftAnalysis = analyzeRoundLifts(
        completedLifts: completedLifts,
        trumpSuit: 'spades',
      );

      final playerStates = <Map<String, dynamic>>[
        {
          'uid': 'p1',
          'currentRoundPoints': 0,
          'totalScore': 10,
          'earnedPoints': <String>[],
          'gameValue': 0,
          'capturedValueCards': <Map<String, dynamic>>[],
        },
        {
          'uid': 'p2',
          'currentRoundPoints': 0,
          'totalScore': -1, // was 10, bid 11 and went buss
          'earnedPoints': <String>[],
          'gameValue': 0,
          'capturedValueCards': <Map<String, dynamic>>[],
        },
        {
          'uid': 'p3',
          'currentRoundPoints': 19,
          'totalScore': 39, // won the match!
          'earnedPoints': <String>['High', 'Hang Jack', '9', '5', 'Game'],
          'gameValue': 18,
          'capturedValueCards': <Map<String, dynamic>>[],
        },
        {
          'uid': 'p4',
          'currentRoundPoints': 1,
          'totalScore': 15,
          'earnedPoints': <String>['Low'],
          'gameValue': 0,
          'capturedValueCards': <Map<String, dynamic>>[],
        },
      ];

      final summaries = extractPlayerRoundStatDeltas(
        playerStates: playerStates,
        previousTotalScores: {'p1': 10, 'p2': 10, 'p3': 20, 'p4': 14},
        playerProfiles: profiles,
        completedLifts: completedLifts,
        liftAnalysis: liftAnalysis,
        bidWinnerId: 'p2',
        bidSuccess: false,
        highTrumpPlayerId: 'p3',
        lowTrumpPlayerId: 'p4',
        gameWinnerId: 'p3',
        matchWinnerId: 'p3',
      );

      final p1Summary = summaries.firstWhere((s) => s['uid'] == 'p1');
      final p2Summary = summaries.firstWhere((s) => s['uid'] == 'p2');
      final p3Summary = summaries.firstWhere((s) => s['uid'] == 'p3');
      final p4Summary = summaries.firstWhere((s) => s['uid'] == 'p4');

      // p1 had Jack hung
      expect(p1Summary['jacksHung'], equals(1));
      expect(p1Summary['hangJacks'], equals(0));
      expect(p1Summary['gamesPlayed'], equals(1));

      // p2 lost 9 and was set on bid
      expect(p2Summary['ninesLost'], equals(1));
      expect(p2Summary['bidsWon'], equals(1));
      expect(p2Summary['bidsMade'], equals(0));
      expect(p2Summary['bidsSet'], equals(1));

      // p3 won High, Hang Jack, 9, 5, Game, and the Match
      expect(p3Summary['highTrumps'], equals(1));
      expect(p3Summary['hangJacks'], equals(1));
      expect(p3Summary['ninesWon'], equals(1));
      expect(p3Summary['fivesWon'], equals(1));
      expect(p3Summary['gamePointsWon'], equals(1));
      expect(p3Summary['gamesWon'], equals(1));
      expect(p3Summary['pointsEarned'], equals(19));

      // p4 won Low, lost 5
      expect(p4Summary['lowTrumps'], equals(1));
      expect(p4Summary['fivesLost'], equals(1));

      final rivalries = extractRivalryDeltas(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        playerProfiles: profiles,
        liftAnalysis: liftAnalysis,
        matchWinnerId: 'p3',
      );

      expect(rivalries, hasLength(3));
      final p3VsP1 = rivalries.firstWhere((r) => r['id'] == 'p3_p1');
      expect(p3VsP1['jacksHung'], equals(1));
      expect(p3VsP1['heistCount'], equals(1));
      expect(p3VsP1['heistPoints'], equals(3));
      expect(p3VsP1['matchesWonAgainst'], equals(1));

      final p3VsP2 = rivalries.firstWhere((r) => r['id'] == 'p3_p2');
      expect(p3VsP2['ninesStolen'], equals(1));
      expect(p3VsP2['heistCount'], equals(1));
      expect(p3VsP2['heistPoints'], equals(9));
      expect(p3VsP2['matchesWonAgainst'], equals(1));

      final p3VsP4 = rivalries.firstWhere((r) => r['id'] == 'p3_p4');
      expect(p3VsP4['fivesStolen'], equals(1));
      expect(p3VsP4['heistCount'], equals(1));
      expect(p3VsP4['heistPoints'], equals(5));
      expect(p3VsP4['matchesWonAgainst'], equals(1));
    });
  });

  group('aggregateArchivedRounds (Deterministic CLI Reconciliation)', () {
    test('aggregates multiple rounds across weeks into all_time and weekly buckets', () {
      final round1 = buildArchivedRoundDocument(
        gameId: 'game_1',
        roundNumber: 1,
        completedAtUtc: DateTime.utc(2026, 10, 8, 12, 0), // 2026-W41
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        dealerId: 'p1',
        trumpSuit: 'spades',
        bidWinnerId: 'p1',
        bidValue: 8,
        bidSuccess: true,
        highTrumpPlayerId: 'p1',
        highTrumpPlayedCard: {'suit': 'spades', 'rank': 'ace'},
        lowTrumpPlayerId: 'p2',
        lowTrumpPlayedCard: {'suit': 'spades', 'rank': 'two'},
        liftAnalysis: const RoundLiftAnalysis(
          hangJackWinnerId: 'p1',
          jackHungVictimId: 'p2',
          nineTrumpWinnerId: 'p1',
          nineTrumpLoserId: 'p3',
          fiveTrumpWinnerId: 'p4',
          fiveTrumpLoserId: null,
        ),
        gameWinnerId: 'p1',
        gameWinningScore: 16,
        isGameTied: false,
        matchWinnerId: null,
        playerSummaries: [
          {
            'uid': 'p1',
            'screenName': 'Alice',
            'pointsEarned': 14,
            'hangJacks': 1,
            'jacksSaved': 0,
            'highTrumps': 1,
            'lowTrumps': 0,
            'fivesWon': 0,
            'ninesWon': 1,
            'gamePointsWon': 1,
            'bidsWon': 1,
            'bidsMade': 1,
            'gamesWon': 0,
            'jacksHung': 0,
            'ninesLost': 0,
            'fivesLost': 0,
            'bidsSet': 0,
            'roundsPlayed': 1,
            'gamesPlayed': 0,
          },
          {
            'uid': 'p2',
            'screenName': 'Bob',
            'pointsEarned': 1,
            'hangJacks': 0,
            'jacksSaved': 0,
            'highTrumps': 0,
            'lowTrumps': 1,
            'fivesWon': 0,
            'ninesWon': 0,
            'gamePointsWon': 0,
            'bidsWon': 0,
            'bidsMade': 0,
            'gamesWon': 0,
            'jacksHung': 1,
            'ninesLost': 0,
            'fivesLost': 0,
            'bidsSet': 0,
            'roundsPlayed': 1,
            'gamesPlayed': 0,
          },
        ],
        heists: [
          {
            'id': 'p1_p2',
            'actorUid': 'p1',
            'actorName': 'Alice',
            'victimUid': 'p2',
            'victimName': 'Bob',
            'jacksHung': 1,
            'ninesStolen': 0,
            'fivesStolen': 0,
            'heistCount': 1,
            'heistPoints': 3,
            'matchesWonAgainst': 0,
          },
        ],
        completedLifts: const [],
      );

      final round2NextWeek = buildArchivedRoundDocument(
        gameId: 'game_1',
        roundNumber: 2,
        completedAtUtc: DateTime.utc(2026, 10, 15, 12, 0), // 2026-W42
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        dealerId: 'p2',
        trumpSuit: 'hearts',
        bidWinnerId: 'p2',
        bidValue: 10,
        bidSuccess: false,
        highTrumpPlayerId: 'p1',
        highTrumpPlayedCard: {'suit': 'hearts', 'rank': 'ace'},
        lowTrumpPlayerId: 'p2',
        lowTrumpPlayedCard: {'suit': 'hearts', 'rank': 'two'},
        liftAnalysis: const RoundLiftAnalysis(
          hangJackWinnerId: 'p1',
          jackHungVictimId: 'p2',
        ),
        gameWinnerId: 'p1',
        gameWinningScore: 20,
        isGameTied: false,
        matchWinnerId: 'p1',
        playerSummaries: [
          {
            'uid': 'p1',
            'screenName': 'Alice',
            'pointsEarned': 21,
            'hangJacks': 1,
            'jacksSaved': 0,
            'highTrumps': 1,
            'lowTrumps': 0,
            'fivesWon': 1,
            'ninesWon': 1,
            'gamePointsWon': 1,
            'bidsWon': 0,
            'bidsMade': 0,
            'gamesWon': 1,
            'jacksHung': 0,
            'ninesLost': 0,
            'fivesLost': 0,
            'bidsSet': 0,
            'roundsPlayed': 1,
            'gamesPlayed': 1,
          },
          {
            'uid': 'p2',
            'screenName': 'Bob',
            'pointsEarned': 1,
            'hangJacks': 0,
            'jacksSaved': 0,
            'highTrumps': 0,
            'lowTrumps': 1,
            'fivesWon': 0,
            'ninesWon': 0,
            'gamePointsWon': 0,
            'bidsWon': 1,
            'bidsMade': 0,
            'gamesWon': 0,
            'jacksHung': 1,
            'ninesLost': 0,
            'fivesLost': 0,
            'bidsSet': 1,
            'roundsPlayed': 1,
            'gamesPlayed': 1,
          },
        ],
        heists: [
          {
            'id': 'p1_p2',
            'actorUid': 'p1',
            'actorName': 'Alice',
            'victimUid': 'p2',
            'victimName': 'Bob',
            'jacksHung': 1,
            'ninesStolen': 0,
            'fivesStolen': 0,
            'heistCount': 1,
            'heistPoints': 3,
            'matchesWonAgainst': 1,
          },
        ],
        completedLifts: const [],
      );

      final aggregated = aggregateArchivedRounds([round1, round2NextWeek]);

      expect(aggregated.totalRoundsProcessed, equals(2));
      expect(aggregated.reconciledGameIds, equals({'game_1'}));

      // Verify all_time sums both weeks
      final allTimeP1 = aggregated.playersByPeriod['all_time']!['p1']!;
      expect(allTimeP1['hangJacks'], equals(2));
      expect(allTimeP1['gamesWon'], equals(1));
      expect(allTimeP1['roundsPlayed'], equals(2));
      expect(allTimeP1['totalPointsEarned'], equals(35));

      final allTimeP2 = aggregated.playersByPeriod['all_time']!['p2']!;
      expect(allTimeP2['jacksHung'], equals(2));
      expect(allTimeP2['bidsSet'], equals(1));

      final allTimeRivalry = aggregated.rivalriesByPeriod['all_time']!['p1_p2']!;
      expect(allTimeRivalry['jacksHung'], equals(2));
      expect(allTimeRivalry['heistPoints'], equals(6));
      expect(allTimeRivalry['matchesWonAgainst'], equals(1));

      // Verify weekly_2026-W41 only has round 1
      final w41P1 = aggregated.playersByPeriod['weekly_2026-W41']!['p1']!;
      expect(w41P1['hangJacks'], equals(1));
      expect(w41P1['gamesWon'], equals(0));

      // Verify weekly_2026-W42 only has round 2
      final w42P1 = aggregated.playersByPeriod['weekly_2026-W42']!['p1']!;
      expect(w42P1['hangJacks'], equals(1));
      expect(w42P1['gamesWon'], equals(1));
    });
  });
}
