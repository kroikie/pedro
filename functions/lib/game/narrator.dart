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

String formatBidContext({
  required String playerName,
  required int? bid,
  required int previousBid,
}) {
  if (bid == null) {
    return '$playerName pass. Dey playing it cool (or dey holding ah real bad hand). High bid still on $previousBid.';
  } else if (bid == 20) {
    return 'Jah! $playerName gone ALL IN with 20! Dat is ah brave bid de $playerName, leh we see if dey could back it up!';
  } else if (bid > previousBid + 5) {
    return 'Lardits! $playerName jump de bid from $previousBid straight to $bid! Look pressure on de table!';
  } else {
    return 'Dat is ah brave bid de $playerName! Bid raised to $bid.';
  }
}

Future<void> narrateBid(
  String gameId,
  String playerName,
  int? bid,
  int previousBid,
) async {
  final context = formatBidContext(
    playerName: playerName,
    bid: bid,
    previousBid: previousBid,
  );

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

String formatPointEventContext({
  required String playerName,
  required String pointType,
  required bool isStolen,
  Rank? cardRank,
  bool isSafe = false,
}) {
  if (pointType == 'Jack') {
    return isStolen
        ? 'Oh gosh! $playerName just hang de man Jack! Massive robbery on de table... $playerName does play card for gramoxone!'
        : '$playerName play and save dey own Jack for 1 point. Safe play.';
  } else if (pointType == '5') {
    return '$playerName grab de 5! 5 big points in de bag!';
  } else if (pointType == '9') {
    return 'Lardits! $playerName just snatch de 9! $playerName does play card for gramoxone!';
  } else if (pointType == 'High') {
    if (isSafe || cardRank == Rank.ace) {
      return '$playerName put down de Ace! High safe, nobody could touch dat!';
    }
    final rankName = cardRank != null ? cardRank.name : '';
    return rankName.isNotEmpty
        ? '$playerName holding High with $rankName. High till higher comes!'
        : '$playerName holding High. High till higher comes!';
  } else if (pointType == 'Low') {
    if (isSafe || cardRank == Rank.two) {
      return '$playerName drop de 2! Low safe, nobody could beat dat!';
    }
    final rankName = cardRank != null ? cardRank.name : '';
    return rankName.isNotEmpty
        ? '$playerName drop low with $rankName. Low till lower comes!'
        : '$playerName drop low. Low till lower comes!';
  }
  return '';
}

Future<void> narratePointEvent(
  String gameId,
  String playerName,
  String pointType,
  bool isStolen, {
  Rank? cardRank,
  bool isSafe = false,
}) async {
  final context = formatPointEventContext(
    playerName: playerName,
    pointType: pointType,
    isStolen: isStolen,
    cardRank: cardRank,
    isSafe: isSafe,
  );

  String text = context;
  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty, lively card game narrator for a game of Pedro with an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'Event: $context '
          'Provide a short, 1-sentence witty reaction to this specific card game event. '
          'Key rules: '
          '- ALWAYS include the player\'s name ($playerName) in your comment. NEVER say "A player". '
          '- When a player makes a clutch, fierce, or ruthless play (hanging a Jack, winning a crucial lift, taking the 9, or scoring big points): ALWAYS comment that "Oh gosh! $playerName does play card for gramoxone!" or use "Lardits!" / "Jah!". '
          '- If it is a "Hang Jack" event, treat it as a dramatic robbery on the table. '
          '- For High/Low points, reflect authentic Pedro phrasing: "High till higher comes" or "Low till lower comes" (unless it is Ace or 2, which are permanently safe). '
          '- Omit "trump point" or "trump" suffixes when referring to point cards (e.g. say "holding High", "drop low", "snatch de 9", or "grab de 5", NOT "High trump point", "lowest trump", or "9 ah trump"). '
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
  String playerName,
  Card card,
  bool isSpecial,
) async {
  if (!isSpecial) return;
  String text =
      'Look trump flying! $playerName just drop de ${card.rank.name} ah ${card.suit.name}!';

  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty card game narrator for Pedro speaking in an authentic Trinidad and Tobago (Trini) dialect. '
          '$playerName just played a high-value card: ${card.rank.name} of ${card.suit.name}. '
          'Provide a short, 1-sentence witty reaction in Trini vernacular. '
          'Key rules: '
          '- ALWAYS include the player\'s name ($playerName) in your comment. NEVER say "A player".';
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

List<String> getCallPlayerFallbacks(String callerName, String slowPlayerName) => [
  'Aye $slowPlayerName, yuh could stop eating for 2 seconds to play yuh know! $callerName waiting on yuh!',
  'Lardits $slowPlayerName, yuh gone to buy doubles or what? Play de card nah, $callerName waiting!',
  'Aye $slowPlayerName, yuh fall asleep on de table? Make ah move nah man, $callerName getting impatient!',
  'Look $callerName calling yuh $slowPlayerName! Stop daydreaming and play yuh turn!',
];

Future<String> narrateCallPlayer({
  required String gameId,
  required String callerName,
  required String slowPlayerName,
}) async {
  final fallbacks = getCallPlayerFallbacks(callerName, slowPlayerName);
  String text =
      fallbacks[DateTime.now().millisecondsSinceEpoch % fallbacks.length];

  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty, lively card game narrator for Pedro speaking in an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'Player "$callerName" just nudged/called "$slowPlayerName" because they are taking too long to play their turn. '
          'Generate a short, 1-sentence witty banter tease addressed to $slowPlayerName in natural Trini dialect, '
          'teasing them with a humorous suggestion of why they might be late (e.g. eating doubles or food, falling asleep, daydreaming, taking a lime break) '
          'and telling them $callerName is waiting for them to play. '
          'Keep it lighthearted, cheeky, and strictly 1 sentence.';

      final response = await ai.generate(
        model: googleAI.gemini('gemini-2.5-flash'),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini call player narration error: $e');
    }
  }

  await postCommentary(gameId, text);
  return text;
}
