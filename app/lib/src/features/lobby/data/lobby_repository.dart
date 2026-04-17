import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/game_room.dart';

class LobbyRepository {
  LobbyRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<GameRoom>> watchGames() {
    return _firestore
        .collection('games')
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        return GameRoom.fromMap({
          'id': doc.id,
          ...data,
          'createdAt': createdAt?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
        });
      }).toList();
    });
  }

  Stream<GameRoom?> watchGame(String gameId) {
    return _firestore.collection('games').doc(gameId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      final createdAt = data['createdAt'] as Timestamp?;
      return GameRoom.fromMap({
        'id': doc.id,
        ...data,
        'createdAt': createdAt?.toDate().toIso8601String() ??
            DateTime.now().toIso8601String(),
      });
    });
  }

  Future<String> createGame(String roomName) async {
    final result = await _functions.httpsCallable('createGame').call({
      'roomName': roomName,
    });
    return result.data['gameId'];
  }

  Future<void> joinGame(String gameId) async {
    await _functions.httpsCallable('joinGame').call({
      'gameId': gameId,
    });
  }
}
