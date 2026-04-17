import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/game_session.dart';
import '../domain/card.dart';

class GameRepository {
  GameRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<GameSession?> watchGameSession(String gameId) {
    return _firestore.collection('games').doc(gameId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      
      // Handle the complex nested structure for GameSession
      // Note: In a real app, we'd ensure the Firestore data structure matches GameSession exactly.
      // For now, we assume currentRound contains the playerStates and other fields.
      
      return GameSession.fromMap({
        'gameId': doc.id,
        ...data,
        'playerStates': data['currentRound']['playerStates'],
        'currentRound': data['currentRound'],
      });
    });
  }

  Future<void> startGame(String gameId) async {
    await _functions.httpsCallable('startGame').call({'gameId': gameId});
  }

  Future<void> submitBid(String gameId, int? bid) async {
    await _functions.httpsCallable('submitBid').call({
      'gameId': gameId,
      'bid': bid,
    });
  }

  Future<void> setTrumpSuit(String gameId, Suit suit) async {
    await _functions.httpsCallable('setTrumpSuit').call({
      'gameId': gameId,
      'suit': suit.name,
    });
  }

  Future<void> playCard(String gameId, Card card) async {
    await _functions.httpsCallable('playCard').call({
      'gameId': gameId,
      'card': card.toMap(),
    });
  }
}
