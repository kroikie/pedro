import 'package:dart_mappable/dart_mappable.dart';

part 'game_reaction.mapper.dart';

@MappableClass()
class GameReaction with GameReactionMappable {
  final String id;
  final String senderId;
  final String senderName;
  final String emoji;
  final DateTime timestamp;

  const GameReaction({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.emoji,
    required this.timestamp,
  });

  static const fromMap = GameReactionMapper.fromMap;
}
