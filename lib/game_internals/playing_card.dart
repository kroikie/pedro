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
    final suiteValue = num % 13 == 0 ? num / 13 : num / 13 + 1;
    CardSuit suite = switch (suiteValue) {
      1 => CardSuit.spades,
      2 => CardSuit.clubs,
      3 => CardSuit.hearts,
      4 => CardSuit.diamonds,
      _ => CardSuit.spades
    };
    final value = num % 13 != 0 ? num % 13 : 13;
    return PlayingCard(suite, value);
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
}
