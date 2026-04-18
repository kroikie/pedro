import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';

class PlayerRepository {
  PlayerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Player> _playersRef() {
    return _firestore.collection('users').withConverter<Player>(
      fromFirestore: (snapshot, _) {
        final data = snapshot.data()!;
        final map = {
          ...data,
          'id': snapshot.id,
          'screenName': data['screenName'] ?? data['displayName'] ?? 'Anonymous',
        };
        return Player.fromMap(map);
      },
      toFirestore: (player, _) {
        final map = player.toMap();
        map.remove('id');
        return map;
      },
    );
  }

  Future<Player?> getPlayer(String uid) async {
    final doc = await _playersRef().doc(uid).get();
    return doc.data();
  }

  Future<void> updatePlayer(Player player) async {
    await _playersRef().doc(player.id).set(player, SetOptions(merge: true));
  }

  Stream<List<Player>> watchAllPlayers() {
    return _playersRef().snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
