enum Suit { clubs, diamonds, hearts, spades }

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

class Card {
  final Suit suit;
  final Rank rank;

  Card({required this.suit, required this.rank});

  Map<String, dynamic> toJson() => {
        'suit': suit.name,
        'rank': rank.name,
      };

  factory Card.fromJson(Map<String, dynamic> json) => Card(
        suit: Suit.values.byName(json['suit'] as String),
        rank: Rank.values.byName(json['rank'] as String),
      );

  @override
  String toString() => '${rank.name} of ${suit.name}';
}

List<Card> createDeck() {
  final deck = <Card>[];
  for (final suit in Suit.values) {
    for (final rank in Rank.values) {
      deck.add(Card(suit: suit, rank: rank));
    }
  }
  return deck;
}

List<T> shuffle<T>(List<T> array) {
  final shuffled = List<T>.from(array);
  shuffled.shuffle();
  return shuffled;
}
