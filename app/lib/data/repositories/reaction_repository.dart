import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_reaction.dart';

class ReactionRepository {
  ReactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<GameReaction>> watchRecentReactions(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('reactions')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        return GameReaction.fromMap({
          'id': doc.id,
          ...data,
          'timestamp': timestamp?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
        });
      }).toList();
    });
  }

  Future<void> sendReaction({
    required String gameId,
    required String senderId,
    required String senderName,
    required String emoji,
  }) async {
    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('reactions')
        .add({
      'senderId': senderId,
      'senderName': senderName,
      'emoji': emoji,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
