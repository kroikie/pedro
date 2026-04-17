import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';

class GameNameService {
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-lite-preview',
  );

  Future<String> generateRoomName() async {
    try {
      const prompt = 'Generate a short, playful two-word name for a card game room Example: "sneeky five". Only return the name.';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'unknown_game';
    } catch (e) {
      debugPrint('Error generating room name: $e');
      return 'lucky_player';
    }
  }
}
