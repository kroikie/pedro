import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/src/features/player/domain/player.dart';

void main() {
  group('Player Model Serialization', () {
    test('Should serialize and deserialize correctly', () {
      const player = Player(id: '123', displayName: 'Arthur', avatarUrl: 'http://example.com/avatar.jpg');
      
      final map = player.toMap();
      expect(map['id'], '123');
      expect(map['displayName'], 'Arthur');
      expect(map['avatarUrl'], 'http://example.com/avatar.jpg');

      final deserializedPlayer = Player.fromMap(map);
      expect(deserializedPlayer.id, player.id);
      expect(deserializedPlayer.displayName, player.displayName);
      expect(deserializedPlayer.avatarUrl, player.avatarUrl);
      expect(deserializedPlayer, player);
    });
  });
}
