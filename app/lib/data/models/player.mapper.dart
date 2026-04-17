// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'player.dart';

class PlayerMapper extends ClassMapperBase<Player> {
  PlayerMapper._();

  static PlayerMapper? _instance;
  static PlayerMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayerMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Player';

  static String _$id(Player v) => v.id;
  static const Field<Player, String> _f$id = Field('id', _$id);
  static String _$displayName(Player v) => v.displayName;
  static const Field<Player, String> _f$displayName =
      Field('displayName', _$displayName);
  static String? _$avatarUrl(Player v) => v.avatarUrl;
  static const Field<Player, String> _f$avatarUrl =
      Field('avatarUrl', _$avatarUrl, opt: true);

  @override
  final MappableFields<Player> fields = const {
    #id: _f$id,
    #displayName: _f$displayName,
    #avatarUrl: _f$avatarUrl,
  };

  static Player _instantiate(DecodingData data) {
    return Player(
        id: data.dec(_f$id),
        displayName: data.dec(_f$displayName),
        avatarUrl: data.dec(_f$avatarUrl));
  }

  @override
  final Function instantiate = _instantiate;

  static Player fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Player>(map);
  }

  static Player fromJson(String json) {
    return ensureInitialized().decodeJson<Player>(json);
  }
}

mixin PlayerMappable {
  String toJson() {
    return PlayerMapper.ensureInitialized().encodeJson<Player>(this as Player);
  }

  Map<String, dynamic> toMap() {
    return PlayerMapper.ensureInitialized().encodeMap<Player>(this as Player);
  }

  PlayerCopyWith<Player, Player, Player> get copyWith =>
      _PlayerCopyWithImpl(this as Player, $identity, $identity);
  @override
  String toString() {
    return PlayerMapper.ensureInitialized().stringifyValue(this as Player);
  }

  @override
  bool operator ==(Object other) {
    return PlayerMapper.ensureInitialized().equalsValue(this as Player, other);
  }

  @override
  int get hashCode {
    return PlayerMapper.ensureInitialized().hashValue(this as Player);
  }
}

extension PlayerValueCopy<$R, $Out> on ObjectCopyWith<$R, Player, $Out> {
  PlayerCopyWith<$R, Player, $Out> get $asPlayer =>
      $base.as((v, t, t2) => _PlayerCopyWithImpl(v, t, t2));
}

abstract class PlayerCopyWith<$R, $In extends Player, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? displayName, String? avatarUrl});
  PlayerCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlayerCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Player, $Out>
    implements PlayerCopyWith<$R, Player, $Out> {
  _PlayerCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Player> $mapper = PlayerMapper.ensureInitialized();
  @override
  $R call({String? id, String? displayName, Object? avatarUrl = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (displayName != null) #displayName: displayName,
        if (avatarUrl != $none) #avatarUrl: avatarUrl
      }));
  @override
  Player $make(CopyWithData data) => Player(
      id: data.get(#id, or: $value.id),
      displayName: data.get(#displayName, or: $value.displayName),
      avatarUrl: data.get(#avatarUrl, or: $value.avatarUrl));

  @override
  PlayerCopyWith<$R2, Player, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PlayerCopyWithImpl($value, $cast, t);
}
