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
  return Genkit(plugins: [googleAI(apiKey: apiKey)]);
}

Future<void> postCommentary(String gameId, String text) async {
  final firestore = FirebaseApp.initializeApp().firestore();
  await firestore.collection('games').doc(gameId).collection('messages').add({
    'senderId': 'ai_narrator',
    'senderName': 'AI Narrator',
    'text': text,
    'timestamp': FieldValue.serverTimestamp,
    'isAi': true,
  });
}

Future<void> narrateWelcome(String gameId, String roomName) async {
  final fallback =
      'Welcome to $roomName! Pull up ah chair, lime ah bit, and leh we deal out de cards for Pedro.';
  String text = fallback;

  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      const prompt =
          'You are a witty, lively card game narrator for Pedro speaking with an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'A new game room named "{roomName}" has just been created. '
          'Provide a short, 1-sentence witty welcome message for the players joining this room. '
          'Use natural Trini expressions (e.g., "Pull up ah chair, lime ah bit, and leh we deal out de cards for Pedro").';

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

Future<void> narrateBid(
  String gameId,
  String playerName,
  int? bid,
  int previousBid,
) async {
  String context = '';
  if (bid == null) {
    context =
        "$playerName pass. Dey playing it cool (or dey holding ah real bad hand). High bid still on $previousBid.";
  } else if (bid == 20) {
    context =
        "Jah! $playerName gone ALL IN with 20! Dat is ah brave bid de $playerName, leh we see if dey could back it up!";
  } else if (bid > previousBid + 5) {
    context =
        "Lardits! $playerName jump de bid from $previousBid straight to $bid! Look pressure on de table!";
  } else {
    context = "Dat is ah brave bid de $playerName! Bid raised to $bid.";
  }

  String text = context;
  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty, lively card game narrator for a game of Pedro with an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'Event: $context '
          'Provide a short, 1-sentence witty reaction or commentary about this bidding action. '
          'Key rules: '
          '- ALWAYS include the player\'s name ($playerName) in your comment. '
          '- Use natural Trinidadian expressions and rhythm. '
          '- For tension or high bids, use expressions like "Lardits!", "Jah!", "Look pressure on de table!", or "Dat is ah brave bid de $playerName!". '
          'Keep it lighthearted, competitive, and brief (strictly 1 sentence).';

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

Future<void> narratePointEvent(
  String gameId,
  String playerName,
  String pointType,
  bool isStolen,
) async {
  String context = '';
  if (pointType == 'Jack') {
    context =
        isStolen
            ? 'Oh gosh! $playerName just hang de man Jack! Massive robbery on de table... $playerName does play card for gramoxone!'
            : '$playerName play and save dey own Jack for 1 point. Safe play.';
  } else if (pointType == '5') {
    context = "$playerName grab de 5 ah trumps! 5 big points in de bag!";
  } else if (pointType == '9') {
    context =
        "Lardits! $playerName snatch de 9 ah trumps! $playerName does play card for gramoxone!";
  } else if (pointType == 'High') {
    context = '$playerName holding High trump point.';
  } else if (pointType == 'Low') {
    context =
        '$playerName drop de lowest trump. 1 point safe even if lift lost!';
  }

  String text = context;
  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty, lively card game narrator for a game of Pedro with an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'Event: $context '
          'Provide a short, 1-sentence witty reaction to this specific card game event. '
          'Key rules: '
          '- ALWAYS include the player\'s name ($playerName) in your comment. '
          '- When a player makes a clutch, fierce, or ruthless play (hanging a Jack, winning a crucial lift, taking the 9 of trumps, or scoring big points): ALWAYS comment that "Oh gosh! $playerName does play card for gramoxone!" or use "Lardits!" / "Jah!". '
          '- If it is a "Hang Jack" event, treat it as a dramatic robbery on the table. '
          'Keep it spirited, humorous, and strictly 1 sentence.';

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

Future<void> narratePlay(
  String gameId,
  String playerId,
  Card card,
  bool isSpecial,
) async {
  if (!isSpecial) return;
  String text =
      'Look trump flying! A player just drop de ${card.rank.name} ah ${card.suit.name}!';

  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty card game narrator for Pedro speaking in an authentic Trinidad and Tobago (Trini) dialect. '
          'A player just played a high-value card: ${card.rank.name} of ${card.suit.name}. '
          'Provide a short, 1-sentence witty reaction in Trini vernacular.';
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
