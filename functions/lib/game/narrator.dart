import 'dart:io';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'deck.dart';

String? get _geminiApiKey =>
    Platform.environment['GEMINI_API_KEY'] ??
    Platform.environment['GOOGLE_GENAI_API_KEY'];

Genkit _getAi() {
  final apiKey = _geminiApiKey;
  return Genkit(
    plugins: [
      googleAI(apiKey: apiKey),
    ],
  );
}

Future<void> postCommentary(String gameId, String text) async {
  final firestore = FirebaseApp.initializeApp().firestore();
  await firestore
      .collection('games')
      .doc(gameId)
      .collection('messages')
      .add({
    'senderId': 'ai_narrator',
    'senderName': 'AI Narrator',
    'text': text,
    'timestamp': FieldValue.serverTimestamp,
    'isAi': true,
  });
}

Future<void> narrateWelcome(String gameId, String roomName) async {
  final fallback = 'Welcome to $roomName! Pull up a chair and let\'s deal the cards for Pedro.';
  String text = fallback;

  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      const prompt = 'You are a witty card game narrator for Pedro. '
          'A new game room named "{roomName}" has just been created. '
          'Provide a short, 1-sentence witty welcome message for the players joining this room.';

      final response = await ai.generate(
        model: googleAI.gemini('gemini-2.5-flash'),
        prompt: prompt.replaceAll('{roomName}', roomName),
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini narration error: $e');
    }
  }

  await postCommentary(gameId, text);
}

Future<void> narrateBid(String gameId, String playerName, int? bid, int previousBid) async {
  String context = '';
  if (bid == null) {
    context = "$playerName decided to pass. They're playing it cool (or they have a terrible hand). The current high bid remains at $previousBid.";
  } else if (bid == 20) {
    context = "$playerName just went ALL IN with a bid of 20! Bold move, let's see if they can back it up!";
  } else if (bid > previousBid + 5) {
    context = "$playerName just jumped the bid from $previousBid all the way to $bid! They must be feeling very confident!";
  } else {
    context = "$playerName raised the bid to $bid. A solid, calculated move.";
  }

  String text = context;
  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt = 'You are a witty, slightly sarcastic card game narrator for a game called Pedro. '
          'Event: $context '
          'Provide a short, 1-sentence witty reaction or commentary about this bidding action. '
          'Keep it lighthearted, competitive, and brief.';

      final response = await ai.generate(
        model: googleAI.gemini('gemini-2.5-flash'),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini narration error: $e');
    }
  }

  await postCommentary(gameId, text);
}

Future<void> narratePointEvent(String gameId, String playerName, String pointType, bool isStolen) async {
  String context = '';
  if (pointType == 'Jack') {
    context = isStolen
      ? '$playerName just "Hung the Jack"! They stole it from an opponent for a massive 3-point swing!'
      : '$playerName played and won their own Jack for 1 point. Safe play.';
  } else if (pointType == '5') {
    context = "$playerName just won a lift with the 5 of trumps! That's 5 big points.";
  } else if (pointType == '9') {
    context = '$playerName secured the 9 of trumps! 9 points in one go!';
  } else if (pointType == 'High') {
    context = '$playerName now holds the High trump point.';
  } else if (pointType == 'Low') {
    context = '$playerName just played the lowest trump. They get 1 point even if they lose the lift!';
  }

  String text = context;
  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt = 'You are a witty card game narrator for Pedro. '
          'Event: $context '
          'Provide a short, 1-sentence witty reaction to this specific event. '
          'If it is a "Hang Jack" event, be extra dramatic about the theft.';

      final response = await ai.generate(
        model: googleAI.gemini('gemini-2.5-flash'),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini narration error: $e');
    }
  }

  await postCommentary(gameId, text);
}

Future<void> narratePlay(String gameId, String playerId, Card card, bool isSpecial) async {
  if (!isSpecial) return;
  String text = 'A player just played the ${card.rank.name} of ${card.suit.name}!';

  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt = 'You are a witty card game narrator for Pedro. '
          'A player just played a high-value card: ${card.rank.name} of ${card.suit.name}. '
          'Provide a short, 1-sentence witty reaction.';
      final response = await ai.generate(
        model: googleAI.gemini('gemini-2.5-flash'),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini narration error: $e');
    }
  }

  await postCommentary(gameId, text);
}
