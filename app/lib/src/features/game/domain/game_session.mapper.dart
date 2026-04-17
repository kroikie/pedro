// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'game_session.dart';

class RoundPhaseMapper extends EnumMapper<RoundPhase> {
  RoundPhaseMapper._();

  static RoundPhaseMapper? _instance;
  static RoundPhaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RoundPhaseMapper._());
    }
    return _instance!;
  }

  static RoundPhase fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  RoundPhase decode(dynamic value) {
    switch (value) {
      case 'wadger':
        return RoundPhase.wadger;
      case 'discarding':
        return RoundPhase.discarding;
      case 'playing':
        return RoundPhase.playing;
      case 'finished':
        return RoundPhase.finished;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(RoundPhase self) {
    switch (self) {
      case RoundPhase.wadger:
        return 'wadger';
      case RoundPhase.discarding:
        return 'discarding';
      case RoundPhase.playing:
        return 'playing';
      case RoundPhase.finished:
        return 'finished';
    }
  }
}

extension RoundPhaseMapperExtension on RoundPhase {
  String toValue() {
    RoundPhaseMapper.ensureInitialized();
    return MapperContainer.globals.toValue<RoundPhase>(this) as String;
  }
}

class PlayerGameStateMapper extends ClassMapperBase<PlayerGameState> {
  PlayerGameStateMapper._();

  static PlayerGameStateMapper? _instance;
  static PlayerGameStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayerGameStateMapper._());
      CardMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayerGameState';

  static String _$uid(PlayerGameState v) => v.uid;
  static const Field<PlayerGameState, String> _f$uid = Field('uid', _$uid);
  static List<Card> _$hand(PlayerGameState v) => v.hand;
  static const Field<PlayerGameState, List<Card>> _f$hand =
      Field('hand', _$hand);
  static int _$currentRoundPoints(PlayerGameState v) => v.currentRoundPoints;
  static const Field<PlayerGameState, int> _f$currentRoundPoints =
      Field('currentRoundPoints', _$currentRoundPoints, opt: true, def: 0);
  static int _$totalScore(PlayerGameState v) => v.totalScore;
  static const Field<PlayerGameState, int> _f$totalScore =
      Field('totalScore', _$totalScore, opt: true, def: 0);

  @override
  final MappableFields<PlayerGameState> fields = const {
    #uid: _f$uid,
    #hand: _f$hand,
    #currentRoundPoints: _f$currentRoundPoints,
    #totalScore: _f$totalScore,
  };

  static PlayerGameState _instantiate(DecodingData data) {
    return PlayerGameState(
        uid: data.dec(_f$uid),
        hand: data.dec(_f$hand),
        currentRoundPoints: data.dec(_f$currentRoundPoints),
        totalScore: data.dec(_f$totalScore));
  }

  @override
  final Function instantiate = _instantiate;

  static PlayerGameState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayerGameState>(map);
  }

  static PlayerGameState fromJson(String json) {
    return ensureInitialized().decodeJson<PlayerGameState>(json);
  }
}

mixin PlayerGameStateMappable {
  String toJson() {
    return PlayerGameStateMapper.ensureInitialized()
        .encodeJson<PlayerGameState>(this as PlayerGameState);
  }

  Map<String, dynamic> toMap() {
    return PlayerGameStateMapper.ensureInitialized()
        .encodeMap<PlayerGameState>(this as PlayerGameState);
  }

  PlayerGameStateCopyWith<PlayerGameState, PlayerGameState, PlayerGameState>
      get copyWith => _PlayerGameStateCopyWithImpl(
          this as PlayerGameState, $identity, $identity);
  @override
  String toString() {
    return PlayerGameStateMapper.ensureInitialized()
        .stringifyValue(this as PlayerGameState);
  }

  @override
  bool operator ==(Object other) {
    return PlayerGameStateMapper.ensureInitialized()
        .equalsValue(this as PlayerGameState, other);
  }

  @override
  int get hashCode {
    return PlayerGameStateMapper.ensureInitialized()
        .hashValue(this as PlayerGameState);
  }
}

extension PlayerGameStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayerGameState, $Out> {
  PlayerGameStateCopyWith<$R, PlayerGameState, $Out> get $asPlayerGameState =>
      $base.as((v, t, t2) => _PlayerGameStateCopyWithImpl(v, t, t2));
}

abstract class PlayerGameStateCopyWith<$R, $In extends PlayerGameState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get hand;
  $R call(
      {String? uid,
      List<Card>? hand,
      int? currentRoundPoints,
      int? totalScore});
  PlayerGameStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _PlayerGameStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayerGameState, $Out>
    implements PlayerGameStateCopyWith<$R, PlayerGameState, $Out> {
  _PlayerGameStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayerGameState> $mapper =
      PlayerGameStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get hand => ListCopyWith(
      $value.hand, (v, t) => v.copyWith.$chain(t), (v) => call(hand: v));
  @override
  $R call(
          {String? uid,
          List<Card>? hand,
          int? currentRoundPoints,
          int? totalScore}) =>
      $apply(FieldCopyWithData({
        if (uid != null) #uid: uid,
        if (hand != null) #hand: hand,
        if (currentRoundPoints != null) #currentRoundPoints: currentRoundPoints,
        if (totalScore != null) #totalScore: totalScore
      }));
  @override
  PlayerGameState $make(CopyWithData data) => PlayerGameState(
      uid: data.get(#uid, or: $value.uid),
      hand: data.get(#hand, or: $value.hand),
      currentRoundPoints:
          data.get(#currentRoundPoints, or: $value.currentRoundPoints),
      totalScore: data.get(#totalScore, or: $value.totalScore));

  @override
  PlayerGameStateCopyWith<$R2, PlayerGameState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _PlayerGameStateCopyWithImpl($value, $cast, t);
}

class LiftMapper extends ClassMapperBase<Lift> {
  LiftMapper._();

  static LiftMapper? _instance;
  static LiftMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LiftMapper._());
      CardMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Lift';

  static String _$leadPlayerId(Lift v) => v.leadPlayerId;
  static const Field<Lift, String> _f$leadPlayerId =
      Field('leadPlayerId', _$leadPlayerId);
  static Map<String, Card> _$plays(Lift v) => v.plays;
  static const Field<Lift, Map<String, Card>> _f$plays =
      Field('plays', _$plays);
  static String? _$winnerId(Lift v) => v.winnerId;
  static const Field<Lift, String> _f$winnerId =
      Field('winnerId', _$winnerId, opt: true);

  @override
  final MappableFields<Lift> fields = const {
    #leadPlayerId: _f$leadPlayerId,
    #plays: _f$plays,
    #winnerId: _f$winnerId,
  };

  static Lift _instantiate(DecodingData data) {
    return Lift(
        leadPlayerId: data.dec(_f$leadPlayerId),
        plays: data.dec(_f$plays),
        winnerId: data.dec(_f$winnerId));
  }

  @override
  final Function instantiate = _instantiate;

  static Lift fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Lift>(map);
  }

  static Lift fromJson(String json) {
    return ensureInitialized().decodeJson<Lift>(json);
  }
}

mixin LiftMappable {
  String toJson() {
    return LiftMapper.ensureInitialized().encodeJson<Lift>(this as Lift);
  }

  Map<String, dynamic> toMap() {
    return LiftMapper.ensureInitialized().encodeMap<Lift>(this as Lift);
  }

  LiftCopyWith<Lift, Lift, Lift> get copyWith =>
      _LiftCopyWithImpl(this as Lift, $identity, $identity);
  @override
  String toString() {
    return LiftMapper.ensureInitialized().stringifyValue(this as Lift);
  }

  @override
  bool operator ==(Object other) {
    return LiftMapper.ensureInitialized().equalsValue(this as Lift, other);
  }

  @override
  int get hashCode {
    return LiftMapper.ensureInitialized().hashValue(this as Lift);
  }
}

extension LiftValueCopy<$R, $Out> on ObjectCopyWith<$R, Lift, $Out> {
  LiftCopyWith<$R, Lift, $Out> get $asLift =>
      $base.as((v, t, t2) => _LiftCopyWithImpl(v, t, t2));
}

abstract class LiftCopyWith<$R, $In extends Lift, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, Card, CardCopyWith<$R, Card, Card>> get plays;
  $R call({String? leadPlayerId, Map<String, Card>? plays, String? winnerId});
  LiftCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LiftCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Lift, $Out>
    implements LiftCopyWith<$R, Lift, $Out> {
  _LiftCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Lift> $mapper = LiftMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, Card, CardCopyWith<$R, Card, Card>> get plays =>
      MapCopyWith(
          $value.plays, (v, t) => v.copyWith.$chain(t), (v) => call(plays: v));
  @override
  $R call(
          {String? leadPlayerId,
          Map<String, Card>? plays,
          Object? winnerId = $none}) =>
      $apply(FieldCopyWithData({
        if (leadPlayerId != null) #leadPlayerId: leadPlayerId,
        if (plays != null) #plays: plays,
        if (winnerId != $none) #winnerId: winnerId
      }));
  @override
  Lift $make(CopyWithData data) => Lift(
      leadPlayerId: data.get(#leadPlayerId, or: $value.leadPlayerId),
      plays: data.get(#plays, or: $value.plays),
      winnerId: data.get(#winnerId, or: $value.winnerId));

  @override
  LiftCopyWith<$R2, Lift, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LiftCopyWithImpl($value, $cast, t);
}

class RoundStateMapper extends ClassMapperBase<RoundState> {
  RoundStateMapper._();

  static RoundStateMapper? _instance;
  static RoundStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RoundStateMapper._());
      SuitMapper.ensureInitialized();
      RoundPhaseMapper.ensureInitialized();
      LiftMapper.ensureInitialized();
      CardMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RoundState';

  static String _$dealerId(RoundState v) => v.dealerId;
  static const Field<RoundState, String> _f$dealerId =
      Field('dealerId', _$dealerId);
  static String? _$bidWinnerId(RoundState v) => v.bidWinnerId;
  static const Field<RoundState, String> _f$bidWinnerId =
      Field('bidWinnerId', _$bidWinnerId, opt: true);
  static int _$bidValue(RoundState v) => v.bidValue;
  static const Field<RoundState, int> _f$bidValue =
      Field('bidValue', _$bidValue, opt: true, def: 0);
  static Suit? _$trumpSuit(RoundState v) => v.trumpSuit;
  static const Field<RoundState, Suit> _f$trumpSuit =
      Field('trumpSuit', _$trumpSuit, opt: true);
  static RoundPhase _$phase(RoundState v) => v.phase;
  static const Field<RoundState, RoundPhase> _f$phase =
      Field('phase', _$phase, opt: true, def: RoundPhase.wadger);
  static Lift? _$currentLift(RoundState v) => v.currentLift;
  static const Field<RoundState, Lift> _f$currentLift =
      Field('currentLift', _$currentLift, opt: true);
  static List<Card> _$discardedCards(RoundState v) => v.discardedCards;
  static const Field<RoundState, List<Card>> _f$discardedCards =
      Field('discardedCards', _$discardedCards, opt: true, def: const []);

  @override
  final MappableFields<RoundState> fields = const {
    #dealerId: _f$dealerId,
    #bidWinnerId: _f$bidWinnerId,
    #bidValue: _f$bidValue,
    #trumpSuit: _f$trumpSuit,
    #phase: _f$phase,
    #currentLift: _f$currentLift,
    #discardedCards: _f$discardedCards,
  };

  static RoundState _instantiate(DecodingData data) {
    return RoundState(
        dealerId: data.dec(_f$dealerId),
        bidWinnerId: data.dec(_f$bidWinnerId),
        bidValue: data.dec(_f$bidValue),
        trumpSuit: data.dec(_f$trumpSuit),
        phase: data.dec(_f$phase),
        currentLift: data.dec(_f$currentLift),
        discardedCards: data.dec(_f$discardedCards));
  }

  @override
  final Function instantiate = _instantiate;

  static RoundState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RoundState>(map);
  }

  static RoundState fromJson(String json) {
    return ensureInitialized().decodeJson<RoundState>(json);
  }
}

mixin RoundStateMappable {
  String toJson() {
    return RoundStateMapper.ensureInitialized()
        .encodeJson<RoundState>(this as RoundState);
  }

  Map<String, dynamic> toMap() {
    return RoundStateMapper.ensureInitialized()
        .encodeMap<RoundState>(this as RoundState);
  }

  RoundStateCopyWith<RoundState, RoundState, RoundState> get copyWith =>
      _RoundStateCopyWithImpl(this as RoundState, $identity, $identity);
  @override
  String toString() {
    return RoundStateMapper.ensureInitialized()
        .stringifyValue(this as RoundState);
  }

  @override
  bool operator ==(Object other) {
    return RoundStateMapper.ensureInitialized()
        .equalsValue(this as RoundState, other);
  }

  @override
  int get hashCode {
    return RoundStateMapper.ensureInitialized().hashValue(this as RoundState);
  }
}

extension RoundStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RoundState, $Out> {
  RoundStateCopyWith<$R, RoundState, $Out> get $asRoundState =>
      $base.as((v, t, t2) => _RoundStateCopyWithImpl(v, t, t2));
}

abstract class RoundStateCopyWith<$R, $In extends RoundState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  LiftCopyWith<$R, Lift, Lift>? get currentLift;
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get discardedCards;
  $R call(
      {String? dealerId,
      String? bidWinnerId,
      int? bidValue,
      Suit? trumpSuit,
      RoundPhase? phase,
      Lift? currentLift,
      List<Card>? discardedCards});
  RoundStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _RoundStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RoundState, $Out>
    implements RoundStateCopyWith<$R, RoundState, $Out> {
  _RoundStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RoundState> $mapper =
      RoundStateMapper.ensureInitialized();
  @override
  LiftCopyWith<$R, Lift, Lift>? get currentLift =>
      $value.currentLift?.copyWith.$chain((v) => call(currentLift: v));
  @override
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get discardedCards =>
      ListCopyWith($value.discardedCards, (v, t) => v.copyWith.$chain(t),
          (v) => call(discardedCards: v));
  @override
  $R call(
          {String? dealerId,
          Object? bidWinnerId = $none,
          int? bidValue,
          Object? trumpSuit = $none,
          RoundPhase? phase,
          Object? currentLift = $none,
          List<Card>? discardedCards}) =>
      $apply(FieldCopyWithData({
        if (dealerId != null) #dealerId: dealerId,
        if (bidWinnerId != $none) #bidWinnerId: bidWinnerId,
        if (bidValue != null) #bidValue: bidValue,
        if (trumpSuit != $none) #trumpSuit: trumpSuit,
        if (phase != null) #phase: phase,
        if (currentLift != $none) #currentLift: currentLift,
        if (discardedCards != null) #discardedCards: discardedCards
      }));
  @override
  RoundState $make(CopyWithData data) => RoundState(
      dealerId: data.get(#dealerId, or: $value.dealerId),
      bidWinnerId: data.get(#bidWinnerId, or: $value.bidWinnerId),
      bidValue: data.get(#bidValue, or: $value.bidValue),
      trumpSuit: data.get(#trumpSuit, or: $value.trumpSuit),
      phase: data.get(#phase, or: $value.phase),
      currentLift: data.get(#currentLift, or: $value.currentLift),
      discardedCards: data.get(#discardedCards, or: $value.discardedCards));

  @override
  RoundStateCopyWith<$R2, RoundState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _RoundStateCopyWithImpl($value, $cast, t);
}

class GameSessionMapper extends ClassMapperBase<GameSession> {
  GameSessionMapper._();

  static GameSessionMapper? _instance;
  static GameSessionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GameSessionMapper._());
      PlayerGameStateMapper.ensureInitialized();
      RoundStateMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GameSession';

  static String _$gameId(GameSession v) => v.gameId;
  static const Field<GameSession, String> _f$gameId = Field('gameId', _$gameId);
  static List<PlayerGameState> _$playerStates(GameSession v) => v.playerStates;
  static const Field<GameSession, List<PlayerGameState>> _f$playerStates =
      Field('playerStates', _$playerStates);
  static RoundState _$currentRound(GameSession v) => v.currentRound;
  static const Field<GameSession, RoundState> _f$currentRound =
      Field('currentRound', _$currentRound);

  @override
  final MappableFields<GameSession> fields = const {
    #gameId: _f$gameId,
    #playerStates: _f$playerStates,
    #currentRound: _f$currentRound,
  };

  static GameSession _instantiate(DecodingData data) {
    return GameSession(
        gameId: data.dec(_f$gameId),
        playerStates: data.dec(_f$playerStates),
        currentRound: data.dec(_f$currentRound));
  }

  @override
  final Function instantiate = _instantiate;

  static GameSession fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GameSession>(map);
  }

  static GameSession fromJson(String json) {
    return ensureInitialized().decodeJson<GameSession>(json);
  }
}

mixin GameSessionMappable {
  String toJson() {
    return GameSessionMapper.ensureInitialized()
        .encodeJson<GameSession>(this as GameSession);
  }

  Map<String, dynamic> toMap() {
    return GameSessionMapper.ensureInitialized()
        .encodeMap<GameSession>(this as GameSession);
  }

  GameSessionCopyWith<GameSession, GameSession, GameSession> get copyWith =>
      _GameSessionCopyWithImpl(this as GameSession, $identity, $identity);
  @override
  String toString() {
    return GameSessionMapper.ensureInitialized()
        .stringifyValue(this as GameSession);
  }

  @override
  bool operator ==(Object other) {
    return GameSessionMapper.ensureInitialized()
        .equalsValue(this as GameSession, other);
  }

  @override
  int get hashCode {
    return GameSessionMapper.ensureInitialized().hashValue(this as GameSession);
  }
}

extension GameSessionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GameSession, $Out> {
  GameSessionCopyWith<$R, GameSession, $Out> get $asGameSession =>
      $base.as((v, t, t2) => _GameSessionCopyWithImpl(v, t, t2));
}

abstract class GameSessionCopyWith<$R, $In extends GameSession, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, PlayerGameState,
          PlayerGameStateCopyWith<$R, PlayerGameState, PlayerGameState>>
      get playerStates;
  RoundStateCopyWith<$R, RoundState, RoundState> get currentRound;
  $R call(
      {String? gameId,
      List<PlayerGameState>? playerStates,
      RoundState? currentRound});
  GameSessionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _GameSessionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GameSession, $Out>
    implements GameSessionCopyWith<$R, GameSession, $Out> {
  _GameSessionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GameSession> $mapper =
      GameSessionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, PlayerGameState,
          PlayerGameStateCopyWith<$R, PlayerGameState, PlayerGameState>>
      get playerStates => ListCopyWith($value.playerStates,
          (v, t) => v.copyWith.$chain(t), (v) => call(playerStates: v));
  @override
  RoundStateCopyWith<$R, RoundState, RoundState> get currentRound =>
      $value.currentRound.copyWith.$chain((v) => call(currentRound: v));
  @override
  $R call(
          {String? gameId,
          List<PlayerGameState>? playerStates,
          RoundState? currentRound}) =>
      $apply(FieldCopyWithData({
        if (gameId != null) #gameId: gameId,
        if (playerStates != null) #playerStates: playerStates,
        if (currentRound != null) #currentRound: currentRound
      }));
  @override
  GameSession $make(CopyWithData data) => GameSession(
      gameId: data.get(#gameId, or: $value.gameId),
      playerStates: data.get(#playerStates, or: $value.playerStates),
      currentRound: data.get(#currentRound, or: $value.currentRound));

  @override
  GameSessionCopyWith<$R2, GameSession, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GameSessionCopyWithImpl($value, $cast, t);
}
