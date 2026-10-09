import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardRepository {
  LeaderboardRepository({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  final FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ?? FirebaseFirestore.instance;

  /// Streams all player Triumph and Hall of Shame rollup entries for [periodId]
  /// (e.g. `'all_time'` or `'weekly_2026-W41'`).
  Stream<List<LeaderboardEntry>> watchPeriodEntries(String periodId) {
    return _firestore
        .collection('leaderboards')
        .doc(periodId)
        .collection('players')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry.fromMap(_normalizePlayerMap(doc.id, periodId, data));
      }).toList();
    });
  }

  /// Streams all directed head-to-head rivalry entries for [periodId]
  /// (e.g. `'all_time'` or `'weekly_2026-W41'`).
  Stream<List<RivalryEntry>> watchPeriodRivalries(String periodId) {
    return _firestore
        .collection('leaderboards')
        .doc(periodId)
        .collection('rivalries')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RivalryEntry.fromMap(_normalizeRivalryMap(doc.id, periodId, data));
      }).toList();
    });
  }

  /// Streams a single player's rollup stats for [periodId] (defaults to `'all_time'`).
  Stream<LeaderboardEntry?> watchPlayerStats(
    String uid, {
    String periodId = 'all_time',
  }) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore
        .collection('leaderboards')
        .doc(periodId)
        .collection('players')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return LeaderboardEntry.fromMap(
        _normalizePlayerMap(doc.id, periodId, doc.data()!),
      );
    });
  }

  Map<String, dynamic> _normalizePlayerMap(
    String docId,
    String periodId,
    Map<String, dynamic> raw,
  ) {
    final updatedAt = raw['updatedAt'];
    String? updatedAtIso;
    if (updatedAt is Timestamp) {
      updatedAtIso = updatedAt.toDate().toIso8601String();
    } else if (updatedAt is String) {
      updatedAtIso = updatedAt;
    }

    int toInt(Object? val) => (val as num?)?.toInt() ?? 0;

    return <String, dynamic>{
      'uid': (raw['uid'] as String?) ?? docId,
      'screenName': (raw['screenName'] as String?) ?? 'Player',
      'avatarUrl': raw['avatarUrl'] as String?,
      'periodId': (raw['periodId'] as String?) ?? periodId,
      'hangJacks': toInt(raw['hangJacks']),
      'jacksSaved': toInt(raw['jacksSaved']),
      'highTrumps': toInt(raw['highTrumps']),
      'lowTrumps': toInt(raw['lowTrumps']),
      'fivesWon': toInt(raw['fivesWon']),
      'ninesWon': toInt(raw['ninesWon']),
      'gamePointsWon': toInt(raw['gamePointsWon']),
      'bidsWon': toInt(raw['bidsWon']),
      'bidsMade': toInt(raw['bidsMade']),
      'gamesWon': toInt(raw['gamesWon']),
      'totalPointsEarned': toInt(raw['totalPointsEarned']),
      'jacksHung': toInt(raw['jacksHung']),
      'ninesLost': toInt(raw['ninesLost']),
      'fivesLost': toInt(raw['fivesLost']),
      'bidsSet': toInt(raw['bidsSet']),
      'roundsPlayed': toInt(raw['roundsPlayed']),
      'gamesPlayed': toInt(raw['gamesPlayed']),
      'updatedAt': updatedAtIso,
    };
  }

  Map<String, dynamic> _normalizeRivalryMap(
    String docId,
    String periodId,
    Map<String, dynamic> raw,
  ) {
    final updatedAt = raw['updatedAt'];
    String? updatedAtIso;
    if (updatedAt is Timestamp) {
      updatedAtIso = updatedAt.toDate().toIso8601String();
    } else if (updatedAt is String) {
      updatedAtIso = updatedAt;
    }

    int toInt(Object? val) => (val as num?)?.toInt() ?? 0;

    return <String, dynamic>{
      'id': (raw['id'] as String?) ?? docId,
      'periodId': (raw['periodId'] as String?) ?? periodId,
      'actorUid': (raw['actorUid'] as String?) ?? '',
      'actorName': (raw['actorName'] as String?) ?? 'Player',
      'actorAvatarUrl': raw['actorAvatarUrl'] as String?,
      'victimUid': (raw['victimUid'] as String?) ?? '',
      'victimName': (raw['victimName'] as String?) ?? 'Player',
      'victimAvatarUrl': raw['victimAvatarUrl'] as String?,
      'jacksHung': toInt(raw['jacksHung']),
      'ninesStolen': toInt(raw['ninesStolen']),
      'fivesStolen': toInt(raw['fivesStolen']),
      'heistCount': toInt(raw['heistCount']),
      'heistPoints': toInt(raw['heistPoints']),
      'matchesWonAgainst': toInt(raw['matchesWonAgainst']),
      'updatedAt': updatedAtIso,
    };
  }
}
