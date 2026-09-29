// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'game_reaction.dart';

class GameReactionMapper extends ClassMapperBase<GameReaction> {
  GameReactionMapper._();

  static GameReactionMapper? _instance;
  static GameReactionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GameReactionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'GameReaction';

  static String _$id(GameReaction v) => v.id;
  static const Field<GameReaction, String> _f$id = Field('id', _$id);
  static String _$senderId(GameReaction v) => v.senderId;
  static const Field<GameReaction, String> _f$senderId = Field(
    'senderId',
    _$senderId,
  );
  static String _$senderName(GameReaction v) => v.senderName;
  static const Field<GameReaction, String> _f$senderName = Field(
    'senderName',
    _$senderName,
  );
  static String _$emoji(GameReaction v) => v.emoji;
  static const Field<GameReaction, String> _f$emoji = Field('emoji', _$emoji);
  static DateTime _$timestamp(GameReaction v) => v.timestamp;
  static const Field<GameReaction, DateTime> _f$timestamp = Field(
    'timestamp',
    _$timestamp,
  );

  @override
  final MappableFields<GameReaction> fields = const {
    #id: _f$id,
    #senderId: _f$senderId,
    #senderName: _f$senderName,
    #emoji: _f$emoji,
    #timestamp: _f$timestamp,
  };

  static GameReaction _instantiate(DecodingData data) {
    return GameReaction(
      id: data.dec(_f$id),
      senderId: data.dec(_f$senderId),
      senderName: data.dec(_f$senderName),
      emoji: data.dec(_f$emoji),
      timestamp: data.dec(_f$timestamp),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GameReaction fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GameReaction>(map);
  }

  static GameReaction fromJson(String json) {
    return ensureInitialized().decodeJson<GameReaction>(json);
  }
}

mixin GameReactionMappable {
  String toJson() {
    return GameReactionMapper.ensureInitialized().encodeJson<GameReaction>(
      this as GameReaction,
    );
  }

  Map<String, dynamic> toMap() {
    return GameReactionMapper.ensureInitialized().encodeMap<GameReaction>(
      this as GameReaction,
    );
  }

  GameReactionCopyWith<GameReaction, GameReaction, GameReaction> get copyWith =>
      _GameReactionCopyWithImpl<GameReaction, GameReaction>(
        this as GameReaction,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GameReactionMapper.ensureInitialized().stringifyValue(
      this as GameReaction,
    );
  }

  @override
  bool operator ==(Object other) {
    return GameReactionMapper.ensureInitialized().equalsValue(
      this as GameReaction,
      other,
    );
  }

  @override
  int get hashCode {
    return GameReactionMapper.ensureInitialized().hashValue(
      this as GameReaction,
    );
  }
}

extension GameReactionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GameReaction, $Out> {
  GameReactionCopyWith<$R, GameReaction, $Out> get $asGameReaction =>
      $base.as((v, t, t2) => _GameReactionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GameReactionCopyWith<$R, $In extends GameReaction, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? senderId,
    String? senderName,
    String? emoji,
    DateTime? timestamp,
  });
  GameReactionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _GameReactionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GameReaction, $Out>
    implements GameReactionCopyWith<$R, GameReaction, $Out> {
  _GameReactionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GameReaction> $mapper =
      GameReactionMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? senderId,
    String? senderName,
    String? emoji,
    DateTime? timestamp,
  }) =>
      $apply(
        FieldCopyWithData({
          if (id != null) #id: id,
          if (senderId != null) #senderId: senderId,
          if (senderName != null) #senderName: senderName,
          if (emoji != null) #emoji: emoji,
          if (timestamp != null) #timestamp: timestamp,
        }),
      );
  @override
  GameReaction $make(CopyWithData data) => GameReaction(
        id: data.get(#id, or: $value.id),
        senderId: data.get(#senderId, or: $value.senderId),
        senderName: data.get(#senderName, or: $value.senderName),
        emoji: data.get(#emoji, or: $value.emoji),
        timestamp: data.get(#timestamp, or: $value.timestamp),
      );

  @override
  GameReactionCopyWith<$R2, GameReaction, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _GameReactionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
