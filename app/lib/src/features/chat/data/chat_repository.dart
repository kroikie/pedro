import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/chat_message.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ChatMessage>> watchMessages(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        return ChatMessage.fromMap({
          'id': doc.id,
          ...data,
          'timestamp': timestamp?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
        });
      }).toList();
    });
  }

  Future<void> sendMessage({
    required String gameId,
    required String senderId,
    required String senderName,
    required String text,
    bool isAi = false,
  }) async {
    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isAi': isAi,
    });
  }
}
