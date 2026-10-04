import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_room.dart';
import '../functions_config.dart';

class LobbyRepository {
  LobbyRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Stream<List<GameRoom>> watchMyGames() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection('games')
        .where('playerIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map(_mapDoc).toList();
          list.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
          return list;
        });
  }

  Stream<List<GameRoom>> watchLiveGames() {
    return _firestore
        .collection('games')
        .where('isOpen', isEqualTo: true)
        .where('status', isEqualTo: 'playing')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map(_mapDoc).toList();
          list.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
          return list;
        });
  }

  Stream<List<GameRoom>> watchInvitations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection('games')
        .where('invitedPlayerIds', arrayContains: uid)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapDoc).toList());
  }

  GameRoom _mapDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] as Timestamp?;
    final updatedAt = data['updatedAt'] as Timestamp?;
    final viewerHeartbeats = data['viewerHeartbeats'] as Map<String, dynamic>?;

    return GameRoom.fromMap({
      'id': doc.id,
      ...data,
      'createdAt': createdAt?.toDate().toIso8601String() ??
          DateTime.now().toIso8601String(),
      'updatedAt': updatedAt?.toDate().toIso8601String(),
      'viewerHeartbeats': viewerHeartbeats?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          {},
    });
  }

  Stream<GameRoom?> watchGame(String gameId) {
    return _firestore.collection('games').doc(gameId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _mapDoc(doc);
    });
  }

  Future<String> createGame(String roomName, {int targetScore = 35}) async {
    final result = await _functions.callable('create-game').call({
      'roomName': roomName,
      'targetScore': targetScore,
    });
    return result.data['gameId'];
  }

  Future<void> joinGame(String gameId) async {
    await _functions.callable('join-game').call({
      'gameId': gameId,
    });
  }

  Future<void> invitePlayer(String gameId, String targetPlayerId) async {
    await _functions.callable('invite-player').call({
      'gameId': gameId,
      'targetPlayerId': targetPlayerId,
    });
  }

  Future<void> uninvitePlayer(String gameId, String targetPlayerId) async {
    await _functions.callable('uninvite-player').call({
      'gameId': gameId,
      'targetPlayerId': targetPlayerId,
    });
  }

  Future<void> deleteGame(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseFunctionsException(
        message: 'User must be authenticated to delete a game.',
        code: 'unauthenticated',
      );
    }
    await user.getIdToken();
    await _functions.callable('delete-game').call({
      'gameId': gameId,
    });
  }

  Future<void> joinGameAsViewer(String gameId) async {
    await _functions.callable('join-game-as-viewer').call({
      'gameId': gameId,
    });
  }

  Future<void> heartbeatViewer(String gameId) async {
    await _functions.callable('heartbeat-viewer').call({
      'gameId': gameId,
    });
  }

  Future<void> leaveGameViewer(String gameId) async {
    await _functions.callable('leave-game-viewer').call({
      'gameId': gameId,
    });
  }
}
