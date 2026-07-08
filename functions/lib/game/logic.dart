import 'deck.dart';

const rankValues = <Rank, int>{
  Rank.two: 2,
  Rank.three: 3,
  Rank.four: 4,
  Rank.five: 5,
  Rank.six: 6,
  Rank.seven: 7,
  Rank.eight: 8,
  Rank.nine: 9,
  Rank.ten: 10,
  Rank.jack: 11,
  Rank.queen: 12,
  Rank.king: 13,
  Rank.ace: 14,
};

String? evaluateLiftWinner({
  required Map<String, Card> plays,
  required Suit leadSuit,
  required Suit trumpSuit,
}) {
  String? winnerId;
  Card? bestCard;

  for (final entry in plays.entries) {
    final uid = entry.key;
    final card = entry.value;

    if (bestCard == null) {
      bestCard = card;
      winnerId = uid;
      continue;
    }

    final isTrump = card.suit == trumpSuit;
    final bestIsTrump = bestCard.suit == trumpSuit;

    if (isTrump && !bestIsTrump) {
      bestCard = card;
      winnerId = uid;
    } else if (isTrump && bestIsTrump) {
      if (rankValues[card.rank]! > rankValues[bestCard.rank]!) {
        bestCard = card;
        winnerId = uid;
      }
    } else if (!isTrump && !bestIsTrump) {
      if (card.suit == leadSuit && bestCard.suit != leadSuit) {
        bestCard = card;
        winnerId = uid;
      } else if (card.suit == leadSuit && bestCard.suit == leadSuit) {
        if (rankValues[card.rank]! > rankValues[bestCard.rank]!) {
          bestCard = card;
          winnerId = uid;
        }
      }
    }
  }
  return winnerId;
}
