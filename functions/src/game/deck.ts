export const Suits = ['clubs', 'diamonds', 'hearts', 'spades'] as const;
export type Suit = typeof Suits[number];

export const Ranks = ['two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'jack', 'queen', 'king', 'ace'] as const;
export type Rank = typeof Ranks[number];

export interface Card {
  suit: Suit;
  rank: Rank;
}

export function createDeck(): Card[] {
  const deck: Card[] = [];
  for (const suit of Suits) {
    for (const rank of Ranks) {
      deck.push({ suit, rank });
    }
  }
  return deck;
}

export function shuffle<T>(array: T[]): T[] {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}
