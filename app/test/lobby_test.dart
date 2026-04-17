import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/game_room.dart';

void main() {
  group('GameRoom Model Serialization', () {
    test('Should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final room = GameRoom(
        id: 'game123',
        hostId: 'user456',
        name: 'sneeky_five',
        playerIds: ['user456'],
        status: GameStatus.waiting,
        createdAt: now,
      );
      
      final map = room.toMap();
      expect(map['id'], 'game123');
      expect(map['hostId'], 'user456');
      expect(map['name'], 'sneeky_five');
      expect(map['playerIds'], ['user456']);
      expect(map['status'], 'waiting');
      
      final deserializedRoom = GameRoom.fromMap(map);
      expect(deserializedRoom.id, room.id);
      expect(deserializedRoom.hostId, room.hostId);
      expect(deserializedRoom.name, room.name);
      expect(deserializedRoom.playerIds, room.playerIds);
      expect(deserializedRoom.status, room.status);
      expect(deserializedRoom.createdAt.millisecondsSinceEpoch, room.createdAt.millisecondsSinceEpoch);
    });
  });
}
