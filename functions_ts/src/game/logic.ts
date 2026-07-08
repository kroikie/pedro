import { Card, Rank, Suit } from './deck';

export const RankValues: Record<Rank, number> = {
  'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7,
  'eight': 8, 'nine': 9, 'ten': 10, 'jack': 11, 'queen': 12,
  'king': 13, 'ace': 14
};

export function evaluateLiftWinner(
  plays: Record<string, Card>,
  leadSuit: Suit,
  trumpSuit: Suit
): string | null {
  let winnerId: string | null = null;
  let bestCard: Card | null = null;

  for (const [uid, card] of Object.entries(plays)) {
    if (!bestCard) {
      bestCard = card;
      winnerId = uid;
      continue;
    }

    const isTrump = card.suit === trumpSuit;
    const bestIsTrump = bestCard.suit === trumpSuit;

    if (isTrump && !bestIsTrump) {
      bestCard = card;
      winnerId = uid;
    } else if (isTrump && bestIsTrump) {
      if (RankValues[card.rank] > RankValues[bestCard.rank]) {
        bestCard = card;
        winnerId = uid;
      }
    } else if (!isTrump && !bestIsTrump) {
      if (card.suit === leadSuit && bestCard.suit !== leadSuit) {
        bestCard = card;
        winnerId = uid;
      } else if (card.suit === leadSuit && bestCard.suit === leadSuit) {
        if (RankValues[card.rank] > RankValues[bestCard.rank]) {
          bestCard = card;
          winnerId = uid;
        }
      }
    }
  }
  return winnerId;
}
