import 'package:dart_mappable/dart_mappable.dart';

part 'player.mapper.dart';

@MappableClass()
class Player with PlayerMappable {
  final String id;
  final String screenName;
  final String? avatarUrl;

  const Player({
    required this.id,
    required this.screenName,
    this.avatarUrl,
  });

  static const fromMap = PlayerMapper.fromMap;
}
