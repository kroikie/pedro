import 'package:firebase_ai/firebase_ai.dart';
import '../../game/domain/card.dart';
import '../../game/domain/game_session.dart';

class TacticalCoachService {
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-1.5-flash',
  );

  Future<String> getMoveSuggestion({
    required List<Card> hand,
    required Lift? currentLift,
    required Suit? trumpSuit,
  }) async {
    try {
      final handStr = hand.map((c) => c.toString()).join(', ');
      final liftStr = currentLift?.plays.values.map((c) => c.toString()).join(', ') ?? 'No cards played yet';
      final trumpStr = trumpSuit?.name ?? 'None';

      final prompt = 'You are a Pedro card game expert. '
          'Trump suit is $trumpStr. '
          'Cards on table: $liftStr. '
          'Your hand: $handStr. '
          'Suggest the best card to play and a 1-sentence reason. '
          'Remember: Winning a 5 or 9 of trumps is a high priority.';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No suggestion.';
    } catch (e) {
      return 'AI coach is thinking...';
    }
  }
}
