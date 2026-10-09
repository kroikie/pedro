import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/leaderboard_entry.dart';
import 'package:pedro/data/repositories/leaderboard_repository.dart';
import 'package:pedro/ui/screens/leaderboard_view.dart';

class FakeLeaderboardRepository extends LeaderboardRepository {
  FakeLeaderboardRepository({
    required this.entriesByPeriod,
    required this.rivalriesByPeriod,
  });

  final Map<String, List<LeaderboardEntry>> entriesByPeriod;
  final Map<String, List<RivalryEntry>> rivalriesByPeriod;

  @override
  Stream<List<LeaderboardEntry>> watchPeriodEntries(String periodId) {
    return Stream.value(entriesByPeriod[periodId] ?? const <LeaderboardEntry>[]);
  }

  @override
  Stream<List<RivalryEntry>> watchPeriodRivalries(String periodId) {
    return Stream.value(rivalriesByPeriod[periodId] ?? const <RivalryEntry>[]);
  }

  @override
  Stream<LeaderboardEntry?> watchPlayerStats(
    String uid, {
    String periodId = 'all_time',
  }) {
    final list = entriesByPeriod[periodId] ?? const <LeaderboardEntry>[];
    for (final e in list) {
      if (e.uid == uid) return Stream.value(e);
    }
    return Stream.value(null);
  }
}

void main() {
  final fixedTime = DateTime.utc(2026, 10, 8, 12, 0); // 2026-W41
  final thisWeekId = getCurrentWeekPeriodId(fixedTime); // weekly_2026-W41

  final sampleEntries = <LeaderboardEntry>[
    const LeaderboardEntry(
      uid: 'u_arthur',
      screenName: 'Arthur',
      periodId: 'weekly_2026-W41',
      hangJacks: 5,
      jacksSaved: 3,
      highTrumps: 8,
      lowTrumps: 4,
      fivesWon: 6,
      ninesWon: 5,
      gamePointsWon: 7,
      bidsWon: 6,
      bidsMade: 5,
      gamesWon: 3,
      totalPointsEarned: 140,
      jacksHung: 1,
      ninesLost: 0,
      fivesLost: 1,
      bidsSet: 1,
      roundsPlayed: 15,
      gamesPlayed: 4,
    ),
    const LeaderboardEntry(
      uid: 'u_bob',
      screenName: 'Bob',
      periodId: 'weekly_2026-W41',
      hangJacks: 2,
      jacksSaved: 1,
      highTrumps: 3,
      lowTrumps: 6,
      fivesWon: 2,
      ninesWon: 2,
      gamePointsWon: 3,
      bidsWon: 5,
      bidsMade: 2,
      gamesWon: 1,
      totalPointsEarned: 72,
      jacksHung: 4,
      ninesLost: 3,
      fivesLost: 2,
      bidsSet: 3,
      roundsPlayed: 15,
      gamesPlayed: 4,
    ),
    const LeaderboardEntry(
      uid: 'u_charlie',
      screenName: 'Charlie',
      periodId: 'weekly_2026-W41',
      hangJacks: 1,
      jacksSaved: 2,
      highTrumps: 4,
      lowTrumps: 2,
      fivesWon: 4,
      ninesWon: 4,
      gamePointsWon: 5,
      bidsWon: 4,
      bidsMade: 3,
      gamesWon: 2,
      totalPointsEarned: 95,
      jacksHung: 2,
      ninesLost: 1,
      fivesLost: 3,
      bidsSet: 1,
      roundsPlayed: 15,
      gamesPlayed: 4,
    ),
  ];

  final sampleRivalries = <RivalryEntry>[
    const RivalryEntry(
      id: 'u_arthur_u_bob',
      periodId: 'weekly_2026-W41',
      actorUid: 'u_arthur',
      actorName: 'Arthur',
      victimUid: 'u_bob',
      victimName: 'Bob',
      jacksHung: 4,
      ninesStolen: 2,
      fivesStolen: 1,
      heistCount: 7,
      heistPoints: 35,
      matchesWonAgainst: 3,
    ),
    const RivalryEntry(
      id: 'u_charlie_u_arthur',
      periodId: 'weekly_2026-W41',
      actorUid: 'u_charlie',
      actorName: 'Charlie',
      victimUid: 'u_arthur',
      victimName: 'Arthur',
      jacksHung: 1,
      ninesStolen: 0,
      fivesStolen: 1,
      heistCount: 2,
      heistPoints: 8,
      matchesWonAgainst: 1,
    ),
  ];

  late FakeLeaderboardRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeLeaderboardRepository(
      entriesByPeriod: {
        thisWeekId: sampleEntries,
        'all_time': sampleEntries,
      },
      rivalriesByPeriod: {
        thisWeekId: sampleRivalries,
        'all_time': sampleRivalries,
      },
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: LeaderboardView(
          leaderboardRepository: fakeRepo,
          currentUserId: 'u_arthur',
          currentUserName: 'Arthur',
          referenceTime: fixedTime,
        ),
      ),
    );
  }

  testWidgets('renders Triumphs mode with Spotlight, Podium, and Ranked list', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Pedro Hall of Fame'), findsOneWidget);
    expect(find.text('The Jack Hanger'), findsWidgets);
    expect(find.text('Arthur'), findsWidgets);
    expect(find.text('Bob'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('YOU'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('YOU'), findsOneWidget);
  });

  testWidgets('switches to Hall of Shame and displays unfortunate distinctions', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('board_mode_hallOfShame')));
    await tester.pumpAndSettle();

    expect(find.text('Pedro Hall of Shame'), findsOneWidget);
    expect(find.text('Neck in the Noose'), findsWidgets);
    expect(find.text('Nine Donor'), findsWidgets);
    expect(find.text('Pedro Donor'), findsWidgets);
    expect(find.text('Biggest Buss'), findsWidgets);

    // Bob has 4 jacksHung in Neck in the Noose
    expect(find.text('4 Jacks Lost'), findsWidgets);
  });

  testWidgets('switches to Rivalries mode and shows Nemesis, Favorite Prey, and Hottest Feuds', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('board_mode_rivalries')));
    await tester.pumpAndSettle();

    expect(find.text('Nemesis & Prey Rivalries'), findsOneWidget);
    expect(find.text('😈 YOUR NEMESIS'), findsOneWidget);
    expect(find.text('🎯 FAVORITE PREY'), findsOneWidget);
    expect(find.text('🔥 HOTTEST TABLE FEUDS'), findsOneWidget);
    expect(find.text('Arthur → Bob'), findsOneWidget);
    expect(find.text('Charlie → Arthur'), findsOneWidget);
  });

  testWidgets('tapping an opponent opens the Head-to-Head Tale of the Tape modal', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final bobRow = find.byKey(const ValueKey('rank_row_u_bob'));
    await tester.scrollUntilVisible(
      bobRow,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(bobRow);
    await tester.pumpAndSettle();

    expect(find.textContaining('TALE OF THE TAPE'), findsOneWidget);
    expect(find.text('🏆 Match Wins Together'), findsOneWidget);
    expect(find.text('🪝 Jacks Hung (+3 pts)'), findsOneWidget);
    expect(find.text('🎯 9 of Trumps Stolen (+9 pts)'), findsOneWidget);
    expect(find.text('🖐️ 5 of Trumps Stolen (+5 pts)'), findsOneWidget);
    expect(find.text('⚡ Total Heist Points Stolen'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);
  });
}
