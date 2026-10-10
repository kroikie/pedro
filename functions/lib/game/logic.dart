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

/// Validates whether playing [card] from [hand] into an in-progress lift is legal.
///
/// Enforces:
/// 1. Following the [leadSuit] (or playing [trumpSuit]) if the player holds any card of [leadSuit].
/// 2. No Under-Trumping: when [leadSuit] is not [trumpSuit] and a trump card has already been played
///    in [currentPlays], any subsequent trump card must beat the highest trump card currently in [currentPlays],
///    unless the player holds only trump cards in [hand].
///
/// Returns `null` if the move is legal, or a human-readable error message if illegal.
String? validateLiftCardPlay({
  required Card card,
  required List<Card> hand,
  required Map<String, Card> currentPlays,
  required Suit leadSuit,
  required Suit trumpSuit,
}) {
  if (card.suit != trumpSuit && card.suit != leadSuit) {
    final hasLeadSuit = hand.any((c) => c.suit == leadSuit);
    if (hasLeadSuit) {
      return 'Must follow suit (${leadSuit.name}) or play Trump.';
    }
  }

  if (card.suit == trumpSuit && leadSuit != trumpSuit) {
    Card? highestTrump;
    for (final played in currentPlays.values) {
      if (played.suit == trumpSuit) {
        if (highestTrump == null ||
            rankValues[played.rank]! > rankValues[highestTrump.rank]!) {
          highestTrump = played;
        }
      }
    }

    if (highestTrump != null &&
        rankValues[card.rank]! < rankValues[highestTrump.rank]!) {
      final hasNonTrump = hand.any((c) => c.suit != trumpSuit);
      if (hasNonTrump) {
        return 'Cannot under-trump (${highestTrump.rank.name} of ${trumpSuit.name}) while holding non-trump cards.';
      }
    }
  }

  return null;
}

/// Finds the index of the next player in anti-clockwise order who has not passed.
///
/// Throws [StateError] if all players in [playerIds] have passed.
int getNextBidderIndex({
  required List<String> playerIds,
  required int currentTurnIndex,
  required Iterable<String> passedPlayerIds,
}) {
  final passedSet = passedPlayerIds.toSet();
  if (passedSet.length >= playerIds.length) {
    throw StateError('Cannot find next bidder: all players have passed.');
  }

  int nextIndex = (currentTurnIndex + 1) % playerIds.length;
  while (passedSet.contains(playerIds[nextIndex])) {
    nextIndex = (nextIndex + 1) % playerIds.length;
  }
  return nextIndex;
}

/// Checks if bidding is complete.
///
/// Bidding concludes when all players except the high bidder have passed
/// (i.e. at least [totalPlayers] - 1 players have passed and there is a valid bid winner).
bool isBiddingComplete({
  required int totalPlayers,
  required Iterable<String> passedPlayerIds,
  required String? bidWinnerId,
}) {
  if (bidWinnerId == null) return false;
  return passedPlayerIds.toSet().length >= totalPlayers - 1;
}

/// Calculates how many cards in [hand] are non-trump cards given up for replacement.
int calculateDiscardsCount({
  required List<Card> hand,
  required Suit trumpSuit,
}) {
  return hand.where((c) => c.suit != trumpSuit).length;
}

const cardGameValues = <Rank, int>{
  Rank.ten: 10,
  Rank.ace: 4,
  Rank.king: 3,
  Rank.queen: 2,
  Rank.jack: 1,
};

int getCardGameValue(Card card) {
  return cardGameValues[card.rank] ?? 0;
}

int calculateGameTotal(Iterable<Card> cards) {
  int total = 0;
  for (final card in cards) {
    total += getCardGameValue(card);
  }
  return total;
}

class GamePointLeaderResult {
  final String? leaderUid;
  final int highestValue;
  final bool isTied;

  const GamePointLeaderResult({
    this.leaderUid,
    this.highestValue = 0,
    this.isTied = false,
  });
}

GamePointLeaderResult evaluateGamePointLeader(List<Map<String, dynamic>> playerStates) {
  int bestValue = 0;
  String? bestUid;
  bool tied = false;

  for (final ps in playerStates) {
    final val = (ps['gameValue'] as num?)?.toInt() ?? 0;
    if (val > bestValue) {
      bestValue = val;
      bestUid = ps['uid'] as String?;
      tied = false;
    } else if (val == bestValue && val > 0) {
      tied = true;
    }
  }

  return GamePointLeaderResult(
    leaderUid: tied ? null : bestUid,
    highestValue: bestValue,
    isTied: tied,
  );
}

Map<String, dynamic>? evaluateGamePointWinner(List<Map<String, dynamic>> playerStates) {
  int bestValue = 0;
  Map<String, dynamic>? winner;
  bool tied = false;

  for (final ps in playerStates) {
    final val = (ps['gameValue'] as num?)?.toInt() ?? 0;
    if (val > bestValue) {
      bestValue = val;
      winner = ps;
      tied = false;
    } else if (val == bestValue && val > 0) {
      tied = true;
    }
  }

  return tied ? null : winner;
}

/// Major "sure point" trump ranks that can "sleep" in the deck.
const sleepingTrumpRanks = <Rank>[
  Rank.jack,
  Rank.five,
  Rank.nine,
  Rank.ace,
  Rank.two,
];

/// Returns the list of sure-point trump cards (Jack, 5, 9, Ace, 2 of [trumpSuit])
/// that were never played during the round (i.e. remained undealt / "sleeping" in the deck).
List<Card> evaluateSleepingCards({
  required Suit trumpSuit,
  required Iterable<Card> playedCards,
}) {
  final playedSet = playedCards.toSet();
  return [
    for (final rank in sleepingTrumpRanks)
      if (!playedSet.contains(Card(suit: trumpSuit, rank: rank)))
        Card(suit: trumpSuit, rank: rank),
  ];
}


