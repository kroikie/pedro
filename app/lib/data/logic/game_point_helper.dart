import '../models/card.dart';

const cardGameValues = <Rank, int>{
  Rank.ten: 10,
  Rank.ace: 4,
  Rank.king: 3,
  Rank.queen: 2,
  Rank.jack: 1,
};

/// Returns the game value for a card in Pedro (10=10, Ace=4, King=3, Queen=2, Jack=1).
int getCardGameValue(Card card) {
  return cardGameValues[card.rank] ?? 0;
}

/// Calculates the combined game points from a collection of cards.
int calculateGameTotal(Iterable<Card> cards) {
  int total = 0;
  for (final card in cards) {
    total += getCardGameValue(card);
  }
  return total;
}
