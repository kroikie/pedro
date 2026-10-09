// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'leaderboard_entry.dart';

class LeaderboardCategoryMapper extends EnumMapper<LeaderboardCategory> {
  LeaderboardCategoryMapper._();

  static LeaderboardCategoryMapper? _instance;
  static LeaderboardCategoryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LeaderboardCategoryMapper._());
    }
    return _instance!;
  }

  static LeaderboardCategory fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LeaderboardCategory decode(dynamic value) {
    switch (value) {
      case r'hangJacks':
        return LeaderboardCategory.hangJacks;
      case r'highTrumps':
        return LeaderboardCategory.highTrumps;
      case r'lowTrumps':
        return LeaderboardCategory.lowTrumps;
      case r'gamesWon':
        return LeaderboardCategory.gamesWon;
      case r'fivesWon':
        return LeaderboardCategory.fivesWon;
      case r'ninesWon':
        return LeaderboardCategory.ninesWon;
      case r'bidsMade':
        return LeaderboardCategory.bidsMade;
      case r'gamePointsWon':
        return LeaderboardCategory.gamePointsWon;
      case r'jacksHung':
        return LeaderboardCategory.jacksHung;
      case r'ninesLost':
        return LeaderboardCategory.ninesLost;
      case r'fivesLost':
        return LeaderboardCategory.fivesLost;
      case r'bidsSet':
        return LeaderboardCategory.bidsSet;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(LeaderboardCategory self) {
    switch (self) {
      case LeaderboardCategory.hangJacks:
        return r'hangJacks';
      case LeaderboardCategory.highTrumps:
        return r'highTrumps';
      case LeaderboardCategory.lowTrumps:
        return r'lowTrumps';
      case LeaderboardCategory.gamesWon:
        return r'gamesWon';
      case LeaderboardCategory.fivesWon:
        return r'fivesWon';
      case LeaderboardCategory.ninesWon:
        return r'ninesWon';
      case LeaderboardCategory.bidsMade:
        return r'bidsMade';
      case LeaderboardCategory.gamePointsWon:
        return r'gamePointsWon';
      case LeaderboardCategory.jacksHung:
        return r'jacksHung';
      case LeaderboardCategory.ninesLost:
        return r'ninesLost';
      case LeaderboardCategory.fivesLost:
        return r'fivesLost';
      case LeaderboardCategory.bidsSet:
        return r'bidsSet';
    }
  }
}

extension LeaderboardCategoryMapperExtension on LeaderboardCategory {
  String toValue() {
    LeaderboardCategoryMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LeaderboardCategory>(this) as String;
  }
}

class LeaderboardEntryMapper extends ClassMapperBase<LeaderboardEntry> {
  LeaderboardEntryMapper._();

  static LeaderboardEntryMapper? _instance;
  static LeaderboardEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LeaderboardEntryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LeaderboardEntry';

  static String _$uid(LeaderboardEntry v) => v.uid;
  static const Field<LeaderboardEntry, String> _f$uid = Field('uid', _$uid);
  static String _$screenName(LeaderboardEntry v) => v.screenName;
  static const Field<LeaderboardEntry, String> _f$screenName = Field(
    'screenName',
    _$screenName,
  );
  static String? _$avatarUrl(LeaderboardEntry v) => v.avatarUrl;
  static const Field<LeaderboardEntry, String> _f$avatarUrl = Field(
    'avatarUrl',
    _$avatarUrl,
    opt: true,
  );
  static String _$periodId(LeaderboardEntry v) => v.periodId;
  static const Field<LeaderboardEntry, String> _f$periodId = Field(
    'periodId',
    _$periodId,
    opt: true,
    def: 'all_time',
  );
  static int _$hangJacks(LeaderboardEntry v) => v.hangJacks;
  static const Field<LeaderboardEntry, int> _f$hangJacks = Field(
    'hangJacks',
    _$hangJacks,
    opt: true,
    def: 0,
  );
  static int _$jacksSaved(LeaderboardEntry v) => v.jacksSaved;
  static const Field<LeaderboardEntry, int> _f$jacksSaved = Field(
    'jacksSaved',
    _$jacksSaved,
    opt: true,
    def: 0,
  );
  static int _$highTrumps(LeaderboardEntry v) => v.highTrumps;
  static const Field<LeaderboardEntry, int> _f$highTrumps = Field(
    'highTrumps',
    _$highTrumps,
    opt: true,
    def: 0,
  );
  static int _$lowTrumps(LeaderboardEntry v) => v.lowTrumps;
  static const Field<LeaderboardEntry, int> _f$lowTrumps = Field(
    'lowTrumps',
    _$lowTrumps,
    opt: true,
    def: 0,
  );
  static int _$fivesWon(LeaderboardEntry v) => v.fivesWon;
  static const Field<LeaderboardEntry, int> _f$fivesWon = Field(
    'fivesWon',
    _$fivesWon,
    opt: true,
    def: 0,
  );
  static int _$ninesWon(LeaderboardEntry v) => v.ninesWon;
  static const Field<LeaderboardEntry, int> _f$ninesWon = Field(
    'ninesWon',
    _$ninesWon,
    opt: true,
    def: 0,
  );
  static int _$gamePointsWon(LeaderboardEntry v) => v.gamePointsWon;
  static const Field<LeaderboardEntry, int> _f$gamePointsWon = Field(
    'gamePointsWon',
    _$gamePointsWon,
    opt: true,
    def: 0,
  );
  static int _$bidsWon(LeaderboardEntry v) => v.bidsWon;
  static const Field<LeaderboardEntry, int> _f$bidsWon = Field(
    'bidsWon',
    _$bidsWon,
    opt: true,
    def: 0,
  );
  static int _$bidsMade(LeaderboardEntry v) => v.bidsMade;
  static const Field<LeaderboardEntry, int> _f$bidsMade = Field(
    'bidsMade',
    _$bidsMade,
    opt: true,
    def: 0,
  );
  static int _$gamesWon(LeaderboardEntry v) => v.gamesWon;
  static const Field<LeaderboardEntry, int> _f$gamesWon = Field(
    'gamesWon',
    _$gamesWon,
    opt: true,
    def: 0,
  );
  static int _$totalPointsEarned(LeaderboardEntry v) => v.totalPointsEarned;
  static const Field<LeaderboardEntry, int> _f$totalPointsEarned = Field(
    'totalPointsEarned',
    _$totalPointsEarned,
    opt: true,
    def: 0,
  );
  static int _$jacksHung(LeaderboardEntry v) => v.jacksHung;
  static const Field<LeaderboardEntry, int> _f$jacksHung = Field(
    'jacksHung',
    _$jacksHung,
    opt: true,
    def: 0,
  );
  static int _$ninesLost(LeaderboardEntry v) => v.ninesLost;
  static const Field<LeaderboardEntry, int> _f$ninesLost = Field(
    'ninesLost',
    _$ninesLost,
    opt: true,
    def: 0,
  );
  static int _$fivesLost(LeaderboardEntry v) => v.fivesLost;
  static const Field<LeaderboardEntry, int> _f$fivesLost = Field(
    'fivesLost',
    _$fivesLost,
    opt: true,
    def: 0,
  );
  static int _$bidsSet(LeaderboardEntry v) => v.bidsSet;
  static const Field<LeaderboardEntry, int> _f$bidsSet = Field(
    'bidsSet',
    _$bidsSet,
    opt: true,
    def: 0,
  );
  static int _$roundsPlayed(LeaderboardEntry v) => v.roundsPlayed;
  static const Field<LeaderboardEntry, int> _f$roundsPlayed = Field(
    'roundsPlayed',
    _$roundsPlayed,
    opt: true,
    def: 0,
  );
  static int _$gamesPlayed(LeaderboardEntry v) => v.gamesPlayed;
  static const Field<LeaderboardEntry, int> _f$gamesPlayed = Field(
    'gamesPlayed',
    _$gamesPlayed,
    opt: true,
    def: 0,
  );
  static DateTime? _$updatedAt(LeaderboardEntry v) => v.updatedAt;
  static const Field<LeaderboardEntry, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
    opt: true,
  );

  @override
  final MappableFields<LeaderboardEntry> fields = const {
    #uid: _f$uid,
    #screenName: _f$screenName,
    #avatarUrl: _f$avatarUrl,
    #periodId: _f$periodId,
    #hangJacks: _f$hangJacks,
    #jacksSaved: _f$jacksSaved,
    #highTrumps: _f$highTrumps,
    #lowTrumps: _f$lowTrumps,
    #fivesWon: _f$fivesWon,
    #ninesWon: _f$ninesWon,
    #gamePointsWon: _f$gamePointsWon,
    #bidsWon: _f$bidsWon,
    #bidsMade: _f$bidsMade,
    #gamesWon: _f$gamesWon,
    #totalPointsEarned: _f$totalPointsEarned,
    #jacksHung: _f$jacksHung,
    #ninesLost: _f$ninesLost,
    #fivesLost: _f$fivesLost,
    #bidsSet: _f$bidsSet,
    #roundsPlayed: _f$roundsPlayed,
    #gamesPlayed: _f$gamesPlayed,
    #updatedAt: _f$updatedAt,
  };

  static LeaderboardEntry _instantiate(DecodingData data) {
    return LeaderboardEntry(
      uid: data.dec(_f$uid),
      screenName: data.dec(_f$screenName),
      avatarUrl: data.dec(_f$avatarUrl),
      periodId: data.dec(_f$periodId),
      hangJacks: data.dec(_f$hangJacks),
      jacksSaved: data.dec(_f$jacksSaved),
      highTrumps: data.dec(_f$highTrumps),
      lowTrumps: data.dec(_f$lowTrumps),
      fivesWon: data.dec(_f$fivesWon),
      ninesWon: data.dec(_f$ninesWon),
      gamePointsWon: data.dec(_f$gamePointsWon),
      bidsWon: data.dec(_f$bidsWon),
      bidsMade: data.dec(_f$bidsMade),
      gamesWon: data.dec(_f$gamesWon),
      totalPointsEarned: data.dec(_f$totalPointsEarned),
      jacksHung: data.dec(_f$jacksHung),
      ninesLost: data.dec(_f$ninesLost),
      fivesLost: data.dec(_f$fivesLost),
      bidsSet: data.dec(_f$bidsSet),
      roundsPlayed: data.dec(_f$roundsPlayed),
      gamesPlayed: data.dec(_f$gamesPlayed),
      updatedAt: data.dec(_f$updatedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LeaderboardEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LeaderboardEntry>(map);
  }

  static LeaderboardEntry fromJson(String json) {
    return ensureInitialized().decodeJson<LeaderboardEntry>(json);
  }
}

mixin LeaderboardEntryMappable {
  String toJson() {
    return LeaderboardEntryMapper.ensureInitialized()
        .encodeJson<LeaderboardEntry>(this as LeaderboardEntry);
  }

  Map<String, dynamic> toMap() {
    return LeaderboardEntryMapper.ensureInitialized()
        .encodeMap<LeaderboardEntry>(this as LeaderboardEntry);
  }

  LeaderboardEntryCopyWith<LeaderboardEntry, LeaderboardEntry, LeaderboardEntry>
  get copyWith =>
      _LeaderboardEntryCopyWithImpl<LeaderboardEntry, LeaderboardEntry>(
        this as LeaderboardEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LeaderboardEntryMapper.ensureInitialized().stringifyValue(
      this as LeaderboardEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return LeaderboardEntryMapper.ensureInitialized().equalsValue(
      this as LeaderboardEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return LeaderboardEntryMapper.ensureInitialized().hashValue(
      this as LeaderboardEntry,
    );
  }
}

extension LeaderboardEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LeaderboardEntry, $Out> {
  LeaderboardEntryCopyWith<$R, LeaderboardEntry, $Out>
  get $asLeaderboardEntry =>
      $base.as((v, t, t2) => _LeaderboardEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LeaderboardEntryCopyWith<$R, $In extends LeaderboardEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? uid,
    String? screenName,
    String? avatarUrl,
    String? periodId,
    int? hangJacks,
    int? jacksSaved,
    int? highTrumps,
    int? lowTrumps,
    int? fivesWon,
    int? ninesWon,
    int? gamePointsWon,
    int? bidsWon,
    int? bidsMade,
    int? gamesWon,
    int? totalPointsEarned,
    int? jacksHung,
    int? ninesLost,
    int? fivesLost,
    int? bidsSet,
    int? roundsPlayed,
    int? gamesPlayed,
    DateTime? updatedAt,
  });
  LeaderboardEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _LeaderboardEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LeaderboardEntry, $Out>
    implements LeaderboardEntryCopyWith<$R, LeaderboardEntry, $Out> {
  _LeaderboardEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LeaderboardEntry> $mapper =
      LeaderboardEntryMapper.ensureInitialized();
  @override
  $R call({
    String? uid,
    String? screenName,
    Object? avatarUrl = $none,
    String? periodId,
    int? hangJacks,
    int? jacksSaved,
    int? highTrumps,
    int? lowTrumps,
    int? fivesWon,
    int? ninesWon,
    int? gamePointsWon,
    int? bidsWon,
    int? bidsMade,
    int? gamesWon,
    int? totalPointsEarned,
    int? jacksHung,
    int? ninesLost,
    int? fivesLost,
    int? bidsSet,
    int? roundsPlayed,
    int? gamesPlayed,
    Object? updatedAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (uid != null) #uid: uid,
      if (screenName != null) #screenName: screenName,
      if (avatarUrl != $none) #avatarUrl: avatarUrl,
      if (periodId != null) #periodId: periodId,
      if (hangJacks != null) #hangJacks: hangJacks,
      if (jacksSaved != null) #jacksSaved: jacksSaved,
      if (highTrumps != null) #highTrumps: highTrumps,
      if (lowTrumps != null) #lowTrumps: lowTrumps,
      if (fivesWon != null) #fivesWon: fivesWon,
      if (ninesWon != null) #ninesWon: ninesWon,
      if (gamePointsWon != null) #gamePointsWon: gamePointsWon,
      if (bidsWon != null) #bidsWon: bidsWon,
      if (bidsMade != null) #bidsMade: bidsMade,
      if (gamesWon != null) #gamesWon: gamesWon,
      if (totalPointsEarned != null) #totalPointsEarned: totalPointsEarned,
      if (jacksHung != null) #jacksHung: jacksHung,
      if (ninesLost != null) #ninesLost: ninesLost,
      if (fivesLost != null) #fivesLost: fivesLost,
      if (bidsSet != null) #bidsSet: bidsSet,
      if (roundsPlayed != null) #roundsPlayed: roundsPlayed,
      if (gamesPlayed != null) #gamesPlayed: gamesPlayed,
      if (updatedAt != $none) #updatedAt: updatedAt,
    }),
  );
  @override
  LeaderboardEntry $make(CopyWithData data) => LeaderboardEntry(
    uid: data.get(#uid, or: $value.uid),
    screenName: data.get(#screenName, or: $value.screenName),
    avatarUrl: data.get(#avatarUrl, or: $value.avatarUrl),
    periodId: data.get(#periodId, or: $value.periodId),
    hangJacks: data.get(#hangJacks, or: $value.hangJacks),
    jacksSaved: data.get(#jacksSaved, or: $value.jacksSaved),
    highTrumps: data.get(#highTrumps, or: $value.highTrumps),
    lowTrumps: data.get(#lowTrumps, or: $value.lowTrumps),
    fivesWon: data.get(#fivesWon, or: $value.fivesWon),
    ninesWon: data.get(#ninesWon, or: $value.ninesWon),
    gamePointsWon: data.get(#gamePointsWon, or: $value.gamePointsWon),
    bidsWon: data.get(#bidsWon, or: $value.bidsWon),
    bidsMade: data.get(#bidsMade, or: $value.bidsMade),
    gamesWon: data.get(#gamesWon, or: $value.gamesWon),
    totalPointsEarned: data.get(
      #totalPointsEarned,
      or: $value.totalPointsEarned,
    ),
    jacksHung: data.get(#jacksHung, or: $value.jacksHung),
    ninesLost: data.get(#ninesLost, or: $value.ninesLost),
    fivesLost: data.get(#fivesLost, or: $value.fivesLost),
    bidsSet: data.get(#bidsSet, or: $value.bidsSet),
    roundsPlayed: data.get(#roundsPlayed, or: $value.roundsPlayed),
    gamesPlayed: data.get(#gamesPlayed, or: $value.gamesPlayed),
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
  );

  @override
  LeaderboardEntryCopyWith<$R2, LeaderboardEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LeaderboardEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class RivalryEntryMapper extends ClassMapperBase<RivalryEntry> {
  RivalryEntryMapper._();

  static RivalryEntryMapper? _instance;
  static RivalryEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RivalryEntryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'RivalryEntry';

  static String _$id(RivalryEntry v) => v.id;
  static const Field<RivalryEntry, String> _f$id = Field('id', _$id);
  static String _$periodId(RivalryEntry v) => v.periodId;
  static const Field<RivalryEntry, String> _f$periodId = Field(
    'periodId',
    _$periodId,
    opt: true,
    def: 'all_time',
  );
  static String _$actorUid(RivalryEntry v) => v.actorUid;
  static const Field<RivalryEntry, String> _f$actorUid = Field(
    'actorUid',
    _$actorUid,
  );
  static String _$actorName(RivalryEntry v) => v.actorName;
  static const Field<RivalryEntry, String> _f$actorName = Field(
    'actorName',
    _$actorName,
  );
  static String? _$actorAvatarUrl(RivalryEntry v) => v.actorAvatarUrl;
  static const Field<RivalryEntry, String> _f$actorAvatarUrl = Field(
    'actorAvatarUrl',
    _$actorAvatarUrl,
    opt: true,
  );
  static String _$victimUid(RivalryEntry v) => v.victimUid;
  static const Field<RivalryEntry, String> _f$victimUid = Field(
    'victimUid',
    _$victimUid,
  );
  static String _$victimName(RivalryEntry v) => v.victimName;
  static const Field<RivalryEntry, String> _f$victimName = Field(
    'victimName',
    _$victimName,
  );
  static String? _$victimAvatarUrl(RivalryEntry v) => v.victimAvatarUrl;
  static const Field<RivalryEntry, String> _f$victimAvatarUrl = Field(
    'victimAvatarUrl',
    _$victimAvatarUrl,
    opt: true,
  );
  static int _$jacksHung(RivalryEntry v) => v.jacksHung;
  static const Field<RivalryEntry, int> _f$jacksHung = Field(
    'jacksHung',
    _$jacksHung,
    opt: true,
    def: 0,
  );
  static int _$ninesStolen(RivalryEntry v) => v.ninesStolen;
  static const Field<RivalryEntry, int> _f$ninesStolen = Field(
    'ninesStolen',
    _$ninesStolen,
    opt: true,
    def: 0,
  );
  static int _$fivesStolen(RivalryEntry v) => v.fivesStolen;
  static const Field<RivalryEntry, int> _f$fivesStolen = Field(
    'fivesStolen',
    _$fivesStolen,
    opt: true,
    def: 0,
  );
  static int _$heistCount(RivalryEntry v) => v.heistCount;
  static const Field<RivalryEntry, int> _f$heistCount = Field(
    'heistCount',
    _$heistCount,
    opt: true,
    def: 0,
  );
  static int _$heistPoints(RivalryEntry v) => v.heistPoints;
  static const Field<RivalryEntry, int> _f$heistPoints = Field(
    'heistPoints',
    _$heistPoints,
    opt: true,
    def: 0,
  );
  static int _$matchesWonAgainst(RivalryEntry v) => v.matchesWonAgainst;
  static const Field<RivalryEntry, int> _f$matchesWonAgainst = Field(
    'matchesWonAgainst',
    _$matchesWonAgainst,
    opt: true,
    def: 0,
  );
  static DateTime? _$updatedAt(RivalryEntry v) => v.updatedAt;
  static const Field<RivalryEntry, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
    opt: true,
  );

  @override
  final MappableFields<RivalryEntry> fields = const {
    #id: _f$id,
    #periodId: _f$periodId,
    #actorUid: _f$actorUid,
    #actorName: _f$actorName,
    #actorAvatarUrl: _f$actorAvatarUrl,
    #victimUid: _f$victimUid,
    #victimName: _f$victimName,
    #victimAvatarUrl: _f$victimAvatarUrl,
    #jacksHung: _f$jacksHung,
    #ninesStolen: _f$ninesStolen,
    #fivesStolen: _f$fivesStolen,
    #heistCount: _f$heistCount,
    #heistPoints: _f$heistPoints,
    #matchesWonAgainst: _f$matchesWonAgainst,
    #updatedAt: _f$updatedAt,
  };

  static RivalryEntry _instantiate(DecodingData data) {
    return RivalryEntry(
      id: data.dec(_f$id),
      periodId: data.dec(_f$periodId),
      actorUid: data.dec(_f$actorUid),
      actorName: data.dec(_f$actorName),
      actorAvatarUrl: data.dec(_f$actorAvatarUrl),
      victimUid: data.dec(_f$victimUid),
      victimName: data.dec(_f$victimName),
      victimAvatarUrl: data.dec(_f$victimAvatarUrl),
      jacksHung: data.dec(_f$jacksHung),
      ninesStolen: data.dec(_f$ninesStolen),
      fivesStolen: data.dec(_f$fivesStolen),
      heistCount: data.dec(_f$heistCount),
      heistPoints: data.dec(_f$heistPoints),
      matchesWonAgainst: data.dec(_f$matchesWonAgainst),
      updatedAt: data.dec(_f$updatedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RivalryEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RivalryEntry>(map);
  }

  static RivalryEntry fromJson(String json) {
    return ensureInitialized().decodeJson<RivalryEntry>(json);
  }
}

mixin RivalryEntryMappable {
  String toJson() {
    return RivalryEntryMapper.ensureInitialized().encodeJson<RivalryEntry>(
      this as RivalryEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return RivalryEntryMapper.ensureInitialized().encodeMap<RivalryEntry>(
      this as RivalryEntry,
    );
  }

  RivalryEntryCopyWith<RivalryEntry, RivalryEntry, RivalryEntry> get copyWith =>
      _RivalryEntryCopyWithImpl<RivalryEntry, RivalryEntry>(
        this as RivalryEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RivalryEntryMapper.ensureInitialized().stringifyValue(
      this as RivalryEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return RivalryEntryMapper.ensureInitialized().equalsValue(
      this as RivalryEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return RivalryEntryMapper.ensureInitialized().hashValue(
      this as RivalryEntry,
    );
  }
}

extension RivalryEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RivalryEntry, $Out> {
  RivalryEntryCopyWith<$R, RivalryEntry, $Out> get $asRivalryEntry =>
      $base.as((v, t, t2) => _RivalryEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RivalryEntryCopyWith<$R, $In extends RivalryEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? periodId,
    String? actorUid,
    String? actorName,
    String? actorAvatarUrl,
    String? victimUid,
    String? victimName,
    String? victimAvatarUrl,
    int? jacksHung,
    int? ninesStolen,
    int? fivesStolen,
    int? heistCount,
    int? heistPoints,
    int? matchesWonAgainst,
    DateTime? updatedAt,
  });
  RivalryEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _RivalryEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RivalryEntry, $Out>
    implements RivalryEntryCopyWith<$R, RivalryEntry, $Out> {
  _RivalryEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RivalryEntry> $mapper =
      RivalryEntryMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? periodId,
    String? actorUid,
    String? actorName,
    Object? actorAvatarUrl = $none,
    String? victimUid,
    String? victimName,
    Object? victimAvatarUrl = $none,
    int? jacksHung,
    int? ninesStolen,
    int? fivesStolen,
    int? heistCount,
    int? heistPoints,
    int? matchesWonAgainst,
    Object? updatedAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (periodId != null) #periodId: periodId,
      if (actorUid != null) #actorUid: actorUid,
      if (actorName != null) #actorName: actorName,
      if (actorAvatarUrl != $none) #actorAvatarUrl: actorAvatarUrl,
      if (victimUid != null) #victimUid: victimUid,
      if (victimName != null) #victimName: victimName,
      if (victimAvatarUrl != $none) #victimAvatarUrl: victimAvatarUrl,
      if (jacksHung != null) #jacksHung: jacksHung,
      if (ninesStolen != null) #ninesStolen: ninesStolen,
      if (fivesStolen != null) #fivesStolen: fivesStolen,
      if (heistCount != null) #heistCount: heistCount,
      if (heistPoints != null) #heistPoints: heistPoints,
      if (matchesWonAgainst != null) #matchesWonAgainst: matchesWonAgainst,
      if (updatedAt != $none) #updatedAt: updatedAt,
    }),
  );
  @override
  RivalryEntry $make(CopyWithData data) => RivalryEntry(
    id: data.get(#id, or: $value.id),
    periodId: data.get(#periodId, or: $value.periodId),
    actorUid: data.get(#actorUid, or: $value.actorUid),
    actorName: data.get(#actorName, or: $value.actorName),
    actorAvatarUrl: data.get(#actorAvatarUrl, or: $value.actorAvatarUrl),
    victimUid: data.get(#victimUid, or: $value.victimUid),
    victimName: data.get(#victimName, or: $value.victimName),
    victimAvatarUrl: data.get(#victimAvatarUrl, or: $value.victimAvatarUrl),
    jacksHung: data.get(#jacksHung, or: $value.jacksHung),
    ninesStolen: data.get(#ninesStolen, or: $value.ninesStolen),
    fivesStolen: data.get(#fivesStolen, or: $value.fivesStolen),
    heistCount: data.get(#heistCount, or: $value.heistCount),
    heistPoints: data.get(#heistPoints, or: $value.heistPoints),
    matchesWonAgainst: data.get(
      #matchesWonAgainst,
      or: $value.matchesWonAgainst,
    ),
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
  );

  @override
  RivalryEntryCopyWith<$R2, RivalryEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RivalryEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

