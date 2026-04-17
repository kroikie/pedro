import 'package:firebase_ai/firebase_ai.dart';
import '../../game/domain/card.dart';

class BidAssistantService {
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-1.5-flash',
  );

  Future<String> getBidSuggestion(List<Card> hand) async {
    try {
      final handDescription = hand.map((c) => c.toString()).join(', ');
      final prompt = 'You are a Pedro card game expert. A player has the following hand: $handDescription. '
          'Suggest a bid range (1-14) and give a 1-sentence explanation why. '
          'In Pedro, higher cards and 5, 9, Jack of trumps are valuable.';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No suggestion available.';
    } catch (e) {
      return 'AI coach is offline.';
    }
  }
}
