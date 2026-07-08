import { createDeck, shuffle } from './game/deck';
import { evaluateLiftWinner } from './game/logic';
import { Card, Suit } from './game/deck';

function testDeck() {
  console.log('Testing Deck Creation...');
  const deck = createDeck();
  if (deck.length !== 52) throw new Error('Deck should have 52 cards');
  console.log('Deck created successfully.');

  console.log('Testing Shuffle...');
  const deck2 = createDeck();
  shuffle(deck2);
  if (JSON.stringify(deck) === JSON.stringify(deck2)) throw new Error('Shuffle failed to change deck order');
  console.log('Shuffle seems to work.');
}

function testLogic() {
  console.log('Testing Lift Evaluation...');
  const plays: Record<string, Card> = {
    'p1': { suit: 'hearts', rank: 'ace' },
    'p2': { suit: 'hearts', rank: 'five' },
    'p3': { suit: 'spades', rank: 'two' },
    'p4': { suit: 'hearts', rank: 'ten' }
  };
  
  // Case 1: Spades is trump
  const winner1 = evaluateLiftWinner(plays, 'hearts', 'spades');
  if (winner1 !== 'p3') throw new Error('P3 should win with trump spade');

  // Case 2: Hearts is trump, P1 plays Ace
  const winner2 = evaluateLiftWinner(plays, 'hearts', 'hearts');
  if (winner2 !== 'p1') throw new Error('P1 should win with Ace of trump');

  // Case 3: Clubs is trump, Hearts led
  const winner3 = evaluateLiftWinner(plays, 'hearts', 'clubs');
  if (winner3 !== 'p1') throw new Error('P1 should win with Ace of lead suit');

  console.log('Lift evaluation works.');
}

try {
  testDeck();
  testLogic();
  console.log('ALL SERVER LOGIC TESTS PASSED');
} catch (e: any) {
  console.error('TEST FAILED:', e.message);
  process.exit(1);
}
