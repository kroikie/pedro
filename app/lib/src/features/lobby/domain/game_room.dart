import 'package:dart_mappable/dart_mappable.dart';

part 'game_room.mapper.dart';

@MappableEnum()
enum GameStatus {
  waiting,
  starting,
  playing,
  finished
}

@MappableClass()
class GameRoom with GameRoomMappable {
  final String id;
  final String hostId;
  final String name;
  final List<String> playerIds;
  final GameStatus status;
  final DateTime createdAt;

  const GameRoom({
    required this.id,
    required this.hostId,
    required this.name,
    required this.playerIds,
    this.status = GameStatus.waiting,
    required this.createdAt,
  });

  static const fromMap = GameRoomMapper.fromMap;
}
