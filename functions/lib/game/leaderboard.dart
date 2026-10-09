import 'package:google_cloud_firestore/google_cloud_firestore.dart';

/// Player profile metadata used to enrich archived rounds, leaderboard rollups,
/// and head-to-head rivalry records.
class PlayerProfileInfo {
  final String uid;
  final String screenName;
  final String? avatarUrl;

  const PlayerProfileInfo({
    required this.uid,
    required this.screenName,
    this.avatarUrl,
  });
}

/// Results of inspecting `completedLifts` for a round's trump suit special cards.
class RoundLiftAnalysis {
  final String? hangJackWinnerId;
  final String? jackHungVictimId;
  final String? savedJackWinnerId;
  final String? nineTrumpWinnerId;
  final String? nineTrumpLoserId;
  final String? fiveTrumpWinnerId;
  final String? fiveTrumpLoserId;

  const RoundLiftAnalysis({
    this.hangJackWinnerId,
    this.jackHungVictimId,
    this.savedJackWinnerId,
    this.nineTrumpWinnerId,
    this.nineTrumpLoserId,
    this.fiveTrumpWinnerId,
    this.fiveTrumpLoserId,
  });
}

/// Summary of a deterministic leaderboard reconciliation run.
class LeaderboardRebuildSummary {
  final bool isDryRun;
  final int gamesWithRoundsReconciled;
  final int legacyGamesIgnored;
  final int totalRoundsScanned;
  final List<String> periodsRebuilt;
  final int playerRollupsWritten;
  final int rivalryRollupsWritten;

  const LeaderboardRebuildSummary({
    required this.isDryRun,
    required this.gamesWithRoundsReconciled,
    required this.legacyGamesIgnored,
    required this.totalRoundsScanned,
    required this.periodsRebuilt,
    required this.playerRollupsWritten,
    required this.rivalryRollupsWritten,
  });
}

/// Computes the ISO-8601 week identifier (e.g. `'2026-W41'`) for [utcTime].
String getIsoWeekId(DateTime utcTime) {
  final utc = utcTime.toUtc();
  final date = DateTime.utc(utc.year, utc.month, utc.day);
  // Shift to Thursday of the same ISO week (Monday = 1 ... Sunday = 7)
  final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
  final isoYear = thursday.year;
  final jan4 = DateTime.utc(isoYear, 1, 4);
  final firstThursday = jan4.add(
    Duration(days: DateTime.thursday - jan4.weekday),
  );
  final weekNumber = 1 + (thursday.difference(firstThursday).inDays ~/ 7);
  return '$isoYear-W${weekNumber.toString().padLeft(2, '0')}';
}

/// Computes the weekly leaderboard period document ID (e.g. `'weekly_2026-W41'`).
String getWeeklyPeriodId(DateTime utcTime) =>
    'weekly_${getIsoWeekId(utcTime)}';

/// Inspects [completedLifts] for the [trumpSuit] Jack, 9, and 5 to identify
/// both the winners and the unfortunate victims who lost those trump cards.
RoundLiftAnalysis analyzeRoundLifts({
  required List<Map<String, dynamic>> completedLifts,
  required String trumpSuit,
}) {
  String? hangJackWinnerId;
  String? jackHungVictimId;
  String? savedJackWinnerId;
  String? nineTrumpWinnerId;
  String? nineTrumpLoserId;
  String? fiveTrumpWinnerId;
  String? fiveTrumpLoserId;

  for (final lift in completedLifts) {
    final winnerId = lift['winnerId'] as String?;
    if (winnerId == null || winnerId.isEmpty) continue;

    final rawPlays = lift['plays'];
    if (rawPlays is! Map) continue;

    for (final entry in rawPlays.entries) {
      final playerId = entry.key.toString();
      final cardVal = entry.value;
      if (cardVal is! Map) continue;

      final suit = cardVal['suit'] as String?;
      final rank = cardVal['rank'] as String?;
      if (suit != trumpSuit || rank == null) continue;

      if (rank == 'jack') {
        if (playerId == winnerId) {
          savedJackWinnerId = winnerId;
        } else {
          hangJackWinnerId = winnerId;
          jackHungVictimId = playerId;
        }
      } else if (rank == 'nine') {
        nineTrumpWinnerId = winnerId;
        if (playerId != winnerId) {
          nineTrumpLoserId = playerId;
        }
      } else if (rank == 'five') {
        fiveTrumpWinnerId = winnerId;
        if (playerId != winnerId) {
          fiveTrumpLoserId = playerId;
        }
      }
    }
  }

  return RoundLiftAnalysis(
    hangJackWinnerId: hangJackWinnerId,
    jackHungVictimId: jackHungVictimId,
    savedJackWinnerId: savedJackWinnerId,
    nineTrumpWinnerId: nineTrumpWinnerId,
    nineTrumpLoserId: nineTrumpLoserId,
    fiveTrumpWinnerId: fiveTrumpWinnerId,
    fiveTrumpLoserId: fiveTrumpLoserId,
  );
}

/// Computes per-player round summary entries with numeric `0`/`1` stat deltas
/// for all Triumph and Hall of Shame categories.
List<Map<String, dynamic>> extractPlayerRoundStatDeltas({
  required List<Map<String, dynamic>> playerStates,
  required Map<String, int> previousTotalScores,
  required Map<String, PlayerProfileInfo> playerProfiles,
  required List<Map<String, dynamic>> completedLifts,
  required RoundLiftAnalysis liftAnalysis,
  required String bidWinnerId,
  required bool bidSuccess,
  required String? highTrumpPlayerId,
  required String? lowTrumpPlayerId,
  required String? gameWinnerId,
  required String? matchWinnerId,
}) {
  final summaries = <Map<String, dynamic>>[];

  for (final ps in playerStates) {
    final uid = ps['uid'] as String;
    final profile = playerProfiles[uid];
    final roundPoints = (ps['currentRoundPoints'] as num?)?.toInt() ?? 0;
    final newTotalScore = (ps['totalScore'] as num?)?.toInt() ?? 0;
    final prevTotalScore = previousTotalScores[uid] ?? newTotalScore;
    final wonLiftsCount =
        completedLifts.where((l) => l['winnerId'] == uid).length;

    summaries.add({
      'uid': uid,
      'screenName': profile?.screenName ?? 'Player',
      'avatarUrl': profile?.avatarUrl,
      'pointsEarned': roundPoints,
      'roundPoints': roundPoints,
      'previousTotalScore': prevTotalScore,
      'newTotalScore': newTotalScore,
      'totalScore': newTotalScore,
      'earnedPoints': List<String>.from(ps['earnedPoints'] as Iterable? ?? []),
      'gameValue': (ps['gameValue'] as num?)?.toInt() ?? 0,
      'capturedValueCards': List<Map<String, dynamic>>.from(
        ps['capturedValueCards'] as Iterable? ?? [],
      ),
      'wonLiftsCount': wonLiftsCount,
      // Triumph (Hall of Fame) deltas
      'hangJacks': liftAnalysis.hangJackWinnerId == uid ? 1 : 0,
      'jacksSaved': liftAnalysis.savedJackWinnerId == uid ? 1 : 0,
      'highTrumps': highTrumpPlayerId == uid ? 1 : 0,
      'lowTrumps': lowTrumpPlayerId == uid ? 1 : 0,
      'fivesWon': liftAnalysis.fiveTrumpWinnerId == uid ? 1 : 0,
      'ninesWon': liftAnalysis.nineTrumpWinnerId == uid ? 1 : 0,
      'gamePointsWon': gameWinnerId == uid ? 1 : 0,
      'bidsWon': bidWinnerId == uid ? 1 : 0,
      'bidsMade': (bidWinnerId == uid && bidSuccess) ? 1 : 0,
      'gamesWon': (matchWinnerId != null && matchWinnerId == uid) ? 1 : 0,
      // Unfortunate (Hall of Shame) deltas
      'jacksHung': liftAnalysis.jackHungVictimId == uid ? 1 : 0,
      'ninesLost': liftAnalysis.nineTrumpLoserId == uid ? 1 : 0,
      'fivesLost': liftAnalysis.fiveTrumpLoserId == uid ? 1 : 0,
      'bidsSet': (bidWinnerId == uid && !bidSuccess) ? 1 : 0,
      // Participation counters
      'roundsPlayed': 1,
      'gamesPlayed': matchWinnerId != null ? 1 : 0,
    });
  }

  return summaries;
}

/// Computes directed `(actorUid -> victimUid)` rivalry records for a round,
/// combining card heists (Jack hung, 9 stolen, 5 stolen) and match wins.
List<Map<String, dynamic>> extractRivalryDeltas({
  required List<String> playerIds,
  required Map<String, PlayerProfileInfo> playerProfiles,
  required RoundLiftAnalysis liftAnalysis,
  required String? matchWinnerId,
}) {
  final byPair = <String, Map<String, dynamic>>{};

  Map<String, dynamic> ensurePair(String actorUid, String victimUid) {
    final pairId = '${actorUid}_$victimUid';
    return byPair.putIfAbsent(pairId, () {
      final actor = playerProfiles[actorUid];
      final victim = playerProfiles[victimUid];
      return {
        'id': pairId,
        'actorUid': actorUid,
        'actorName': actor?.screenName ?? 'Player',
        'actorAvatarUrl': actor?.avatarUrl,
        'victimUid': victimUid,
        'victimName': victim?.screenName ?? 'Player',
        'victimAvatarUrl': victim?.avatarUrl,
        'jacksHung': 0,
        'ninesStolen': 0,
        'fivesStolen': 0,
        'heistCount': 0,
        'heistPoints': 0,
        'matchesWonAgainst': 0,
      };
    });
  }

  // 1. Jack of Trumps Hung (+3 heist points)
  if (liftAnalysis.hangJackWinnerId != null &&
      liftAnalysis.jackHungVictimId != null &&
      liftAnalysis.hangJackWinnerId != liftAnalysis.jackHungVictimId) {
    final entry = ensurePair(
      liftAnalysis.hangJackWinnerId!,
      liftAnalysis.jackHungVictimId!,
    );
    entry['jacksHung'] = (entry['jacksHung'] as int) + 1;
    entry['heistCount'] = (entry['heistCount'] as int) + 1;
    entry['heistPoints'] = (entry['heistPoints'] as int) + 3;
  }

  // 2. Nine of Trumps Stolen (+9 heist points)
  if (liftAnalysis.nineTrumpWinnerId != null &&
      liftAnalysis.nineTrumpLoserId != null &&
      liftAnalysis.nineTrumpWinnerId != liftAnalysis.nineTrumpLoserId) {
    final entry = ensurePair(
      liftAnalysis.nineTrumpWinnerId!,
      liftAnalysis.nineTrumpLoserId!,
    );
    entry['ninesStolen'] = (entry['ninesStolen'] as int) + 1;
    entry['heistCount'] = (entry['heistCount'] as int) + 1;
    entry['heistPoints'] = (entry['heistPoints'] as int) + 9;
  }

  // 3. Five of Trumps Stolen (+5 heist points)
  if (liftAnalysis.fiveTrumpWinnerId != null &&
      liftAnalysis.fiveTrumpLoserId != null &&
      liftAnalysis.fiveTrumpWinnerId != liftAnalysis.fiveTrumpLoserId) {
    final entry = ensurePair(
      liftAnalysis.fiveTrumpWinnerId!,
      liftAnalysis.fiveTrumpLoserId!,
    );
    entry['fivesStolen'] = (entry['fivesStolen'] as int) + 1;
    entry['heistCount'] = (entry['heistCount'] as int) + 1;
    entry['heistPoints'] = (entry['heistPoints'] as int) + 5;
  }

  // 4. Match Victory over seated opponents
  if (matchWinnerId != null && matchWinnerId.isNotEmpty) {
    for (final otherUid in playerIds) {
      if (otherUid == matchWinnerId) continue;
      final entry = ensurePair(matchWinnerId, otherUid);
      entry['matchesWonAgainst'] = (entry['matchesWonAgainst'] as int) + 1;
    }
  }

  return byPair.values.toList();
}

/// Builds the complete `games/{gameId}/rounds/round_{roundNumber}` archive document.
Map<String, dynamic> buildArchivedRoundDocument({
  required String gameId,
  required int roundNumber,
  required DateTime completedAtUtc,
  required List<String> playerIds,
  required String dealerId,
  required String trumpSuit,
  required String bidWinnerId,
  required int bidValue,
  required bool bidSuccess,
  required String? highTrumpPlayerId,
  required Map<String, dynamic>? highTrumpPlayedCard,
  required String? lowTrumpPlayerId,
  required Map<String, dynamic>? lowTrumpPlayedCard,
  required RoundLiftAnalysis liftAnalysis,
  required String? gameWinnerId,
  required int gameWinningScore,
  required bool isGameTied,
  required String? matchWinnerId,
  required List<Map<String, dynamic>> playerSummaries,
  required List<Map<String, dynamic>> heists,
  required List<Map<String, dynamic>> completedLifts,
  Object? completedAtFieldValue,
}) {
  final isoWeek = getIsoWeekId(completedAtUtc);
  return {
    'gameId': gameId,
    'roundNumber': roundNumber,
    'completedAt': completedAtFieldValue ?? Timestamp.fromDate(completedAtUtc),
    'isoWeek': isoWeek,
    'playerCount': playerIds.length,
    'playerIds': playerIds,
    'dealerId': dealerId,
    'trumpSuit': trumpSuit,
    'bidWinnerId': bidWinnerId,
    'bidValue': bidValue,
    'bidSuccess': bidSuccess,
    'bidMadeWinnerId': bidSuccess ? bidWinnerId : null,
    'bidSetLoserId': bidSuccess ? null : bidWinnerId,
    'highTrumpPlayerId': highTrumpPlayerId,
    'highTrumpPlayedCard': highTrumpPlayedCard,
    'lowTrumpPlayerId': lowTrumpPlayerId,
    'lowTrumpPlayedCard': lowTrumpPlayedCard,
    'hangJackWinnerId': liftAnalysis.hangJackWinnerId,
    'jackHungVictimId': liftAnalysis.jackHungVictimId,
    'savedJackWinnerId': liftAnalysis.savedJackWinnerId,
    'fiveTrumpWinnerId': liftAnalysis.fiveTrumpWinnerId,
    'fiveTrumpLoserId': liftAnalysis.fiveTrumpLoserId,
    'nineTrumpWinnerId': liftAnalysis.nineTrumpWinnerId,
    'nineTrumpLoserId': liftAnalysis.nineTrumpLoserId,
    'gameWinnerId': gameWinnerId,
    'gameWinningScore': gameWinningScore,
    'isGameTied': isGameTied,
    'matchWinnerId': matchWinnerId,
    'playerSummaries': playerSummaries,
    'heists': heists,
    'completedLifts': completedLifts,
  };
}

const List<String> _playerCounterFields = <String>[
  'hangJacks',
  'jacksSaved',
  'highTrumps',
  'lowTrumps',
  'fivesWon',
  'ninesWon',
  'gamePointsWon',
  'bidsWon',
  'bidsMade',
  'gamesWon',
  'jacksHung',
  'ninesLost',
  'fivesLost',
  'bidsSet',
  'roundsPlayed',
  'gamesPlayed',
];

const List<String> _rivalryCounterFields = <String>[
  'jacksHung',
  'ninesStolen',
  'fivesStolen',
  'heistCount',
  'heistPoints',
  'matchesWonAgainst',
];

/// Fetches `screenName` and `avatarUrl` for all [playerIds] from `users/{uid}`.
Future<Map<String, PlayerProfileInfo>> fetchPlayerProfiles(
  Firestore firestore,
  Iterable<String> playerIds,
) async {
  final uniqueIds = playerIds.toSet().toList();
  final profiles = <String, PlayerProfileInfo>{};
  if (uniqueIds.isEmpty) return profiles;

  for (final uid in uniqueIds) {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();
      final screenName =
          (data?['screenName'] ?? data?['displayName'] ?? 'Player') as String;
      final avatarUrl = data?['avatarUrl'] as String?;
      profiles[uid] = PlayerProfileInfo(
        uid: uid,
        screenName: screenName,
        avatarUrl: avatarUrl,
      );
    } catch (_) {
      profiles[uid] = PlayerProfileInfo(uid: uid, screenName: 'Player');
    }
  }
  return profiles;
}

/// Enqueues the `games/{gameId}/rounds/round_{N}` archive write and all
/// `leaderboards/{periodId}/players/{uid}` and `leaderboards/{periodId}/rivalries/{pairId}`
/// atomic `FieldValue.increment` mutations onto [batch].
void addRoundArchiveAndLeaderboardToBatch({
  required Firestore firestore,
  required WriteBatch batch,
  required DocumentReference<DocumentData> gameRef,
  required int roundNumber,
  required Map<String, dynamic> archivedRoundDoc,
}) {
  final roundRef = gameRef.collection('rounds').doc('round_$roundNumber');
  batch.set(roundRef, archivedRoundDoc);

  final isoWeek = archivedRoundDoc['isoWeek'] as String;
  final periods = <String>['all_time', 'weekly_$isoWeek'];
  final playerSummaries = List<Map<String, dynamic>>.from(
    archivedRoundDoc['playerSummaries'] as Iterable? ?? const [],
  );
  final heists = List<Map<String, dynamic>>.from(
    archivedRoundDoc['heists'] as Iterable? ?? const [],
  );

  for (final periodId in periods) {
    final periodRef = firestore.collection('leaderboards').doc(periodId);
    batch.set(
      periodRef,
      {
        'periodId': periodId,
        'updatedAt': FieldValue.serverTimestamp,
      },
      options: const SetOptions.merge(),
    );

    for (final ps in playerSummaries) {
      final uid = ps['uid'] as String;
      final playerRef = periodRef.collection('players').doc(uid);
      final pointsEarned = (ps['pointsEarned'] as num?)?.toInt() ??
          (ps['roundPoints'] as num?)?.toInt() ??
          0;

      final payload = <String, Object?>{
        'uid': uid,
        'screenName': ps['screenName'] ?? 'Player',
        if (ps['avatarUrl'] != null) 'avatarUrl': ps['avatarUrl'],
        'periodId': periodId,
        'totalPointsEarned': FieldValue.increment(pointsEarned),
        'updatedAt': FieldValue.serverTimestamp,
      };

      for (final field in _playerCounterFields) {
        final delta = (ps[field] as num?)?.toInt() ?? 0;
        payload[field] = FieldValue.increment(delta);
      }

      batch.set(playerRef, payload, options: const SetOptions.merge());
    }

    for (final heist in heists) {
      final actorUid = heist['actorUid'] as String;
      final victimUid = heist['victimUid'] as String;
      final pairId = (heist['id'] as String?) ?? '${actorUid}_$victimUid';
      final rivalryRef = periodRef.collection('rivalries').doc(pairId);

      final payload = <String, Object?>{
        'id': pairId,
        'periodId': periodId,
        'actorUid': actorUid,
        'actorName': heist['actorName'] ?? 'Player',
        if (heist['actorAvatarUrl'] != null)
          'actorAvatarUrl': heist['actorAvatarUrl'],
        'victimUid': victimUid,
        'victimName': heist['victimName'] ?? 'Player',
        if (heist['victimAvatarUrl'] != null)
          'victimAvatarUrl': heist['victimAvatarUrl'],
        'updatedAt': FieldValue.serverTimestamp,
      };

      for (final field in _rivalryCounterFields) {
        final delta = (heist[field] as num?)?.toInt() ?? 0;
        payload[field] = FieldValue.increment(delta);
      }

      batch.set(rivalryRef, payload, options: const SetOptions.merge());
    }
  }
}

/// Reverses a game's archived rounds from `leaderboards/*` and deletes its
/// `games/{gameId}/rounds/*` documents when `deleteGame` is called.
///
/// Legacy games that do not have any documents in `games/{gameId}/rounds`
/// are cleanly ignored.
Future<void> rollbackGameLeaderboardStats({
  required Firestore firestore,
  required DocumentReference<DocumentData> gameRef,
}) async {
  final roundsSnapshot = await gameRef.collection('rounds').get();
  if (roundsSnapshot.docs.isEmpty) {
    // Legacy game without persisted rounds: ignore leaderboard rollups.
    return;
  }

  final roundDocs = roundsSnapshot.docs.map((d) => d.data()).toList();
  final aggregated = aggregateArchivedRounds(roundDocs);

  final batch = firestore.batch();

  // 1. Delete all archived round documents under this game
  for (final doc in roundsSnapshot.docs) {
    batch.delete(doc.ref);
  }

  // 2. Apply negative FieldValue.increment(-delta) to each affected period
  for (final periodEntry in aggregated.playersByPeriod.entries) {
    final periodId = periodEntry.key;
    final periodRef = firestore.collection('leaderboards').doc(periodId);

    for (final playerEntry in periodEntry.value.entries) {
      final uid = playerEntry.key;
      final stats = playerEntry.value;
      final playerRef = periodRef.collection('players').doc(uid);

      final payload = <String, Object?>{
        'updatedAt': FieldValue.serverTimestamp,
      };
      final pointsDelta = (stats['totalPointsEarned'] as num?)?.toInt() ?? 0;
      if (pointsDelta != 0) {
        payload['totalPointsEarned'] = FieldValue.increment(-pointsDelta);
      }
      for (final field in _playerCounterFields) {
        final delta = (stats[field] as num?)?.toInt() ?? 0;
        if (delta != 0) {
          payload[field] = FieldValue.increment(-delta);
        }
      }
      batch.set(playerRef, payload, options: const SetOptions.merge());
    }
  }

  for (final periodEntry in aggregated.rivalriesByPeriod.entries) {
    final periodId = periodEntry.key;
    final periodRef = firestore.collection('leaderboards').doc(periodId);

    for (final rivalryEntry in periodEntry.value.entries) {
      final pairId = rivalryEntry.key;
      final stats = rivalryEntry.value;
      final rivalryRef = periodRef.collection('rivalries').doc(pairId);

      final payload = <String, Object?>{
        'updatedAt': FieldValue.serverTimestamp,
      };
      for (final field in _rivalryCounterFields) {
        final delta = (stats[field] as num?)?.toInt() ?? 0;
        if (delta != 0) {
          payload[field] = FieldValue.increment(-delta);
        }
      }
      batch.set(rivalryRef, payload, options: const SetOptions.merge());
    }
  }

  await batch.commit();
}

/// Pure in-memory aggregation result produced by [aggregateArchivedRounds].
class AggregatedLeaderboardData {
  /// `periodId -> uid -> player rollup document map`
  final Map<String, Map<String, Map<String, dynamic>>> playersByPeriod;

  /// `periodId -> pairId -> rivalry rollup document map`
  final Map<String, Map<String, Map<String, dynamic>>> rivalriesByPeriod;

  /// Distinct `gameId`s represented in the archived rounds.
  final Set<String> reconciledGameIds;

  /// Total archived round documents processed.
  final int totalRoundsProcessed;

  const AggregatedLeaderboardData({
    required this.playersByPeriod,
    required this.rivalriesByPeriod,
    required this.reconciledGameIds,
    required this.totalRoundsProcessed,
  });
}

/// Deterministically aggregates a collection of archived round documents into
/// `all_time` and `weekly_{isoWeek}` player and rivalry rollup maps.
///
/// Games that do not have archived round documents are naturally excluded.
AggregatedLeaderboardData aggregateArchivedRounds(
  Iterable<Map<String, dynamic>> roundDocs, {
  Map<String, PlayerProfileInfo> latestProfiles = const {},
}) {
  final playersByPeriod = <String, Map<String, Map<String, dynamic>>>{};
  final rivalriesByPeriod = <String, Map<String, Map<String, dynamic>>>{};
  final reconciledGameIds = <String>{};
  int totalRoundsProcessed = 0;

  for (final round in roundDocs) {
    final isoWeek = round['isoWeek'] as String?;
    if (isoWeek == null || isoWeek.isEmpty) continue;

    final gameId = round['gameId'] as String?;
    if (gameId != null && gameId.isNotEmpty) {
      reconciledGameIds.add(gameId);
    }
    totalRoundsProcessed++;

    final periods = <String>['all_time', 'weekly_$isoWeek'];
    final playerSummaries = List<Map<String, dynamic>>.from(
      round['playerSummaries'] as Iterable? ?? const [],
    );
    final heists = List<Map<String, dynamic>>.from(
      round['heists'] as Iterable? ?? const [],
    );

    for (final periodId in periods) {
      final periodPlayers = playersByPeriod.putIfAbsent(
        periodId,
        () => <String, Map<String, dynamic>>{},
      );
      final periodRivalries = rivalriesByPeriod.putIfAbsent(
        periodId,
        () => <String, Map<String, dynamic>>{},
      );

      for (final ps in playerSummaries) {
        final uid = ps['uid'] as String?;
        if (uid == null || uid.isEmpty) continue;

        final latestProfile = latestProfiles[uid];
        final screenName = latestProfile?.screenName ??
            (ps['screenName'] as String?) ??
            'Player';
        final avatarUrl =
            latestProfile?.avatarUrl ?? (ps['avatarUrl'] as String?);

        final accum = periodPlayers.putIfAbsent(uid, () {
          final map = <String, dynamic>{
            'uid': uid,
            'screenName': screenName,
            'avatarUrl': avatarUrl,
            'periodId': periodId,
            'totalPointsEarned': 0,
          };
          for (final field in _playerCounterFields) {
            map[field] = 0;
          }
          return map;
        });

        accum['screenName'] = screenName;
        if (avatarUrl != null) {
          accum['avatarUrl'] = avatarUrl;
        }

        final pointsEarned = (ps['pointsEarned'] as num?)?.toInt() ??
            (ps['roundPoints'] as num?)?.toInt() ??
            0;
        accum['totalPointsEarned'] =
            (accum['totalPointsEarned'] as int) + pointsEarned;

        for (final field in _playerCounterFields) {
          final delta = (ps[field] as num?)?.toInt() ?? 0;
          accum[field] = (accum[field] as int) + delta;
        }
      }

      for (final heist in heists) {
        final actorUid = heist['actorUid'] as String?;
        final victimUid = heist['victimUid'] as String?;
        if (actorUid == null ||
            actorUid.isEmpty ||
            victimUid == null ||
            victimUid.isEmpty) {
          continue;
        }

        final pairId = (heist['id'] as String?) ?? '${actorUid}_$victimUid';
        final latestActor = latestProfiles[actorUid];
        final latestVictim = latestProfiles[victimUid];

        final actorName = latestActor?.screenName ??
            (heist['actorName'] as String?) ??
            'Player';
        final actorAvatarUrl =
            latestActor?.avatarUrl ?? (heist['actorAvatarUrl'] as String?);
        final victimName = latestVictim?.screenName ??
            (heist['victimName'] as String?) ??
            'Player';
        final victimAvatarUrl =
            latestVictim?.avatarUrl ?? (heist['victimAvatarUrl'] as String?);

        final accum = periodRivalries.putIfAbsent(pairId, () {
          final map = <String, dynamic>{
            'id': pairId,
            'periodId': periodId,
            'actorUid': actorUid,
            'actorName': actorName,
            'actorAvatarUrl': actorAvatarUrl,
            'victimUid': victimUid,
            'victimName': victimName,
            'victimAvatarUrl': victimAvatarUrl,
          };
          for (final field in _rivalryCounterFields) {
            map[field] = 0;
          }
          return map;
        });

        accum['actorName'] = actorName;
        if (actorAvatarUrl != null) {
          accum['actorAvatarUrl'] = actorAvatarUrl;
        }
        accum['victimName'] = victimName;
        if (victimAvatarUrl != null) {
          accum['victimAvatarUrl'] = victimAvatarUrl;
        }

        for (final field in _rivalryCounterFields) {
          final delta = (heist[field] as num?)?.toInt() ?? 0;
          accum[field] = (accum[field] as int) + delta;
        }
      }
    }
  }

  return AggregatedLeaderboardData(
    playersByPeriod: playersByPeriod,
    rivalriesByPeriod: rivalriesByPeriod,
    reconciledGameIds: reconciledGameIds,
    totalRoundsProcessed: totalRoundsProcessed,
  );
}

/// Scans all persisted `games/{gameId}/rounds/*` documents across Firestore
/// (ignoring legacy games missing the `rounds` subcollection), wipes existing
/// `leaderboards/*` rollups, and deterministically rebuilds all `all_time` and
/// `weekly_*` player and rivalry rollups.
Future<LeaderboardRebuildSummary> rebuildAllLeaderboards(
  Firestore firestore, {
  bool isDryRun = false,
  void Function(String message)? onLog,
}) async {
  void log(String msg) {
    if (onLog != null) onLog(msg);
  }

  // 1. Load user profiles so rebuilt leaderboard entries have latest names/avatars
  final usersSnap = await firestore.collection('users').get();
  final latestProfiles = <String, PlayerProfileInfo>{};
  for (final doc in usersSnap.docs) {
    final data = doc.data();
    latestProfiles[doc.id] = PlayerProfileInfo(
      uid: doc.id,
      screenName:
          (data['screenName'] ?? data['displayName'] ?? 'Player') as String,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }
  log('Loaded ${latestProfiles.length} user profile(s).');

  // 2. Load existing games to identify active/finished games vs legacy games missing rounds
  final gamesSnap = await firestore.collection('games').get();
  final existingGameIds = gamesSnap.docs.map((d) => d.id).toSet();

  // 3. Query all archived rounds across all games
  final roundsSnap = await firestore.collectionGroup('rounds').get();
  final validRoundDocs = <Map<String, dynamic>>[];

  for (final doc in roundsSnap.docs) {
    final data = doc.data();
    final gameId = data['gameId'] as String?;
    // Ignore orphaned round docs if their parent game was deleted
    if (existingGameIds.isNotEmpty &&
        gameId != null &&
        !existingGameIds.contains(gameId)) {
      continue;
    }
    validRoundDocs.add(data);
  }

  final aggregated = aggregateArchivedRounds(
    validRoundDocs,
    latestProfiles: latestProfiles,
  );

  final gamesWithRoundsCount = aggregated.reconciledGameIds.length;
  final legacyGamesIgnored = existingGameIds
      .where((id) => !aggregated.reconciledGameIds.contains(id))
      .length;

  final allPeriods = <String>{
    ...aggregated.playersByPeriod.keys,
    ...aggregated.rivalriesByPeriod.keys,
  }.toList()..sort();

  int playerRollupsCount = 0;
  for (final p in aggregated.playersByPeriod.values) {
    playerRollupsCount += p.length;
  }

  int rivalryRollupsCount = 0;
  for (final r in aggregated.rivalriesByPeriod.values) {
    rivalryRollupsCount += r.length;
  }

  log(
    'Scanned ${aggregated.totalRoundsProcessed} round(s) across $gamesWithRoundsCount game(s) '
    '(ignored $legacyGamesIgnored legacy game(s) without persisted rounds).',
  );

  if (isDryRun) {
    for (final periodId in allPeriods) {
      final pCount = aggregated.playersByPeriod[periodId]?.length ?? 0;
      final rCount = aggregated.rivalriesByPeriod[periodId]?.length ?? 0;
      log(
        '[DRY-RUN] Period "$periodId": would write $pCount player rollup(s) and $rCount rivalry rollup(s).',
      );
    }
    return LeaderboardRebuildSummary(
      isDryRun: true,
      gamesWithRoundsReconciled: gamesWithRoundsCount,
      legacyGamesIgnored: legacyGamesIgnored,
      totalRoundsScanned: aggregated.totalRoundsProcessed,
      periodsRebuilt: allPeriods,
      playerRollupsWritten: playerRollupsCount,
      rivalryRollupsWritten: rivalryRollupsCount,
    );
  }

  // 4. Wipe existing documents under leaderboards/*
  final existingPeriodRefs =
      await firestore.collection('leaderboards').listDocuments();
  final periodIdsToWipe = <String>{
    ...existingPeriodRefs.map((ref) => ref.id),
    ...allPeriods,
  };

  final refsToDelete = <DocumentReference<DocumentData>>[];
  for (final periodId in periodIdsToWipe) {
    final periodRef = firestore.collection('leaderboards').doc(periodId);
    final oldPlayers = await periodRef.collection('players').get();
    for (final doc in oldPlayers.docs) {
      refsToDelete.add(doc.ref);
    }
    final oldRivalries = await periodRef.collection('rivalries').get();
    for (final doc in oldRivalries.docs) {
      refsToDelete.add(doc.ref);
    }
    refsToDelete.add(periodRef);
  }

  const maxBatchSize = 400;
  for (int i = 0; i < refsToDelete.length; i += maxBatchSize) {
    final chunk = refsToDelete.sublist(
      i,
      i + maxBatchSize > refsToDelete.length
          ? refsToDelete.length
          : i + maxBatchSize,
    );
    final batch = firestore.batch();
    for (final ref in chunk) {
      batch.delete(ref);
    }
    await batch.commit();
  }
  log('Cleared ${refsToDelete.length} existing leaderboard document(s).');

  // 5. Write freshly aggregated rollups in batches
  final pendingWrites =
      <({DocumentReference<DocumentData> ref, Map<String, Object?> data})>[];

  for (final periodId in allPeriods) {
    final periodRef = firestore.collection('leaderboards').doc(periodId);
    pendingWrites.add((
      ref: periodRef,
      data: <String, Object?>{
        'periodId': periodId,
        'updatedAt': FieldValue.serverTimestamp,
      },
    ));

    final periodPlayers = aggregated.playersByPeriod[periodId] ?? const {};
    for (final entry in periodPlayers.entries) {
      final playerRef = periodRef.collection('players').doc(entry.key);
      pendingWrites.add((
        ref: playerRef,
        data: <String, Object?>{
          ...entry.value,
          'updatedAt': FieldValue.serverTimestamp,
        },
      ));
    }

    final periodRivalries = aggregated.rivalriesByPeriod[periodId] ?? const {};
    for (final entry in periodRivalries.entries) {
      final rivalryRef = periodRef.collection('rivalries').doc(entry.key);
      pendingWrites.add((
        ref: rivalryRef,
        data: <String, Object?>{
          ...entry.value,
          'updatedAt': FieldValue.serverTimestamp,
        },
      ));
    }
  }

  for (int i = 0; i < pendingWrites.length; i += maxBatchSize) {
    final chunk = pendingWrites.sublist(
      i,
      i + maxBatchSize > pendingWrites.length
          ? pendingWrites.length
          : i + maxBatchSize,
    );
    final batch = firestore.batch();
    for (final item in chunk) {
      batch.set(item.ref, item.data);
    }
    await batch.commit();
  }
  log(
    'Wrote $playerRollupsCount player rollup(s) and $rivalryRollupsCount rivalry rollup(s) across ${allPeriods.length} period(s).',
  );

  return LeaderboardRebuildSummary(
    isDryRun: false,
    gamesWithRoundsReconciled: gamesWithRoundsCount,
    legacyGamesIgnored: legacyGamesIgnored,
    totalRoundsScanned: aggregated.totalRoundsProcessed,
    periodsRebuilt: allPeriods,
    playerRollupsWritten: playerRollupsCount,
    rivalryRollupsWritten: rivalryRollupsCount,
  );
}
