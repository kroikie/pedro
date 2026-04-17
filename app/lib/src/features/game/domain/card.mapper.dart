// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'card.dart';

class SuitMapper extends EnumMapper<Suit> {
  SuitMapper._();

  static SuitMapper? _instance;
  static SuitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SuitMapper._());
    }
    return _instance!;
  }

  static Suit fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  Suit decode(dynamic value) {
    switch (value) {
      case 'clubs':
        return Suit.clubs;
      case 'diamonds':
        return Suit.diamonds;
      case 'hearts':
        return Suit.hearts;
      case 'spades':
        return Suit.spades;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Suit self) {
    switch (self) {
      case Suit.clubs:
        return 'clubs';
      case Suit.diamonds:
        return 'diamonds';
      case Suit.hearts:
        return 'hearts';
      case Suit.spades:
        return 'spades';
    }
  }
}

extension SuitMapperExtension on Suit {
  String toValue() {
    SuitMapper.ensureInitialized();
    return MapperContainer.globals.toValue<Suit>(this) as String;
  }
}

class RankMapper extends EnumMapper<Rank> {
  RankMapper._();

  static RankMapper? _instance;
  static RankMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RankMapper._());
    }
    return _instance!;
  }

  static Rank fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  Rank decode(dynamic value) {
    switch (value) {
      case 'two':
        return Rank.two;
      case 'three':
        return Rank.three;
      case 'four':
        return Rank.four;
      case 'five':
        return Rank.five;
      case 'six':
        return Rank.six;
      case 'seven':
        return Rank.seven;
      case 'eight':
        return Rank.eight;
      case 'nine':
        return Rank.nine;
      case 'ten':
        return Rank.ten;
      case 'jack':
        return Rank.jack;
      case 'queen':
        return Rank.queen;
      case 'king':
        return Rank.king;
      case 'ace':
        return Rank.ace;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Rank self) {
    switch (self) {
      case Rank.two:
        return 'two';
      case Rank.three:
        return 'three';
      case Rank.four:
        return 'four';
      case Rank.five:
        return 'five';
      case Rank.six:
        return 'six';
      case Rank.seven:
        return 'seven';
      case Rank.eight:
        return 'eight';
      case Rank.nine:
        return 'nine';
      case Rank.ten:
        return 'ten';
      case Rank.jack:
        return 'jack';
      case Rank.queen:
        return 'queen';
      case Rank.king:
        return 'king';
      case Rank.ace:
        return 'ace';
    }
  }
}

extension RankMapperExtension on Rank {
  String toValue() {
    RankMapper.ensureInitialized();
    return MapperContainer.globals.toValue<Rank>(this) as String;
  }
}

class CardMapper extends ClassMapperBase<Card> {
  CardMapper._();

  static CardMapper? _instance;
  static CardMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CardMapper._());
      SuitMapper.ensureInitialized();
      RankMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Card';

  static Suit _$suit(Card v) => v.suit;
  static const Field<Card, Suit> _f$suit = Field('suit', _$suit);
  static Rank _$rank(Card v) => v.rank;
  static const Field<Card, Rank> _f$rank = Field('rank', _$rank);

  @override
  final MappableFields<Card> fields = const {
    #suit: _f$suit,
    #rank: _f$rank,
  };

  static Card _instantiate(DecodingData data) {
    return Card(suit: data.dec(_f$suit), rank: data.dec(_f$rank));
  }

  @override
  final Function instantiate = _instantiate;

  static Card fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Card>(map);
  }

  static Card fromJson(String json) {
    return ensureInitialized().decodeJson<Card>(json);
  }
}

mixin CardMappable {
  String toJson() {
    return CardMapper.ensureInitialized().encodeJson<Card>(this as Card);
  }

  Map<String, dynamic> toMap() {
    return CardMapper.ensureInitialized().encodeMap<Card>(this as Card);
  }

  CardCopyWith<Card, Card, Card> get copyWith =>
      _CardCopyWithImpl(this as Card, $identity, $identity);
  @override
  String toString() {
    return CardMapper.ensureInitialized().stringifyValue(this as Card);
  }

  @override
  bool operator ==(Object other) {
    return CardMapper.ensureInitialized().equalsValue(this as Card, other);
  }

  @override
  int get hashCode {
    return CardMapper.ensureInitialized().hashValue(this as Card);
  }
}

extension CardValueCopy<$R, $Out> on ObjectCopyWith<$R, Card, $Out> {
  CardCopyWith<$R, Card, $Out> get $asCard =>
      $base.as((v, t, t2) => _CardCopyWithImpl(v, t, t2));
}

abstract class CardCopyWith<$R, $In extends Card, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({Suit? suit, Rank? rank});
  CardCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CardCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Card, $Out>
    implements CardCopyWith<$R, Card, $Out> {
  _CardCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Card> $mapper = CardMapper.ensureInitialized();
  @override
  $R call({Suit? suit, Rank? rank}) => $apply(FieldCopyWithData(
      {if (suit != null) #suit: suit, if (rank != null) #rank: rank}));
  @override
  Card $make(CopyWithData data) => Card(
      suit: data.get(#suit, or: $value.suit),
      rank: data.get(#rank, or: $value.rank));

  @override
  CardCopyWith<$R2, Card, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CardCopyWithImpl($value, $cast, t);
}
