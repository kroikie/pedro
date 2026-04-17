// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'game_room.dart';

class GameStatusMapper extends EnumMapper<GameStatus> {
  GameStatusMapper._();

  static GameStatusMapper? _instance;
  static GameStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GameStatusMapper._());
    }
    return _instance!;
  }

  static GameStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  GameStatus decode(dynamic value) {
    switch (value) {
      case 'waiting':
        return GameStatus.waiting;
      case 'starting':
        return GameStatus.starting;
      case 'playing':
        return GameStatus.playing;
      case 'finished':
        return GameStatus.finished;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(GameStatus self) {
    switch (self) {
      case GameStatus.waiting:
        return 'waiting';
      case GameStatus.starting:
        return 'starting';
      case GameStatus.playing:
        return 'playing';
      case GameStatus.finished:
        return 'finished';
    }
  }
}

extension GameStatusMapperExtension on GameStatus {
  String toValue() {
    GameStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<GameStatus>(this) as String;
  }
}

class GameRoomMapper extends ClassMapperBase<GameRoom> {
  GameRoomMapper._();

  static GameRoomMapper? _instance;
  static GameRoomMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GameRoomMapper._());
      GameStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GameRoom';

  static String _$id(GameRoom v) => v.id;
  static const Field<GameRoom, String> _f$id = Field('id', _$id);
  static String _$hostId(GameRoom v) => v.hostId;
  static const Field<GameRoom, String> _f$hostId = Field('hostId', _$hostId);
  static String _$name(GameRoom v) => v.name;
  static const Field<GameRoom, String> _f$name = Field('name', _$name);
  static List<String> _$playerIds(GameRoom v) => v.playerIds;
  static const Field<GameRoom, List<String>> _f$playerIds =
      Field('playerIds', _$playerIds);
  static GameStatus _$status(GameRoom v) => v.status;
  static const Field<GameRoom, GameStatus> _f$status =
      Field('status', _$status, opt: true, def: GameStatus.waiting);
  static DateTime _$createdAt(GameRoom v) => v.createdAt;
  static const Field<GameRoom, DateTime> _f$createdAt =
      Field('createdAt', _$createdAt);

  @override
  final MappableFields<GameRoom> fields = const {
    #id: _f$id,
    #hostId: _f$hostId,
    #name: _f$name,
    #playerIds: _f$playerIds,
    #status: _f$status,
    #createdAt: _f$createdAt,
  };

  static GameRoom _instantiate(DecodingData data) {
    return GameRoom(
        id: data.dec(_f$id),
        hostId: data.dec(_f$hostId),
        name: data.dec(_f$name),
        playerIds: data.dec(_f$playerIds),
        status: data.dec(_f$status),
        createdAt: data.dec(_f$createdAt));
  }

  @override
  final Function instantiate = _instantiate;

  static GameRoom fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GameRoom>(map);
  }

  static GameRoom fromJson(String json) {
    return ensureInitialized().decodeJson<GameRoom>(json);
  }
}

mixin GameRoomMappable {
  String toJson() {
    return GameRoomMapper.ensureInitialized()
        .encodeJson<GameRoom>(this as GameRoom);
  }

  Map<String, dynamic> toMap() {
    return GameRoomMapper.ensureInitialized()
        .encodeMap<GameRoom>(this as GameRoom);
  }

  GameRoomCopyWith<GameRoom, GameRoom, GameRoom> get copyWith =>
      _GameRoomCopyWithImpl(this as GameRoom, $identity, $identity);
  @override
  String toString() {
    return GameRoomMapper.ensureInitialized().stringifyValue(this as GameRoom);
  }

  @override
  bool operator ==(Object other) {
    return GameRoomMapper.ensureInitialized()
        .equalsValue(this as GameRoom, other);
  }

  @override
  int get hashCode {
    return GameRoomMapper.ensureInitialized().hashValue(this as GameRoom);
  }
}

extension GameRoomValueCopy<$R, $Out> on ObjectCopyWith<$R, GameRoom, $Out> {
  GameRoomCopyWith<$R, GameRoom, $Out> get $asGameRoom =>
      $base.as((v, t, t2) => _GameRoomCopyWithImpl(v, t, t2));
}

abstract class GameRoomCopyWith<$R, $In extends GameRoom, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get playerIds;
  $R call(
      {String? id,
      String? hostId,
      String? name,
      List<String>? playerIds,
      GameStatus? status,
      DateTime? createdAt});
  GameRoomCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _GameRoomCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GameRoom, $Out>
    implements GameRoomCopyWith<$R, GameRoom, $Out> {
  _GameRoomCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GameRoom> $mapper =
      GameRoomMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get playerIds =>
      ListCopyWith($value.playerIds, (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(playerIds: v));
  @override
  $R call(
          {String? id,
          String? hostId,
          String? name,
          List<String>? playerIds,
          GameStatus? status,
          DateTime? createdAt}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (hostId != null) #hostId: hostId,
        if (name != null) #name: name,
        if (playerIds != null) #playerIds: playerIds,
        if (status != null) #status: status,
        if (createdAt != null) #createdAt: createdAt
      }));
  @override
  GameRoom $make(CopyWithData data) => GameRoom(
      id: data.get(#id, or: $value.id),
      hostId: data.get(#hostId, or: $value.hostId),
      name: data.get(#name, or: $value.name),
      playerIds: data.get(#playerIds, or: $value.playerIds),
      status: data.get(#status, or: $value.status),
      createdAt: data.get(#createdAt, or: $value.createdAt));

  @override
  GameRoomCopyWith<$R2, GameRoom, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GameRoomCopyWithImpl($value, $cast, t);
}
