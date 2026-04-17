import 'package:firebase_ai/firebase_ai.dart';
import '../models/card.dart';
import '../models/game_session.dart';

class TacticalCoachService {
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-lite-preview',
  );

  Future<String> getMoveSuggestion({
    required List<Card> hand,
    required Lift? currentLift,
    required Suit? trumpSuit,
    required List<Card> playedCards,
  }) async {
    try {
      final handStr = hand.map((c) => c.toString()).join(', ');
      final liftStr = currentLift?.plays.values.map((c) => c.toString()).join(', ') ?? 'No cards played yet';
      final playedStr = playedCards.isEmpty ? 'None' : playedCards.map((c) => c.toString()).join(', ');
      final trumpStr = trumpSuit?.name ?? 'None';

      final prompt = '''
You are a Pedro card game expert.

CONTEXT:
- Trump suit: $trumpStr
- Cards already played in PREVIOUS lifts of this round: $playedStr
- Cards currently ON THE TABLE (the current lift): $liftStr
- Your hand: $handStr

RANK ORDER (Weakest to Strongest):
2, 3, 4, 5, 6, 7, 8, 9, 10, jack, queen, king, ace

POINT CARDS (in Trump Suit):
- 5: worth 5 points
- 9: worth 9 points
- jack: worth 1 point to you, but 3 points to an opponent if they steal it

FORBIDDEN MOVES:
- NEVER recommend playing a 5, 9, or jack of trumps if a HIGHER trump card is already "ON THE TABLE".
- Example: If an Ace of trumps is on the table, playing your 5 of trumps is a guaranteed loss of 5 points. Recommend your lowest legal non-point card instead.

STRATEGIC LOGIC:
1. Is there a card "ON THE TABLE" that beats your best card? If yes, DUCK by playing your lowest legal card.
2. Is your 5, 9, or jack safe? It is only safe if all higher ranks have been played in PREVIOUS lifts OR if you are the last player and you currently hold the highest card on the table.
3. Memory: Use the "PREVIOUS lifts" list to track which high cards are gone.

Suggest the best card to play with a 1-sentence reason.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No suggestion.';
    } catch (e) {
      return 'AI coach is thinking...';
    }
  }
}
