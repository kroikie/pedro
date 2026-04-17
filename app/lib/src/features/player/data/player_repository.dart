import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/player.dart';

class PlayerRepository {
  PlayerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Player> _playersRef() {
    return _firestore.collection('users').withConverter<Player>(
      fromFirestore: (snapshot, _) => Player.fromMap({'id': snapshot.id, ...snapshot.data()!}),
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
}
