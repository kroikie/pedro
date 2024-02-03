import 'dart:math';

import 'package:flutter/foundation.dart';

import 'card_suit.dart';

@immutable
class PlayingCard {
  static final _random = Random();

  final CardSuit suit;
  final int value;

  const PlayingCard(this.suit, this.value);

  factory PlayingCard.fromJson(Map<String, dynamic> json) {
    return PlayingCard(
      CardSuit.values
          .singleWhere((e) => e.internalRepresentation == json['suit']),
      json['value'] as int,
    );
  }

  factory PlayingCard.fromInt(int num) {
    CardSuit suite = _getCardSuit(num);
    final value = _getCardValue(num);
    return PlayingCard(suite, value);
  }

  static CardSuit _getCardSuit(int num) {
    if (num == 0) {
      return CardSuit.hearts;
    }
    return switch(num ~/ 13) {
      0 => CardSuit.hearts,
      1 => CardSuit.clubs,
      2 => CardSuit.diamonds,
      3 => CardSuit.spades,
      _ => CardSuit.hearts,
    };
  }

  static int _getCardValue(int num) {
    if (num == 0) {
      return 2;
    }
    return (num % 13) + 2;
  }

  factory PlayingCard.random([Random? random]) {
    random ??= _random;
    return PlayingCard(
      CardSuit.values[random.nextInt(CardSuit.values.length)],
      2 + random.nextInt(9),
    );
  }

  @override
  int get hashCode => Object.hash(suit, value);

  @override
  bool operator ==(Object other) {
    return other is PlayingCard && other.suit == suit && other.value == value;
  }

  Map<String, dynamic> toJson() => {
        'suit': suit.internalRepresentation,
        'value': value,
      };

  @override
  String toString() {
    return '$suit$value';
  }

  String get label {
    if (value <= 10) {
      return value.toString();
    }
    return switch(value) {
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      14 => 'A',
      _ => ''
    };
  }
}
