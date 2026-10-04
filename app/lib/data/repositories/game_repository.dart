import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_session.dart';
import '../models/card.dart';
import '../functions_config.dart';

class GameRepository {
  GameRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Stream<GameSession?> watchGameSession(String gameId) {
    return _firestore.collection('games').doc(gameId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      final roundData = Map<String, dynamic>.from(data['currentRound'] as Map);
      if (roundData['lastCalledAt'] != null && roundData['lastCalledAt'] is Timestamp) {
        roundData['lastCalledAt'] = (roundData['lastCalledAt'] as Timestamp).toDate().toIso8601String();
      }
      
      final viewerHeartbeats = data['viewerHeartbeats'] as Map<String, dynamic>?;
      final createdAt = data['createdAt'] as Timestamp?;
      final updatedAt = data['updatedAt'] as Timestamp?;

      return GameSession.fromMap({
        'gameId': doc.id,
        ...data,
        'viewerHeartbeats': viewerHeartbeats?.map(
              (key, value) => MapEntry(key, (value as num).toInt()),
            ) ??
            {},
        'createdAt': createdAt?.toDate().toIso8601String(),
        'updatedAt': updatedAt?.toDate().toIso8601String(),
        'playerStates': roundData['playerStates'],
        'currentRound': roundData,
      });
    });
  }

  Future<void> startGame(String gameId) async {
    await _functions.callable('start-game').call({'gameId': gameId});
  }

  Future<void> submitBid(String gameId, int? bid) async {
    await _functions.callable('submit-bid').call({
      'gameId': gameId,
      'bid': bid,
    });
  }

  Future<void> setTrumpSuit(String gameId, Suit suit) async {
    await _functions.callable('set-trump-suit').call({
      'gameId': gameId,
      'suit': suit.name,
    });
  }

  Future<void> playCard(String gameId, Card card) async {
    await _functions.callable('play-card').call({
      'gameId': gameId,
      'card': card.toMap(),
    });
  }

  Future<void> callPlayer(String gameId) async {
    await _functions.callable('call-player').call({
      'gameId': gameId,
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
