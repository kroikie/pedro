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
  final int targetScore;
  final List<String> playerIds;
  final List<String> invitedPlayerIds;
  final List<String> viewerIds;
  final Map<String, int> viewerHeartbeats;
  final bool isOpen;
  final GameStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GameRoom({
    required this.id,
    required this.hostId,
    required this.name,
    this.targetScore = 35,
    required this.playerIds,
    this.invitedPlayerIds = const [],
    this.viewerIds = const [],
    this.viewerHeartbeats = const {},
    this.isOpen = false,
    this.status = GameStatus.waiting,
    required this.createdAt,
    this.updatedAt,
  });

  DateTime get lastActivityAt => updatedAt ?? createdAt;

  List<String> get activeViewerIds {
    final now = DateTime.now().millisecondsSinceEpoch;
    return viewerIds.where((uid) {
      final hb = viewerHeartbeats[uid];
      if (hb == null) return true;
      return (now - hb) <= 60000;
    }).toList();
  }

  int get viewerCount => activeViewerIds.length;

  static const fromMap = GameRoomMapper.fromMap;
}
