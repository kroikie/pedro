import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/card.dart';
import '../logic/card_sorting.dart';

class BidAssistantService {
  BidAssistantService({
    FirebaseAI? firebaseAI,
  }) : _customFirebaseAI = firebaseAI;

  final FirebaseAI? _customFirebaseAI;

  FirebaseAI get _firebaseAI =>
      _customFirebaseAI ??
      FirebaseAI.googleAI();

  GenerativeModel get _model => _firebaseAI.generativeModel(
        model: 'gemini-3.5-flash-lite',
      );

  Future<String> getBidSuggestion(List<Card> hand) async {
    try {
      final sortedHand = hand.sortedHand();
      final handDescription = sortedHand.map((c) => c.toString()).join(', ');
      final prompt = 'You are a Pedro card game expert. A player has the following hand: $handDescription. '
          'Suggest a bid range (1-20) and give a 1-sentence explanation why. '
          'In Pedro, higher cards and 5, 9, Jack of trumps are valuable.';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No suggestion available.';
    } catch (e, stack) {
      debugPrint('Error generating bid suggestion: $e');
      try {
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'BidAssistantService.getBidSuggestion failed',
          );
        }
      } catch (_) {}
      return 'AI coach is offline.';
    }
  }
}
