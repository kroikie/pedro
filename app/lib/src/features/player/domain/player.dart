import 'package:dart_mappable/dart_mappable.dart';

part 'player.mapper.dart';

@MappableClass()
class Player with PlayerMappable {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const Player({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  static const fromMap = PlayerMapper.fromMap;
}
