import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/game_reaction.dart';

void main() {
  group('GameReaction Model Serialization', () {
    test('Should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final reaction = GameReaction(
        id: 'reaction_123',
        senderId: 'user_456',
        senderName: 'Arthur',
        emoji: '🔥',
        timestamp: now,
      );

      final map = reaction.toMap();
      expect(map['id'], 'reaction_123');
      expect(map['senderId'], 'user_456');
      expect(map['senderName'], 'Arthur');
      expect(map['emoji'], '🔥');

      final deserialized = GameReaction.fromMap(map);
      expect(deserialized.id, reaction.id);
      expect(deserialized.senderId, reaction.senderId);
      expect(deserialized.senderName, reaction.senderName);
      expect(deserialized.emoji, reaction.emoji);
      expect(
        deserialized.timestamp.millisecondsSinceEpoch,
        reaction.timestamp.millisecondsSinceEpoch,
      );
    });
  });
}
