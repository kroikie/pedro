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

class HighLowEvaluationResult {
  final bool highChanged;
  final String? oldHighPlayerId;
  final String? newHighPlayerId;
  final Card? newHighCard;
  final bool isHighSafe;

  final bool lowChanged;
  final String? oldLowPlayerId;
  final String? newLowPlayerId;
  final Card? newLowCard;
  final bool isLowSafe;

  const HighLowEvaluationResult({
    this.highChanged = false,
    this.oldHighPlayerId,
    this.newHighPlayerId,
    this.newHighCard,
    this.isHighSafe = false,
    this.lowChanged = false,
    this.oldLowPlayerId,
    this.newLowPlayerId,
    this.newLowCard,
    this.isLowSafe = false,
  });
}

HighLowEvaluationResult evaluateHighLowTrump({
  required Card playedCard,
  required Suit trumpSuit,
  required String playerId,
  required Card? currentHighCard,
  required String? currentHighPlayerId,
  required Card? currentLowCard,
  required String? currentLowPlayerId,
}) {
  if (playedCard.suit != trumpSuit) {
    return const HighLowEvaluationResult();
  }

  bool highChanged = false;
  String? oldHighPlayerId;
  String? newHighPlayerId;
  Card? newHighCard;
  bool isHighSafe = false;

  if (currentHighCard == null) {
    highChanged = true;
    oldHighPlayerId = null;
    newHighPlayerId = playerId;
    newHighCard = playedCard;
    isHighSafe = playedCard.rank == Rank.ace;
  } else if (rankValues[playedCard.rank]! > rankValues[currentHighCard.rank]!) {
    highChanged = true;
    oldHighPlayerId = currentHighPlayerId;
    newHighPlayerId = playerId;
    newHighCard = playedCard;
    isHighSafe = playedCard.rank == Rank.ace;
  }

  bool lowChanged = false;
  String? oldLowPlayerId;
  String? newLowPlayerId;
  Card? newLowCard;
  bool isLowSafe = false;

  if (currentLowCard == null) {
    lowChanged = true;
    oldLowPlayerId = null;
    newLowPlayerId = playerId;
    newLowCard = playedCard;
    isLowSafe = playedCard.rank == Rank.two;
  } else if (rankValues[playedCard.rank]! < rankValues[currentLowCard.rank]!) {
    lowChanged = true;
    oldLowPlayerId = currentLowPlayerId;
    newLowPlayerId = playerId;
    newLowCard = playedCard;
    isLowSafe = playedCard.rank == Rank.two;
  }

  return HighLowEvaluationResult(
    highChanged: highChanged,
    oldHighPlayerId: oldHighPlayerId,
    newHighPlayerId: newHighPlayerId,
    newHighCard: newHighCard,
    isHighSafe: isHighSafe,
    lowChanged: lowChanged,
    oldLowPlayerId: oldLowPlayerId,
    newLowPlayerId: newLowPlayerId,
    newLowCard: newLowCard,
    isLowSafe: isLowSafe,
  );
}

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
