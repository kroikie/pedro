// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
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
      case r'wadger':
        return RoundPhase.wadger;
      case r'discarding':
        return RoundPhase.discarding;
      case r'playing':
        return RoundPhase.playing;
      case r'finished':
        return RoundPhase.finished;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(RoundPhase self) {
    switch (self) {
      case RoundPhase.wadger:
        return r'wadger';
      case RoundPhase.discarding:
        return r'discarding';
      case RoundPhase.playing:
        return r'playing';
      case RoundPhase.finished:
        return r'finished';
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
  static const Field<PlayerGameState, List<Card>> _f$hand = Field(
    'hand',
    _$hand,
  );
  static int _$currentRoundPoints(PlayerGameState v) => v.currentRoundPoints;
  static const Field<PlayerGameState, int> _f$currentRoundPoints = Field(
    'currentRoundPoints',
    _$currentRoundPoints,
    opt: true,
    def: 0,
  );
  static int _$totalScore(PlayerGameState v) => v.totalScore;
  static const Field<PlayerGameState, int> _f$totalScore = Field(
    'totalScore',
    _$totalScore,
    opt: true,
    def: 0,
  );
  static List<String> _$earnedPoints(PlayerGameState v) => v.earnedPoints;
  static const Field<PlayerGameState, List<String>> _f$earnedPoints = Field(
    'earnedPoints',
    _$earnedPoints,
    opt: true,
    def: const [],
  );
  static int? _$cardsDiscarded(PlayerGameState v) => v.cardsDiscarded;
  static const Field<PlayerGameState, int> _f$cardsDiscarded = Field(
    'cardsDiscarded',
    _$cardsDiscarded,
    opt: true,
  );
  static int _$gameValue(PlayerGameState v) => v.gameValue;
  static const Field<PlayerGameState, int> _f$gameValue = Field(
    'gameValue',
    _$gameValue,
    opt: true,
    def: 0,
  );
  static List<Card> _$capturedValueCards(PlayerGameState v) =>
      v.capturedValueCards;
  static const Field<PlayerGameState, List<Card>> _f$capturedValueCards = Field(
    'capturedValueCards',
    _$capturedValueCards,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<PlayerGameState> fields = const {
    #uid: _f$uid,
    #hand: _f$hand,
    #currentRoundPoints: _f$currentRoundPoints,
    #totalScore: _f$totalScore,
    #earnedPoints: _f$earnedPoints,
    #cardsDiscarded: _f$cardsDiscarded,
    #gameValue: _f$gameValue,
    #capturedValueCards: _f$capturedValueCards,
  };

  static PlayerGameState _instantiate(DecodingData data) {
    return PlayerGameState(
      uid: data.dec(_f$uid),
      hand: data.dec(_f$hand),
      currentRoundPoints: data.dec(_f$currentRoundPoints),
      totalScore: data.dec(_f$totalScore),
      earnedPoints: data.dec(_f$earnedPoints),
      cardsDiscarded: data.dec(_f$cardsDiscarded),
      gameValue: data.dec(_f$gameValue),
      capturedValueCards: data.dec(_f$capturedValueCards),
    );
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
    return PlayerGameStateMapper.ensureInitialized().encodeMap<PlayerGameState>(
      this as PlayerGameState,
    );
  }

  PlayerGameStateCopyWith<PlayerGameState, PlayerGameState, PlayerGameState>
  get copyWith =>
      _PlayerGameStateCopyWithImpl<PlayerGameState, PlayerGameState>(
        this as PlayerGameState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayerGameStateMapper.ensureInitialized().stringifyValue(
      this as PlayerGameState,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayerGameStateMapper.ensureInitialized().equalsValue(
      this as PlayerGameState,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayerGameStateMapper.ensureInitialized().hashValue(
      this as PlayerGameState,
    );
  }
}

extension PlayerGameStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayerGameState, $Out> {
  PlayerGameStateCopyWith<$R, PlayerGameState, $Out> get $asPlayerGameState =>
      $base.as((v, t, t2) => _PlayerGameStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayerGameStateCopyWith<$R, $In extends PlayerGameState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get hand;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get earnedPoints;
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get capturedValueCards;
  $R call({
    String? uid,
    List<Card>? hand,
    int? currentRoundPoints,
    int? totalScore,
    List<String>? earnedPoints,
    int? cardsDiscarded,
    int? gameValue,
    List<Card>? capturedValueCards,
  });
  PlayerGameStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
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
    $value.hand,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(hand: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get earnedPoints => ListCopyWith(
    $value.earnedPoints,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(earnedPoints: v),
  );
  @override
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get capturedValueCards =>
      ListCopyWith(
        $value.capturedValueCards,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(capturedValueCards: v),
      );
  @override
  $R call({
    String? uid,
    List<Card>? hand,
    int? currentRoundPoints,
    int? totalScore,
    List<String>? earnedPoints,
    Object? cardsDiscarded = $none,
    int? gameValue,
    List<Card>? capturedValueCards,
  }) => $apply(
    FieldCopyWithData({
      if (uid != null) #uid: uid,
      if (hand != null) #hand: hand,
      if (currentRoundPoints != null) #currentRoundPoints: currentRoundPoints,
      if (totalScore != null) #totalScore: totalScore,
      if (earnedPoints != null) #earnedPoints: earnedPoints,
      if (cardsDiscarded != $none) #cardsDiscarded: cardsDiscarded,
      if (gameValue != null) #gameValue: gameValue,
      if (capturedValueCards != null) #capturedValueCards: capturedValueCards,
    }),
  );
  @override
  PlayerGameState $make(CopyWithData data) => PlayerGameState(
    uid: data.get(#uid, or: $value.uid),
    hand: data.get(#hand, or: $value.hand),
    currentRoundPoints: data.get(
      #currentRoundPoints,
      or: $value.currentRoundPoints,
    ),
    totalScore: data.get(#totalScore, or: $value.totalScore),
    earnedPoints: data.get(#earnedPoints, or: $value.earnedPoints),
    cardsDiscarded: data.get(#cardsDiscarded, or: $value.cardsDiscarded),
    gameValue: data.get(#gameValue, or: $value.gameValue),
    capturedValueCards: data.get(
      #capturedValueCards,
      or: $value.capturedValueCards,
    ),
  );

  @override
  PlayerGameStateCopyWith<$R2, PlayerGameState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayerGameStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
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
  static const Field<Lift, String> _f$leadPlayerId = Field(
    'leadPlayerId',
    _$leadPlayerId,
  );
  static Map<String, Card> _$plays(Lift v) => v.plays;
  static const Field<Lift, Map<String, Card>> _f$plays = Field(
    'plays',
    _$plays,
    opt: true,
    def: const {},
  );
  static String? _$winnerId(Lift v) => v.winnerId;
  static const Field<Lift, String> _f$winnerId = Field(
    'winnerId',
    _$winnerId,
    opt: true,
  );

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
      winnerId: data.dec(_f$winnerId),
    );
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
      _LiftCopyWithImpl<Lift, Lift>(this as Lift, $identity, $identity);
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
      $base.as((v, t, t2) => _LiftCopyWithImpl<$R, $Out>(v, t, t2));
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
        $value.plays,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(plays: v),
      );
  @override
  $R call({
    String? leadPlayerId,
    Map<String, Card>? plays,
    Object? winnerId = $none,
  }) => $apply(
    FieldCopyWithData({
      if (leadPlayerId != null) #leadPlayerId: leadPlayerId,
      if (plays != null) #plays: plays,
      if (winnerId != $none) #winnerId: winnerId,
    }),
  );
  @override
  Lift $make(CopyWithData data) => Lift(
    leadPlayerId: data.get(#leadPlayerId, or: $value.leadPlayerId),
    plays: data.get(#plays, or: $value.plays),
    winnerId: data.get(#winnerId, or: $value.winnerId),
  );

  @override
  LiftCopyWith<$R2, Lift, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LiftCopyWithImpl<$R2, $Out2>($value, $cast, t);
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
  static const Field<RoundState, String> _f$dealerId = Field(
    'dealerId',
    _$dealerId,
  );
  static String? _$bidWinnerId(RoundState v) => v.bidWinnerId;
  static const Field<RoundState, String> _f$bidWinnerId = Field(
    'bidWinnerId',
    _$bidWinnerId,
    opt: true,
  );
  static int _$bidValue(RoundState v) => v.bidValue;
  static const Field<RoundState, int> _f$bidValue = Field(
    'bidValue',
    _$bidValue,
    opt: true,
    def: 0,
  );
  static Suit? _$trumpSuit(RoundState v) => v.trumpSuit;
  static const Field<RoundState, Suit> _f$trumpSuit = Field(
    'trumpSuit',
    _$trumpSuit,
    opt: true,
  );
  static RoundPhase _$phase(RoundState v) => v.phase;
  static const Field<RoundState, RoundPhase> _f$phase = Field(
    'phase',
    _$phase,
    opt: true,
    def: RoundPhase.wadger,
  );
  static Lift? _$currentLift(RoundState v) => v.currentLift;
  static const Field<RoundState, Lift> _f$currentLift = Field(
    'currentLift',
    _$currentLift,
    opt: true,
  );
  static Lift? _$lastLift(RoundState v) => v.lastLift;
  static const Field<RoundState, Lift> _f$lastLift = Field(
    'lastLift',
    _$lastLift,
    opt: true,
  );
  static List<Lift> _$completedLifts(RoundState v) => v.completedLifts;
  static const Field<RoundState, List<Lift>> _f$completedLifts = Field(
    'completedLifts',
    _$completedLifts,
    opt: true,
    def: const [],
  );
  static List<Card> _$discardedCards(RoundState v) => v.discardedCards;
  static const Field<RoundState, List<Card>> _f$discardedCards = Field(
    'discardedCards',
    _$discardedCards,
    opt: true,
    def: const [],
  );
  static List<Card> _$playedCards(RoundState v) => v.playedCards;
  static const Field<RoundState, List<Card>> _f$playedCards = Field(
    'playedCards',
    _$playedCards,
    opt: true,
    def: const [],
  );
  static List<String> _$passedPlayerIds(RoundState v) => v.passedPlayerIds;
  static const Field<RoundState, List<String>> _f$passedPlayerIds = Field(
    'passedPlayerIds',
    _$passedPlayerIds,
    opt: true,
    def: const [],
  );
  static int _$turnIndex(RoundState v) => v.turnIndex;
  static const Field<RoundState, int> _f$turnIndex = Field(
    'turnIndex',
    _$turnIndex,
    opt: true,
    def: 0,
  );
  static DateTime? _$lastCalledAt(RoundState v) => v.lastCalledAt;
  static const Field<RoundState, DateTime> _f$lastCalledAt = Field(
    'lastCalledAt',
    _$lastCalledAt,
    opt: true,
  );
  static String? _$gamePointLeaderId(RoundState v) => v.gamePointLeaderId;
  static const Field<RoundState, String> _f$gamePointLeaderId = Field(
    'gamePointLeaderId',
    _$gamePointLeaderId,
    opt: true,
  );
  static int _$gamePointLeaderValue(RoundState v) => v.gamePointLeaderValue;
  static const Field<RoundState, int> _f$gamePointLeaderValue = Field(
    'gamePointLeaderValue',
    _$gamePointLeaderValue,
    opt: true,
    def: 0,
  );
  static String? _$highTrumpPlayerId(RoundState v) => v.highTrumpPlayerId;
  static const Field<RoundState, String> _f$highTrumpPlayerId = Field(
    'highTrumpPlayerId',
    _$highTrumpPlayerId,
    opt: true,
  );
  static Card? _$highTrumpPlayedCard(RoundState v) => v.highTrumpPlayedCard;
  static const Field<RoundState, Card> _f$highTrumpPlayedCard = Field(
    'highTrumpPlayedCard',
    _$highTrumpPlayedCard,
    opt: true,
  );
  static String? _$lowTrumpPlayerId(RoundState v) => v.lowTrumpPlayerId;
  static const Field<RoundState, String> _f$lowTrumpPlayerId = Field(
    'lowTrumpPlayerId',
    _$lowTrumpPlayerId,
    opt: true,
  );
  static Card? _$lowTrumpPlayedCard(RoundState v) => v.lowTrumpPlayedCard;
  static const Field<RoundState, Card> _f$lowTrumpPlayedCard = Field(
    'lowTrumpPlayedCard',
    _$lowTrumpPlayedCard,
    opt: true,
  );

  @override
  final MappableFields<RoundState> fields = const {
    #dealerId: _f$dealerId,
    #bidWinnerId: _f$bidWinnerId,
    #bidValue: _f$bidValue,
    #trumpSuit: _f$trumpSuit,
    #phase: _f$phase,
    #currentLift: _f$currentLift,
    #lastLift: _f$lastLift,
    #completedLifts: _f$completedLifts,
    #discardedCards: _f$discardedCards,
    #playedCards: _f$playedCards,
    #passedPlayerIds: _f$passedPlayerIds,
    #turnIndex: _f$turnIndex,
    #lastCalledAt: _f$lastCalledAt,
    #gamePointLeaderId: _f$gamePointLeaderId,
    #gamePointLeaderValue: _f$gamePointLeaderValue,
    #highTrumpPlayerId: _f$highTrumpPlayerId,
    #highTrumpPlayedCard: _f$highTrumpPlayedCard,
    #lowTrumpPlayerId: _f$lowTrumpPlayerId,
    #lowTrumpPlayedCard: _f$lowTrumpPlayedCard,
  };

  static RoundState _instantiate(DecodingData data) {
    return RoundState(
      dealerId: data.dec(_f$dealerId),
      bidWinnerId: data.dec(_f$bidWinnerId),
      bidValue: data.dec(_f$bidValue),
      trumpSuit: data.dec(_f$trumpSuit),
      phase: data.dec(_f$phase),
      currentLift: data.dec(_f$currentLift),
      lastLift: data.dec(_f$lastLift),
      completedLifts: data.dec(_f$completedLifts),
      discardedCards: data.dec(_f$discardedCards),
      playedCards: data.dec(_f$playedCards),
      passedPlayerIds: data.dec(_f$passedPlayerIds),
      turnIndex: data.dec(_f$turnIndex),
      lastCalledAt: data.dec(_f$lastCalledAt),
      gamePointLeaderId: data.dec(_f$gamePointLeaderId),
      gamePointLeaderValue: data.dec(_f$gamePointLeaderValue),
      highTrumpPlayerId: data.dec(_f$highTrumpPlayerId),
      highTrumpPlayedCard: data.dec(_f$highTrumpPlayedCard),
      lowTrumpPlayerId: data.dec(_f$lowTrumpPlayerId),
      lowTrumpPlayedCard: data.dec(_f$lowTrumpPlayedCard),
    );
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
    return RoundStateMapper.ensureInitialized().encodeJson<RoundState>(
      this as RoundState,
    );
  }

  Map<String, dynamic> toMap() {
    return RoundStateMapper.ensureInitialized().encodeMap<RoundState>(
      this as RoundState,
    );
  }

  RoundStateCopyWith<RoundState, RoundState, RoundState> get copyWith =>
      _RoundStateCopyWithImpl<RoundState, RoundState>(
        this as RoundState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RoundStateMapper.ensureInitialized().stringifyValue(
      this as RoundState,
    );
  }

  @override
  bool operator ==(Object other) {
    return RoundStateMapper.ensureInitialized().equalsValue(
      this as RoundState,
      other,
    );
  }

  @override
  int get hashCode {
    return RoundStateMapper.ensureInitialized().hashValue(this as RoundState);
  }
}

extension RoundStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RoundState, $Out> {
  RoundStateCopyWith<$R, RoundState, $Out> get $asRoundState =>
      $base.as((v, t, t2) => _RoundStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RoundStateCopyWith<$R, $In extends RoundState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  LiftCopyWith<$R, Lift, Lift>? get currentLift;
  LiftCopyWith<$R, Lift, Lift>? get lastLift;
  ListCopyWith<$R, Lift, LiftCopyWith<$R, Lift, Lift>> get completedLifts;
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get discardedCards;
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get playedCards;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get passedPlayerIds;
  CardCopyWith<$R, Card, Card>? get highTrumpPlayedCard;
  CardCopyWith<$R, Card, Card>? get lowTrumpPlayedCard;
  $R call({
    String? dealerId,
    String? bidWinnerId,
    int? bidValue,
    Suit? trumpSuit,
    RoundPhase? phase,
    Lift? currentLift,
    Lift? lastLift,
    List<Lift>? completedLifts,
    List<Card>? discardedCards,
    List<Card>? playedCards,
    List<String>? passedPlayerIds,
    int? turnIndex,
    DateTime? lastCalledAt,
    String? gamePointLeaderId,
    int? gamePointLeaderValue,
    String? highTrumpPlayerId,
    Card? highTrumpPlayedCard,
    String? lowTrumpPlayerId,
    Card? lowTrumpPlayedCard,
  });
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
  LiftCopyWith<$R, Lift, Lift>? get lastLift =>
      $value.lastLift?.copyWith.$chain((v) => call(lastLift: v));
  @override
  ListCopyWith<$R, Lift, LiftCopyWith<$R, Lift, Lift>> get completedLifts =>
      ListCopyWith(
        $value.completedLifts,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(completedLifts: v),
      );
  @override
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get discardedCards =>
      ListCopyWith(
        $value.discardedCards,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(discardedCards: v),
      );
  @override
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get playedCards =>
      ListCopyWith(
        $value.playedCards,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(playedCards: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get passedPlayerIds => ListCopyWith(
    $value.passedPlayerIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(passedPlayerIds: v),
  );
  @override
  CardCopyWith<$R, Card, Card>? get highTrumpPlayedCard => $value
      .highTrumpPlayedCard
      ?.copyWith
      .$chain((v) => call(highTrumpPlayedCard: v));
  @override
  CardCopyWith<$R, Card, Card>? get lowTrumpPlayedCard => $value
      .lowTrumpPlayedCard
      ?.copyWith
      .$chain((v) => call(lowTrumpPlayedCard: v));
  @override
  $R call({
    String? dealerId,
    Object? bidWinnerId = $none,
    int? bidValue,
    Object? trumpSuit = $none,
    RoundPhase? phase,
    Object? currentLift = $none,
    Object? lastLift = $none,
    List<Lift>? completedLifts,
    List<Card>? discardedCards,
    List<Card>? playedCards,
    List<String>? passedPlayerIds,
    int? turnIndex,
    Object? lastCalledAt = $none,
    Object? gamePointLeaderId = $none,
    int? gamePointLeaderValue,
    Object? highTrumpPlayerId = $none,
    Object? highTrumpPlayedCard = $none,
    Object? lowTrumpPlayerId = $none,
    Object? lowTrumpPlayedCard = $none,
  }) => $apply(
    FieldCopyWithData({
      if (dealerId != null) #dealerId: dealerId,
      if (bidWinnerId != $none) #bidWinnerId: bidWinnerId,
      if (bidValue != null) #bidValue: bidValue,
      if (trumpSuit != $none) #trumpSuit: trumpSuit,
      if (phase != null) #phase: phase,
      if (currentLift != $none) #currentLift: currentLift,
      if (lastLift != $none) #lastLift: lastLift,
      if (completedLifts != null) #completedLifts: completedLifts,
      if (discardedCards != null) #discardedCards: discardedCards,
      if (playedCards != null) #playedCards: playedCards,
      if (passedPlayerIds != null) #passedPlayerIds: passedPlayerIds,
      if (turnIndex != null) #turnIndex: turnIndex,
      if (lastCalledAt != $none) #lastCalledAt: lastCalledAt,
      if (gamePointLeaderId != $none) #gamePointLeaderId: gamePointLeaderId,
      if (gamePointLeaderValue != null)
        #gamePointLeaderValue: gamePointLeaderValue,
      if (highTrumpPlayerId != $none) #highTrumpPlayerId: highTrumpPlayerId,
      if (highTrumpPlayedCard != $none)
        #highTrumpPlayedCard: highTrumpPlayedCard,
      if (lowTrumpPlayerId != $none) #lowTrumpPlayerId: lowTrumpPlayerId,
      if (lowTrumpPlayedCard != $none) #lowTrumpPlayedCard: lowTrumpPlayedCard,
    }),
  );
  @override
  RoundState $make(CopyWithData data) => RoundState(
    dealerId: data.get(#dealerId, or: $value.dealerId),
    bidWinnerId: data.get(#bidWinnerId, or: $value.bidWinnerId),
    bidValue: data.get(#bidValue, or: $value.bidValue),
    trumpSuit: data.get(#trumpSuit, or: $value.trumpSuit),
    phase: data.get(#phase, or: $value.phase),
    currentLift: data.get(#currentLift, or: $value.currentLift),
    lastLift: data.get(#lastLift, or: $value.lastLift),
    completedLifts: data.get(#completedLifts, or: $value.completedLifts),
    discardedCards: data.get(#discardedCards, or: $value.discardedCards),
    playedCards: data.get(#playedCards, or: $value.playedCards),
    passedPlayerIds: data.get(#passedPlayerIds, or: $value.passedPlayerIds),
    turnIndex: data.get(#turnIndex, or: $value.turnIndex),
    lastCalledAt: data.get(#lastCalledAt, or: $value.lastCalledAt),
    gamePointLeaderId: data.get(
      #gamePointLeaderId,
      or: $value.gamePointLeaderId,
    ),
    gamePointLeaderValue: data.get(
      #gamePointLeaderValue,
      or: $value.gamePointLeaderValue,
    ),
    highTrumpPlayerId: data.get(
      #highTrumpPlayerId,
      or: $value.highTrumpPlayerId,
    ),
    highTrumpPlayedCard: data.get(
      #highTrumpPlayedCard,
      or: $value.highTrumpPlayedCard,
    ),
    lowTrumpPlayerId: data.get(#lowTrumpPlayerId, or: $value.lowTrumpPlayerId),
    lowTrumpPlayedCard: data.get(
      #lowTrumpPlayedCard,
      or: $value.lowTrumpPlayedCard,
    ),
  );

  @override
  RoundStateCopyWith<$R2, RoundState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RoundStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayerRoundSummaryMapper extends ClassMapperBase<PlayerRoundSummary> {
  PlayerRoundSummaryMapper._();

  static PlayerRoundSummaryMapper? _instance;
  static PlayerRoundSummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayerRoundSummaryMapper._());
      CardMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayerRoundSummary';

  static String _$uid(PlayerRoundSummary v) => v.uid;
  static const Field<PlayerRoundSummary, String> _f$uid = Field('uid', _$uid);
  static int _$roundPoints(PlayerRoundSummary v) => v.roundPoints;
  static const Field<PlayerRoundSummary, int> _f$roundPoints = Field(
    'roundPoints',
    _$roundPoints,
    opt: true,
    def: 0,
  );
  static List<String> _$earnedPoints(PlayerRoundSummary v) => v.earnedPoints;
  static const Field<PlayerRoundSummary, List<String>> _f$earnedPoints = Field(
    'earnedPoints',
    _$earnedPoints,
    opt: true,
    def: const [],
  );
  static int _$totalScore(PlayerRoundSummary v) => v.totalScore;
  static const Field<PlayerRoundSummary, int> _f$totalScore = Field(
    'totalScore',
    _$totalScore,
    opt: true,
    def: 0,
  );
  static int _$gameValue(PlayerRoundSummary v) => v.gameValue;
  static const Field<PlayerRoundSummary, int> _f$gameValue = Field(
    'gameValue',
    _$gameValue,
    opt: true,
    def: 0,
  );
  static List<Card> _$capturedValueCards(PlayerRoundSummary v) =>
      v.capturedValueCards;
  static const Field<PlayerRoundSummary, List<Card>> _f$capturedValueCards =
      Field(
        'capturedValueCards',
        _$capturedValueCards,
        opt: true,
        def: const [],
      );
  static int _$wonLiftsCount(PlayerRoundSummary v) => v.wonLiftsCount;
  static const Field<PlayerRoundSummary, int> _f$wonLiftsCount = Field(
    'wonLiftsCount',
    _$wonLiftsCount,
    opt: true,
    def: 0,
  );

  @override
  final MappableFields<PlayerRoundSummary> fields = const {
    #uid: _f$uid,
    #roundPoints: _f$roundPoints,
    #earnedPoints: _f$earnedPoints,
    #totalScore: _f$totalScore,
    #gameValue: _f$gameValue,
    #capturedValueCards: _f$capturedValueCards,
    #wonLiftsCount: _f$wonLiftsCount,
  };

  static PlayerRoundSummary _instantiate(DecodingData data) {
    return PlayerRoundSummary(
      uid: data.dec(_f$uid),
      roundPoints: data.dec(_f$roundPoints),
      earnedPoints: data.dec(_f$earnedPoints),
      totalScore: data.dec(_f$totalScore),
      gameValue: data.dec(_f$gameValue),
      capturedValueCards: data.dec(_f$capturedValueCards),
      wonLiftsCount: data.dec(_f$wonLiftsCount),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayerRoundSummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayerRoundSummary>(map);
  }

  static PlayerRoundSummary fromJson(String json) {
    return ensureInitialized().decodeJson<PlayerRoundSummary>(json);
  }
}

mixin PlayerRoundSummaryMappable {
  String toJson() {
    return PlayerRoundSummaryMapper.ensureInitialized()
        .encodeJson<PlayerRoundSummary>(this as PlayerRoundSummary);
  }

  Map<String, dynamic> toMap() {
    return PlayerRoundSummaryMapper.ensureInitialized()
        .encodeMap<PlayerRoundSummary>(this as PlayerRoundSummary);
  }

  PlayerRoundSummaryCopyWith<
    PlayerRoundSummary,
    PlayerRoundSummary,
    PlayerRoundSummary
  >
  get copyWith =>
      _PlayerRoundSummaryCopyWithImpl<PlayerRoundSummary, PlayerRoundSummary>(
        this as PlayerRoundSummary,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayerRoundSummaryMapper.ensureInitialized().stringifyValue(
      this as PlayerRoundSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayerRoundSummaryMapper.ensureInitialized().equalsValue(
      this as PlayerRoundSummary,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayerRoundSummaryMapper.ensureInitialized().hashValue(
      this as PlayerRoundSummary,
    );
  }
}

extension PlayerRoundSummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayerRoundSummary, $Out> {
  PlayerRoundSummaryCopyWith<$R, PlayerRoundSummary, $Out>
  get $asPlayerRoundSummary => $base.as(
    (v, t, t2) => _PlayerRoundSummaryCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PlayerRoundSummaryCopyWith<
  $R,
  $In extends PlayerRoundSummary,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get earnedPoints;
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get capturedValueCards;
  $R call({
    String? uid,
    int? roundPoints,
    List<String>? earnedPoints,
    int? totalScore,
    int? gameValue,
    List<Card>? capturedValueCards,
    int? wonLiftsCount,
  });
  PlayerRoundSummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayerRoundSummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayerRoundSummary, $Out>
    implements PlayerRoundSummaryCopyWith<$R, PlayerRoundSummary, $Out> {
  _PlayerRoundSummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayerRoundSummary> $mapper =
      PlayerRoundSummaryMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get earnedPoints => ListCopyWith(
    $value.earnedPoints,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(earnedPoints: v),
  );
  @override
  ListCopyWith<$R, Card, CardCopyWith<$R, Card, Card>> get capturedValueCards =>
      ListCopyWith(
        $value.capturedValueCards,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(capturedValueCards: v),
      );
  @override
  $R call({
    String? uid,
    int? roundPoints,
    List<String>? earnedPoints,
    int? totalScore,
    int? gameValue,
    List<Card>? capturedValueCards,
    int? wonLiftsCount,
  }) => $apply(
    FieldCopyWithData({
      if (uid != null) #uid: uid,
      if (roundPoints != null) #roundPoints: roundPoints,
      if (earnedPoints != null) #earnedPoints: earnedPoints,
      if (totalScore != null) #totalScore: totalScore,
      if (gameValue != null) #gameValue: gameValue,
      if (capturedValueCards != null) #capturedValueCards: capturedValueCards,
      if (wonLiftsCount != null) #wonLiftsCount: wonLiftsCount,
    }),
  );
  @override
  PlayerRoundSummary $make(CopyWithData data) => PlayerRoundSummary(
    uid: data.get(#uid, or: $value.uid),
    roundPoints: data.get(#roundPoints, or: $value.roundPoints),
    earnedPoints: data.get(#earnedPoints, or: $value.earnedPoints),
    totalScore: data.get(#totalScore, or: $value.totalScore),
    gameValue: data.get(#gameValue, or: $value.gameValue),
    capturedValueCards: data.get(
      #capturedValueCards,
      or: $value.capturedValueCards,
    ),
    wonLiftsCount: data.get(#wonLiftsCount, or: $value.wonLiftsCount),
  );

  @override
  PlayerRoundSummaryCopyWith<$R2, PlayerRoundSummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayerRoundSummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class RoundSummaryMapper extends ClassMapperBase<RoundSummary> {
  RoundSummaryMapper._();

  static RoundSummaryMapper? _instance;
  static RoundSummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RoundSummaryMapper._());
      SuitMapper.ensureInitialized();
      CardMapper.ensureInitialized();
      PlayerRoundSummaryMapper.ensureInitialized();
      LiftMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RoundSummary';

  static int _$roundNumber(RoundSummary v) => v.roundNumber;
  static const Field<RoundSummary, int> _f$roundNumber = Field(
    'roundNumber',
    _$roundNumber,
    opt: true,
    def: 1,
  );
  static Suit? _$trumpSuit(RoundSummary v) => v.trumpSuit;
  static const Field<RoundSummary, Suit> _f$trumpSuit = Field(
    'trumpSuit',
    _$trumpSuit,
    opt: true,
  );
  static String _$bidWinnerId(RoundSummary v) => v.bidWinnerId;
  static const Field<RoundSummary, String> _f$bidWinnerId = Field(
    'bidWinnerId',
    _$bidWinnerId,
  );
  static int _$bidValue(RoundSummary v) => v.bidValue;
  static const Field<RoundSummary, int> _f$bidValue = Field(
    'bidValue',
    _$bidValue,
    opt: true,
    def: 0,
  );
  static bool _$bidSuccess(RoundSummary v) => v.bidSuccess;
  static const Field<RoundSummary, bool> _f$bidSuccess = Field(
    'bidSuccess',
    _$bidSuccess,
    opt: true,
    def: false,
  );
  static String? _$highTrumpPlayerId(RoundSummary v) => v.highTrumpPlayerId;
  static const Field<RoundSummary, String> _f$highTrumpPlayerId = Field(
    'highTrumpPlayerId',
    _$highTrumpPlayerId,
    opt: true,
  );
  static Card? _$highTrumpPlayedCard(RoundSummary v) => v.highTrumpPlayedCard;
  static const Field<RoundSummary, Card> _f$highTrumpPlayedCard = Field(
    'highTrumpPlayedCard',
    _$highTrumpPlayedCard,
    opt: true,
  );
  static String? _$lowTrumpPlayerId(RoundSummary v) => v.lowTrumpPlayerId;
  static const Field<RoundSummary, String> _f$lowTrumpPlayerId = Field(
    'lowTrumpPlayerId',
    _$lowTrumpPlayerId,
    opt: true,
  );
  static Card? _$lowTrumpPlayedCard(RoundSummary v) => v.lowTrumpPlayedCard;
  static const Field<RoundSummary, Card> _f$lowTrumpPlayedCard = Field(
    'lowTrumpPlayedCard',
    _$lowTrumpPlayedCard,
    opt: true,
  );
  static String? _$gameWinnerId(RoundSummary v) => v.gameWinnerId;
  static const Field<RoundSummary, String> _f$gameWinnerId = Field(
    'gameWinnerId',
    _$gameWinnerId,
    opt: true,
  );
  static int _$gameWinningScore(RoundSummary v) => v.gameWinningScore;
  static const Field<RoundSummary, int> _f$gameWinningScore = Field(
    'gameWinningScore',
    _$gameWinningScore,
    opt: true,
    def: 0,
  );
  static bool _$isGameTied(RoundSummary v) => v.isGameTied;
  static const Field<RoundSummary, bool> _f$isGameTied = Field(
    'isGameTied',
    _$isGameTied,
    opt: true,
    def: false,
  );
  static List<PlayerRoundSummary> _$playerSummaries(RoundSummary v) =>
      v.playerSummaries;
  static const Field<RoundSummary, List<PlayerRoundSummary>>
  _f$playerSummaries = Field(
    'playerSummaries',
    _$playerSummaries,
    opt: true,
    def: const [],
  );
  static List<Lift> _$completedLifts(RoundSummary v) => v.completedLifts;
  static const Field<RoundSummary, List<Lift>> _f$completedLifts = Field(
    'completedLifts',
    _$completedLifts,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<RoundSummary> fields = const {
    #roundNumber: _f$roundNumber,
    #trumpSuit: _f$trumpSuit,
    #bidWinnerId: _f$bidWinnerId,
    #bidValue: _f$bidValue,
    #bidSuccess: _f$bidSuccess,
    #highTrumpPlayerId: _f$highTrumpPlayerId,
    #highTrumpPlayedCard: _f$highTrumpPlayedCard,
    #lowTrumpPlayerId: _f$lowTrumpPlayerId,
    #lowTrumpPlayedCard: _f$lowTrumpPlayedCard,
    #gameWinnerId: _f$gameWinnerId,
    #gameWinningScore: _f$gameWinningScore,
    #isGameTied: _f$isGameTied,
    #playerSummaries: _f$playerSummaries,
    #completedLifts: _f$completedLifts,
  };

  static RoundSummary _instantiate(DecodingData data) {
    return RoundSummary(
      roundNumber: data.dec(_f$roundNumber),
      trumpSuit: data.dec(_f$trumpSuit),
      bidWinnerId: data.dec(_f$bidWinnerId),
      bidValue: data.dec(_f$bidValue),
      bidSuccess: data.dec(_f$bidSuccess),
      highTrumpPlayerId: data.dec(_f$highTrumpPlayerId),
      highTrumpPlayedCard: data.dec(_f$highTrumpPlayedCard),
      lowTrumpPlayerId: data.dec(_f$lowTrumpPlayerId),
      lowTrumpPlayedCard: data.dec(_f$lowTrumpPlayedCard),
      gameWinnerId: data.dec(_f$gameWinnerId),
      gameWinningScore: data.dec(_f$gameWinningScore),
      isGameTied: data.dec(_f$isGameTied),
      playerSummaries: data.dec(_f$playerSummaries),
      completedLifts: data.dec(_f$completedLifts),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RoundSummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RoundSummary>(map);
  }

  static RoundSummary fromJson(String json) {
    return ensureInitialized().decodeJson<RoundSummary>(json);
  }
}

mixin RoundSummaryMappable {
  String toJson() {
    return RoundSummaryMapper.ensureInitialized().encodeJson<RoundSummary>(
      this as RoundSummary,
    );
  }

  Map<String, dynamic> toMap() {
    return RoundSummaryMapper.ensureInitialized().encodeMap<RoundSummary>(
      this as RoundSummary,
    );
  }

  RoundSummaryCopyWith<RoundSummary, RoundSummary, RoundSummary> get copyWith =>
      _RoundSummaryCopyWithImpl<RoundSummary, RoundSummary>(
        this as RoundSummary,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RoundSummaryMapper.ensureInitialized().stringifyValue(
      this as RoundSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return RoundSummaryMapper.ensureInitialized().equalsValue(
      this as RoundSummary,
      other,
    );
  }

  @override
  int get hashCode {
    return RoundSummaryMapper.ensureInitialized().hashValue(
      this as RoundSummary,
    );
  }
}

extension RoundSummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RoundSummary, $Out> {
  RoundSummaryCopyWith<$R, RoundSummary, $Out> get $asRoundSummary =>
      $base.as((v, t, t2) => _RoundSummaryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RoundSummaryCopyWith<$R, $In extends RoundSummary, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  CardCopyWith<$R, Card, Card>? get highTrumpPlayedCard;
  CardCopyWith<$R, Card, Card>? get lowTrumpPlayedCard;
  ListCopyWith<
    $R,
    PlayerRoundSummary,
    PlayerRoundSummaryCopyWith<$R, PlayerRoundSummary, PlayerRoundSummary>
  >
  get playerSummaries;
  ListCopyWith<$R, Lift, LiftCopyWith<$R, Lift, Lift>> get completedLifts;
  $R call({
    int? roundNumber,
    Suit? trumpSuit,
    String? bidWinnerId,
    int? bidValue,
    bool? bidSuccess,
    String? highTrumpPlayerId,
    Card? highTrumpPlayedCard,
    String? lowTrumpPlayerId,
    Card? lowTrumpPlayedCard,
    String? gameWinnerId,
    int? gameWinningScore,
    bool? isGameTied,
    List<PlayerRoundSummary>? playerSummaries,
    List<Lift>? completedLifts,
  });
  RoundSummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _RoundSummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RoundSummary, $Out>
    implements RoundSummaryCopyWith<$R, RoundSummary, $Out> {
  _RoundSummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RoundSummary> $mapper =
      RoundSummaryMapper.ensureInitialized();
  @override
  CardCopyWith<$R, Card, Card>? get highTrumpPlayedCard => $value
      .highTrumpPlayedCard
      ?.copyWith
      .$chain((v) => call(highTrumpPlayedCard: v));
  @override
  CardCopyWith<$R, Card, Card>? get lowTrumpPlayedCard => $value
      .lowTrumpPlayedCard
      ?.copyWith
      .$chain((v) => call(lowTrumpPlayedCard: v));
  @override
  ListCopyWith<
    $R,
    PlayerRoundSummary,
    PlayerRoundSummaryCopyWith<$R, PlayerRoundSummary, PlayerRoundSummary>
  >
  get playerSummaries => ListCopyWith(
    $value.playerSummaries,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(playerSummaries: v),
  );
  @override
  ListCopyWith<$R, Lift, LiftCopyWith<$R, Lift, Lift>> get completedLifts =>
      ListCopyWith(
        $value.completedLifts,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(completedLifts: v),
      );
  @override
  $R call({
    int? roundNumber,
    Object? trumpSuit = $none,
    String? bidWinnerId,
    int? bidValue,
    bool? bidSuccess,
    Object? highTrumpPlayerId = $none,
    Object? highTrumpPlayedCard = $none,
    Object? lowTrumpPlayerId = $none,
    Object? lowTrumpPlayedCard = $none,
    Object? gameWinnerId = $none,
    int? gameWinningScore,
    bool? isGameTied,
    List<PlayerRoundSummary>? playerSummaries,
    List<Lift>? completedLifts,
  }) => $apply(
    FieldCopyWithData({
      if (roundNumber != null) #roundNumber: roundNumber,
      if (trumpSuit != $none) #trumpSuit: trumpSuit,
      if (bidWinnerId != null) #bidWinnerId: bidWinnerId,
      if (bidValue != null) #bidValue: bidValue,
      if (bidSuccess != null) #bidSuccess: bidSuccess,
      if (highTrumpPlayerId != $none) #highTrumpPlayerId: highTrumpPlayerId,
      if (highTrumpPlayedCard != $none)
        #highTrumpPlayedCard: highTrumpPlayedCard,
      if (lowTrumpPlayerId != $none) #lowTrumpPlayerId: lowTrumpPlayerId,
      if (lowTrumpPlayedCard != $none) #lowTrumpPlayedCard: lowTrumpPlayedCard,
      if (gameWinnerId != $none) #gameWinnerId: gameWinnerId,
      if (gameWinningScore != null) #gameWinningScore: gameWinningScore,
      if (isGameTied != null) #isGameTied: isGameTied,
      if (playerSummaries != null) #playerSummaries: playerSummaries,
      if (completedLifts != null) #completedLifts: completedLifts,
    }),
  );
  @override
  RoundSummary $make(CopyWithData data) => RoundSummary(
    roundNumber: data.get(#roundNumber, or: $value.roundNumber),
    trumpSuit: data.get(#trumpSuit, or: $value.trumpSuit),
    bidWinnerId: data.get(#bidWinnerId, or: $value.bidWinnerId),
    bidValue: data.get(#bidValue, or: $value.bidValue),
    bidSuccess: data.get(#bidSuccess, or: $value.bidSuccess),
    highTrumpPlayerId: data.get(
      #highTrumpPlayerId,
      or: $value.highTrumpPlayerId,
    ),
    highTrumpPlayedCard: data.get(
      #highTrumpPlayedCard,
      or: $value.highTrumpPlayedCard,
    ),
    lowTrumpPlayerId: data.get(#lowTrumpPlayerId, or: $value.lowTrumpPlayerId),
    lowTrumpPlayedCard: data.get(
      #lowTrumpPlayedCard,
      or: $value.lowTrumpPlayedCard,
    ),
    gameWinnerId: data.get(#gameWinnerId, or: $value.gameWinnerId),
    gameWinningScore: data.get(#gameWinningScore, or: $value.gameWinningScore),
    isGameTied: data.get(#isGameTied, or: $value.isGameTied),
    playerSummaries: data.get(#playerSummaries, or: $value.playerSummaries),
    completedLifts: data.get(#completedLifts, or: $value.completedLifts),
  );

  @override
  RoundSummaryCopyWith<$R2, RoundSummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RoundSummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GameSessionMapper extends ClassMapperBase<GameSession> {
  GameSessionMapper._();

  static GameSessionMapper? _instance;
  static GameSessionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GameSessionMapper._());
      PlayerGameStateMapper.ensureInitialized();
      RoundStateMapper.ensureInitialized();
      RoundSummaryMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GameSession';

  static String _$gameId(GameSession v) => v.gameId;
  static const Field<GameSession, String> _f$gameId = Field('gameId', _$gameId);
  static String? _$hostId(GameSession v) => v.hostId;
  static const Field<GameSession, String> _f$hostId = Field(
    'hostId',
    _$hostId,
    opt: true,
  );
  static String? _$name(GameSession v) => v.name;
  static const Field<GameSession, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static int _$targetScore(GameSession v) => v.targetScore;
  static const Field<GameSession, int> _f$targetScore = Field(
    'targetScore',
    _$targetScore,
    opt: true,
    def: 35,
  );
  static List<PlayerGameState> _$playerStates(GameSession v) => v.playerStates;
  static const Field<GameSession, List<PlayerGameState>> _f$playerStates =
      Field('playerStates', _$playerStates);
  static RoundState _$currentRound(GameSession v) => v.currentRound;
  static const Field<GameSession, RoundState> _f$currentRound = Field(
    'currentRound',
    _$currentRound,
  );
  static RoundSummary? _$lastRoundSummary(GameSession v) => v.lastRoundSummary;
  static const Field<GameSession, RoundSummary> _f$lastRoundSummary = Field(
    'lastRoundSummary',
    _$lastRoundSummary,
    opt: true,
  );
  static List<String> _$viewerIds(GameSession v) => v.viewerIds;
  static const Field<GameSession, List<String>> _f$viewerIds = Field(
    'viewerIds',
    _$viewerIds,
    opt: true,
    def: const [],
  );
  static Map<String, int> _$viewerHeartbeats(GameSession v) =>
      v.viewerHeartbeats;
  static const Field<GameSession, Map<String, int>> _f$viewerHeartbeats = Field(
    'viewerHeartbeats',
    _$viewerHeartbeats,
    opt: true,
    def: const {},
  );
  static bool _$isOpen(GameSession v) => v.isOpen;
  static const Field<GameSession, bool> _f$isOpen = Field(
    'isOpen',
    _$isOpen,
    opt: true,
    def: false,
  );
  static DateTime? _$updatedAt(GameSession v) => v.updatedAt;
  static const Field<GameSession, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
    opt: true,
  );
  static DateTime? _$createdAt(GameSession v) => v.createdAt;
  static const Field<GameSession, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    opt: true,
  );

  @override
  final MappableFields<GameSession> fields = const {
    #gameId: _f$gameId,
    #hostId: _f$hostId,
    #name: _f$name,
    #targetScore: _f$targetScore,
    #playerStates: _f$playerStates,
    #currentRound: _f$currentRound,
    #lastRoundSummary: _f$lastRoundSummary,
    #viewerIds: _f$viewerIds,
    #viewerHeartbeats: _f$viewerHeartbeats,
    #isOpen: _f$isOpen,
    #updatedAt: _f$updatedAt,
    #createdAt: _f$createdAt,
  };

  static GameSession _instantiate(DecodingData data) {
    return GameSession(
      gameId: data.dec(_f$gameId),
      hostId: data.dec(_f$hostId),
      name: data.dec(_f$name),
      targetScore: data.dec(_f$targetScore),
      playerStates: data.dec(_f$playerStates),
      currentRound: data.dec(_f$currentRound),
      lastRoundSummary: data.dec(_f$lastRoundSummary),
      viewerIds: data.dec(_f$viewerIds),
      viewerHeartbeats: data.dec(_f$viewerHeartbeats),
      isOpen: data.dec(_f$isOpen),
      updatedAt: data.dec(_f$updatedAt),
      createdAt: data.dec(_f$createdAt),
    );
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
    return GameSessionMapper.ensureInitialized().encodeJson<GameSession>(
      this as GameSession,
    );
  }

  Map<String, dynamic> toMap() {
    return GameSessionMapper.ensureInitialized().encodeMap<GameSession>(
      this as GameSession,
    );
  }

  GameSessionCopyWith<GameSession, GameSession, GameSession> get copyWith =>
      _GameSessionCopyWithImpl<GameSession, GameSession>(
        this as GameSession,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GameSessionMapper.ensureInitialized().stringifyValue(
      this as GameSession,
    );
  }

  @override
  bool operator ==(Object other) {
    return GameSessionMapper.ensureInitialized().equalsValue(
      this as GameSession,
      other,
    );
  }

  @override
  int get hashCode {
    return GameSessionMapper.ensureInitialized().hashValue(this as GameSession);
  }
}

extension GameSessionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GameSession, $Out> {
  GameSessionCopyWith<$R, GameSession, $Out> get $asGameSession =>
      $base.as((v, t, t2) => _GameSessionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GameSessionCopyWith<$R, $In extends GameSession, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    PlayerGameState,
    PlayerGameStateCopyWith<$R, PlayerGameState, PlayerGameState>
  >
  get playerStates;
  RoundStateCopyWith<$R, RoundState, RoundState> get currentRound;
  RoundSummaryCopyWith<$R, RoundSummary, RoundSummary>? get lastRoundSummary;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get viewerIds;
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
  get viewerHeartbeats;
  $R call({
    String? gameId,
    String? hostId,
    String? name,
    int? targetScore,
    List<PlayerGameState>? playerStates,
    RoundState? currentRound,
    RoundSummary? lastRoundSummary,
    List<String>? viewerIds,
    Map<String, int>? viewerHeartbeats,
    bool? isOpen,
    DateTime? updatedAt,
    DateTime? createdAt,
  });
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
  ListCopyWith<
    $R,
    PlayerGameState,
    PlayerGameStateCopyWith<$R, PlayerGameState, PlayerGameState>
  >
  get playerStates => ListCopyWith(
    $value.playerStates,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(playerStates: v),
  );
  @override
  RoundStateCopyWith<$R, RoundState, RoundState> get currentRound =>
      $value.currentRound.copyWith.$chain((v) => call(currentRound: v));
  @override
  RoundSummaryCopyWith<$R, RoundSummary, RoundSummary>? get lastRoundSummary =>
      $value.lastRoundSummary?.copyWith.$chain(
        (v) => call(lastRoundSummary: v),
      );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get viewerIds =>
      ListCopyWith(
        $value.viewerIds,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(viewerIds: v),
      );
  @override
  MapCopyWith<$R, String, int, ObjectCopyWith<$R, int, int>>
  get viewerHeartbeats => MapCopyWith(
    $value.viewerHeartbeats,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(viewerHeartbeats: v),
  );
  @override
  $R call({
    String? gameId,
    Object? hostId = $none,
    Object? name = $none,
    int? targetScore,
    List<PlayerGameState>? playerStates,
    RoundState? currentRound,
    Object? lastRoundSummary = $none,
    List<String>? viewerIds,
    Map<String, int>? viewerHeartbeats,
    bool? isOpen,
    Object? updatedAt = $none,
    Object? createdAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (gameId != null) #gameId: gameId,
      if (hostId != $none) #hostId: hostId,
      if (name != $none) #name: name,
      if (targetScore != null) #targetScore: targetScore,
      if (playerStates != null) #playerStates: playerStates,
      if (currentRound != null) #currentRound: currentRound,
      if (lastRoundSummary != $none) #lastRoundSummary: lastRoundSummary,
      if (viewerIds != null) #viewerIds: viewerIds,
      if (viewerHeartbeats != null) #viewerHeartbeats: viewerHeartbeats,
      if (isOpen != null) #isOpen: isOpen,
      if (updatedAt != $none) #updatedAt: updatedAt,
      if (createdAt != $none) #createdAt: createdAt,
    }),
  );
  @override
  GameSession $make(CopyWithData data) => GameSession(
    gameId: data.get(#gameId, or: $value.gameId),
    hostId: data.get(#hostId, or: $value.hostId),
    name: data.get(#name, or: $value.name),
    targetScore: data.get(#targetScore, or: $value.targetScore),
    playerStates: data.get(#playerStates, or: $value.playerStates),
    currentRound: data.get(#currentRound, or: $value.currentRound),
    lastRoundSummary: data.get(#lastRoundSummary, or: $value.lastRoundSummary),
    viewerIds: data.get(#viewerIds, or: $value.viewerIds),
    viewerHeartbeats: data.get(#viewerHeartbeats, or: $value.viewerHeartbeats),
    isOpen: data.get(#isOpen, or: $value.isOpen),
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
    createdAt: data.get(#createdAt, or: $value.createdAt),
  );

  @override
  GameSessionCopyWith<$R2, GameSession, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _GameSessionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

