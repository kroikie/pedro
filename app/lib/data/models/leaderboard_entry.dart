import 'package:dart_mappable/dart_mappable.dart';

part 'leaderboard_entry.mapper.dart';

/// Computes the ISO-8601 week identifier (e.g. `'2026-W41'`) for [utcTime].
String getIsoWeekIdForDate(DateTime utcTime) {
  final utc = utcTime.toUtc();
  final date = DateTime.utc(utc.year, utc.month, utc.day);
  final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
  final isoYear = thursday.year;
  final jan4 = DateTime.utc(isoYear, 1, 4);
  final firstThursday = jan4.add(
    Duration(days: DateTime.thursday - jan4.weekday),
  );
  final weekNumber = 1 + (thursday.difference(firstThursday).inDays ~/ 7);
  return '$isoYear-W${weekNumber.toString().padLeft(2, '0')}';
}

/// Returns the Firestore leaderboard period ID for the current ISO week.
String getCurrentWeekPeriodId([DateTime? now]) {
  final ref = (now ?? DateTime.now()).toUtc();
  return 'weekly_${getIsoWeekIdForDate(ref)}';
}

/// Returns the Firestore leaderboard period ID for the previous ISO week.
String getLastWeekPeriodId([DateTime? now]) {
  final ref = (now ?? DateTime.now()).toUtc().subtract(const Duration(days: 7));
  return 'weekly_${getIsoWeekIdForDate(ref)}';
}

@MappableEnum()
enum LeaderboardCategory {
  // Triumphs (Hall of Fame)
  hangJacks(
    title: 'The Jack Hanger',
    shortLabel: 'Jack Hanger',
    unitLabel: 'Jacks Hung',
    description: "Most times capturing an opponent's Jack of trumps (+3 pts)",
    badgeEmoji: '🪝',
    isUnfortunate: false,
  ),
  highTrumps(
    title: 'Higher than High',
    shortLabel: 'High Trumps',
    unitLabel: 'High Trumps',
    description: 'Most times winning the High trump point',
    badgeEmoji: '👑',
    isUnfortunate: false,
  ),
  lowTrumps(
    title: 'Lower than Low',
    shortLabel: 'Low Trumps',
    unitLabel: 'Low Trumps',
    description: 'Most times winning the Low trump point',
    badgeEmoji: '⚓',
    isUnfortunate: false,
  ),
  gamesWon(
    title: 'Table Boss',
    shortLabel: 'Matches Won',
    unitLabel: 'Wins',
    description: 'Most full Pedro matches won',
    badgeEmoji: '🏆',
    isUnfortunate: false,
  ),
  fivesWon(
    title: 'Pedro Catcher',
    shortLabel: '5s Won',
    unitLabel: '5s Won',
    description: 'Most times winning a lift containing the 5 of trumps',
    badgeEmoji: '🖐️',
    isUnfortunate: false,
  ),
  ninesWon(
    title: 'Nine Hunter',
    shortLabel: '9s Won',
    unitLabel: '9s Won',
    description: 'Most times winning a lift containing the 9 of trumps',
    badgeEmoji: '🎯',
    isUnfortunate: false,
  ),
  bidsMade(
    title: 'Contract Boss',
    shortLabel: 'Bids Made',
    unitLabel: 'Bids Made',
    description: 'Most winning bids successfully made',
    badgeEmoji: '📜',
    isUnfortunate: false,
  ),
  gamePointsWon(
    title: 'Point Hoarder',
    shortLabel: 'Game Points',
    unitLabel: 'Game Pts',
    description: "Most times winning the round's Game point (card values)",
    badgeEmoji: '💰',
    isUnfortunate: false,
  ),

  // Unfortunate Distinctions (Hall of Shame)
  jacksHung(
    title: 'Neck in the Noose',
    shortLabel: 'Jacks Hung',
    unitLabel: 'Jacks Lost',
    description: "Most times getting your Jack of trumps hung by an opponent",
    badgeEmoji: '🪢',
    isUnfortunate: true,
  ),
  ninesLost(
    title: 'Nine Donor',
    shortLabel: '9s Lost',
    unitLabel: '9s Lost',
    description: 'Most times playing the 9 of trumps and losing the lift',
    badgeEmoji: '💸',
    isUnfortunate: true,
  ),
  fivesLost(
    title: 'Pedro Donor',
    shortLabel: '5s Lost',
    unitLabel: '5s Lost',
    description: 'Most times playing the 5 of trumps and losing the lift',
    badgeEmoji: '🎁',
    isUnfortunate: true,
  ),
  bidsSet(
    title: 'Biggest Buss',
    shortLabel: 'Bids Set',
    unitLabel: 'Times Buss',
    description: 'Most times winning the bid and failing to make the contract',
    badgeEmoji: '💥',
    isUnfortunate: true,
  );

  const LeaderboardCategory({
    required this.title,
    required this.shortLabel,
    required this.unitLabel,
    required this.description,
    required this.badgeEmoji,
    required this.isUnfortunate,
  });

  final String title;
  final String shortLabel;
  final String unitLabel;
  final String description;
  final String badgeEmoji;
  final bool isUnfortunate;

  static List<LeaderboardCategory> get triumphs =>
      values.where((c) => !c.isUnfortunate).toList();

  static List<LeaderboardCategory> get hallOfShame =>
      values.where((c) => c.isUnfortunate).toList();
}

@MappableClass()
class LeaderboardEntry with LeaderboardEntryMappable {
  final String uid;
  final String screenName;
  final String? avatarUrl;
  final String periodId;

  // Triumph counters
  final int hangJacks;
  final int jacksSaved;
  final int highTrumps;
  final int lowTrumps;
  final int fivesWon;
  final int ninesWon;
  final int gamePointsWon;
  final int bidsWon;
  final int bidsMade;
  final int gamesWon;
  final int totalPointsEarned;

  // Unfortunate (Hall of Shame) counters
  final int jacksHung;
  final int ninesLost;
  final int fivesLost;
  final int bidsSet;

  // Participation counters
  final int roundsPlayed;
  final int gamesPlayed;
  final DateTime? updatedAt;

  const LeaderboardEntry({
    required this.uid,
    required this.screenName,
    this.avatarUrl,
    this.periodId = 'all_time',
    this.hangJacks = 0,
    this.jacksSaved = 0,
    this.highTrumps = 0,
    this.lowTrumps = 0,
    this.fivesWon = 0,
    this.ninesWon = 0,
    this.gamePointsWon = 0,
    this.bidsWon = 0,
    this.bidsMade = 0,
    this.gamesWon = 0,
    this.totalPointsEarned = 0,
    this.jacksHung = 0,
    this.ninesLost = 0,
    this.fivesLost = 0,
    this.bidsSet = 0,
    this.roundsPlayed = 0,
    this.gamesPlayed = 0,
    this.updatedAt,
  });

  double get winRate =>
      gamesPlayed > 0 ? (gamesWon / gamesPlayed).clamp(0.0, 1.0) : 0.0;

  int get winRatePercent => (winRate * 100).round();

  int get bidSuccessRatePercent =>
      bidsWon > 0 ? ((bidsMade / bidsWon).clamp(0.0, 1.0) * 100).round() : 0;

  int valueForCategory(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.hangJacks:
        return hangJacks;
      case LeaderboardCategory.highTrumps:
        return highTrumps;
      case LeaderboardCategory.lowTrumps:
        return lowTrumps;
      case LeaderboardCategory.gamesWon:
        return gamesWon;
      case LeaderboardCategory.fivesWon:
        return fivesWon;
      case LeaderboardCategory.ninesWon:
        return ninesWon;
      case LeaderboardCategory.bidsMade:
        return bidsMade;
      case LeaderboardCategory.gamePointsWon:
        return gamePointsWon;
      case LeaderboardCategory.jacksHung:
        return jacksHung;
      case LeaderboardCategory.ninesLost:
        return ninesLost;
      case LeaderboardCategory.fivesLost:
        return fivesLost;
      case LeaderboardCategory.bidsSet:
        return bidsSet;
    }
  }

  String secondarySubtitleForCategory(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.hangJacks:
        return '$jacksSaved saved • $roundsPlayed rounds';
      case LeaderboardCategory.gamesWon:
        return '$gamesPlayed matches ($winRatePercent% win rate)';
      case LeaderboardCategory.bidsMade:
        return '$bidsMade/$bidsWon contracts ($bidSuccessRatePercent%)';
      case LeaderboardCategory.bidsSet:
        return '$bidsSet of $bidsWon bids went buss';
      case LeaderboardCategory.jacksHung:
        return 'Hung $jacksHung× across $roundsPlayed rounds';
      case LeaderboardCategory.ninesLost:
        return 'Lost 9 of trumps $ninesLost× ($ninesWon won)';
      case LeaderboardCategory.fivesLost:
        return 'Lost 5 of trumps $fivesLost× ($fivesWon won)';
      default:
        return '$roundsPlayed rounds • $totalPointsEarned total pts';
    }
  }

  static const fromMap = LeaderboardEntryMapper.fromMap;
}

@MappableClass()
class RivalryEntry with RivalryEntryMappable {
  final String id;
  final String periodId;
  final String actorUid;
  final String actorName;
  final String? actorAvatarUrl;
  final String victimUid;
  final String victimName;
  final String? victimAvatarUrl;
  final int jacksHung;
  final int ninesStolen;
  final int fivesStolen;
  final int heistCount;
  final int heistPoints;
  final int matchesWonAgainst;
  final DateTime? updatedAt;

  const RivalryEntry({
    required this.id,
    this.periodId = 'all_time',
    required this.actorUid,
    required this.actorName,
    this.actorAvatarUrl,
    required this.victimUid,
    required this.victimName,
    this.victimAvatarUrl,
    this.jacksHung = 0,
    this.ninesStolen = 0,
    this.fivesStolen = 0,
    this.heistCount = 0,
    this.heistPoints = 0,
    this.matchesWonAgainst = 0,
    this.updatedAt,
  });

  int get dominanceScore => heistPoints + (matchesWonAgainst * 10);

  String get breakdownSummary {
    final parts = <String>[];
    if (jacksHung > 0) {
      parts.add('$jacksHung ${jacksHung == 1 ? "Jack" : "Jacks"} Hung');
    }
    if (ninesStolen > 0) {
      parts.add('$ninesStolen ${ninesStolen == 1 ? "Nine" : "Nines"} Stolen');
    }
    if (fivesStolen > 0) {
      parts.add('$fivesStolen ${fivesStolen == 1 ? "Pedro" : "Pedros"} Stolen');
    }
    if (matchesWonAgainst > 0) {
      parts.add(
        '$matchesWonAgainst ${matchesWonAgainst == 1 ? "Match" : "Matches"} Won',
      );
    }
    if (parts.isEmpty) {
      return 'No heists recorded yet';
    }
    return parts.join(' • ');
  }

  static const fromMap = RivalryEntryMapper.fromMap;
}
