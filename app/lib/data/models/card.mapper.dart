// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
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
      case r'clubs':
        return Suit.clubs;
      case r'diamonds':
        return Suit.diamonds;
      case r'hearts':
        return Suit.hearts;
      case r'spades':
        return Suit.spades;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Suit self) {
    switch (self) {
      case Suit.clubs:
        return r'clubs';
      case Suit.diamonds:
        return r'diamonds';
      case Suit.hearts:
        return r'hearts';
      case Suit.spades:
        return r'spades';
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
      case r'two':
        return Rank.two;
      case r'three':
        return Rank.three;
      case r'four':
        return Rank.four;
      case r'five':
        return Rank.five;
      case r'six':
        return Rank.six;
      case r'seven':
        return Rank.seven;
      case r'eight':
        return Rank.eight;
      case r'nine':
        return Rank.nine;
      case r'ten':
        return Rank.ten;
      case r'jack':
        return Rank.jack;
      case r'queen':
        return Rank.queen;
      case r'king':
        return Rank.king;
      case r'ace':
        return Rank.ace;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Rank self) {
    switch (self) {
      case Rank.two:
        return r'two';
      case Rank.three:
        return r'three';
      case Rank.four:
        return r'four';
      case Rank.five:
        return r'five';
      case Rank.six:
        return r'six';
      case Rank.seven:
        return r'seven';
      case Rank.eight:
        return r'eight';
      case Rank.nine:
        return r'nine';
      case Rank.ten:
        return r'ten';
      case Rank.jack:
        return r'jack';
      case Rank.queen:
        return r'queen';
      case Rank.king:
        return r'king';
      case Rank.ace:
        return r'ace';
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
  final MappableFields<Card> fields = const {#suit: _f$suit, #rank: _f$rank};

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
      _CardCopyWithImpl<Card, Card>(this as Card, $identity, $identity);
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
      $base.as((v, t, t2) => _CardCopyWithImpl<$R, $Out>(v, t, t2));
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
  $R call({Suit? suit, Rank? rank}) => $apply(
        FieldCopyWithData({
          if (suit != null) #suit: suit,
          if (rank != null) #rank: rank,
        }),
      );
  @override
  Card $make(CopyWithData data) => Card(
        suit: data.get(#suit, or: $value.suit),
        rank: data.get(#rank, or: $value.rank),
      );

  @override
  CardCopyWith<$R2, Card, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CardCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
