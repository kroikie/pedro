import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_room.dart';

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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapDoc).toList());
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
    return GameRoom.fromMap({
      'id': doc.id,
      ...data,
      'createdAt': createdAt?.toDate().toIso8601String() ??
          DateTime.now().toIso8601String(),
    });
  }

  Stream<GameRoom?> watchGame(String gameId) {
    return _firestore.collection('games').doc(gameId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _mapDoc(doc);
    });
  }

  Future<String> createGame(String roomName, {int targetScore = 35}) async {
    final result = await _functions.httpsCallable('createGame').call({
      'roomName': roomName,
      'targetScore': targetScore,
    });
    return result.data['gameId'];
  }

  Future<void> joinGame(String gameId) async {
    await _functions.httpsCallable('joinGame').call({
      'gameId': gameId,
    });
  }

  Future<void> invitePlayer(String gameId, String targetPlayerId) async {
    await _functions.httpsCallable('invitePlayer').call({
      'gameId': gameId,
      'targetPlayerId': targetPlayerId,
    });
  }

  Future<void> uninvitePlayer(String gameId, String targetPlayerId) async {
    await _functions.httpsCallable('uninvitePlayer').call({
      'gameId': gameId,
      'targetPlayerId': targetPlayerId,
    });
  }
}
