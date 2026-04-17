import 'package:dart_mappable/dart_mappable.dart';

part 'card.mapper.dart';

@MappableEnum()
enum Suit { clubs, diamonds, hearts, spades }

@MappableEnum()
enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace
}

@MappableClass()
class Card with CardMappable {
  final Suit suit;
  final Rank rank;

  const Card({required this.suit, required this.rank});

  static const fromMap = CardMapper.fromMap;

  @override
  String toString() => '${rank.name}_of_${suit.name}';
}
