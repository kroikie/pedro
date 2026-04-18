import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/player.dart';

void main() {
  group('Player Model Serialization', () {
    test('Should serialize and deserialize correctly', () {
      const player = Player(id: '123', screenName: 'Arthur', avatarUrl: 'http://example.com/avatar.jpg');
      
      final map = player.toMap();
      expect(map['id'], '123');
      expect(map['screenName'], 'Arthur');
      expect(map['avatarUrl'], 'http://example.com/avatar.jpg');

      final deserializedPlayer = Player.fromMap(map);
      expect(deserializedPlayer.id, player.id);
      expect(deserializedPlayer.screenName, player.screenName);
      expect(deserializedPlayer.avatarUrl, player.avatarUrl);
      expect(deserializedPlayer, player);
    });
  });
}
