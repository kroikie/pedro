const RankValues = { 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'jack': 11, 'queen': 12, 'king': 13, 'ace': 14 };

function evaluateLiftWinner(plays, leadSuit, trumpSuit) {
  let winnerId = null;
  let bestCard = null;

  for (const [uid, card] of Object.entries(plays)) {
    if (!bestCard) {
      bestCard = card;
      winnerId = uid;
      continue;
    }

    const isTrump = card.suit === trumpSuit;
    const bestIsTrump = bestCard.suit === trumpSuit;

    if (isTrump && !bestIsTrump) {
      bestCard = card; winnerId = uid;
    } else if (isTrump && bestIsTrump) {
      if (RankValues[card.rank] > RankValues[bestCard.rank]) {
        bestCard = card; winnerId = uid;
      }
    } else if (!isTrump && !bestIsTrump) {
      if (card.suit === leadSuit && bestCard.suit !== leadSuit) {
        bestCard = card; winnerId = uid;
      } else if (card.suit === leadSuit && bestCard.suit === leadSuit) {
        if (RankValues[card.rank] > RankValues[bestCard.rank]) {
          bestCard = card; winnerId = uid;
        }
      }
    }
  }
  return winnerId;
}

module.exports = { evaluateLiftWinner };
