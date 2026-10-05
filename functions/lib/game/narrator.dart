import 'dart:io';
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'deck.dart';

const String narratorModel = 'gemini-3.5-flash-lite';

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
          'Use natural Trini expressions (e.g., "Pull up ah chair, lime ah bit, and leh we deal out de cards for Pedro"). '
          'Keep it warm, spirited, and strictly 1 sentence.';

      final response = await ai.generate(
        model: googleAI.gemini(narratorModel),
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
          'Provide a short, 1-sentence witty reaction or commentary about this high-stakes bidding action. '
          'Key rules: '
          '- ALWAYS include the player\'s name ($playerName) in your comment. '
          '- Use natural Trinidadian expressions and rhythm. '
          '- For tension or high bids, vary your expressions like "Lardits!", "Jah!", "Look pressure on de table!", or "Dat is ah brave bid de $playerName!". '
          '- Do not repeat the same catchphrase consecutively. '
          'Keep it lighthearted, competitive, and brief (strictly 1 sentence).';

      final response = await ai.generate(
        model: googleAI.gemini(narratorModel),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini narration error: $e');
    }
  }

  await postCommentary(gameId, text);
}

String formatBidWonContext({
  required String playerName,
  required int bid,
}) {
  return '$playerName win de bid with $bid! Contract set, leh we see what trump dey calling!';
}

Future<void> narrateBidWon(
  String gameId,
  String playerName,
  int bid,
) async {
  final context = formatBidWonContext(playerName: playerName, bid: bid);
  String text = context;

  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty, lively card game narrator for a game of Pedro with an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'Event: $playerName just won the bidding contract with a bid of $bid. Now they must choose the trump suit. '
          'Provide a short, 1-sentence witty reaction congratulating or hyping up $playerName on winning the contract and wondering what trump they will call. '
          'Key rules: '
          '- ALWAYS include the player\'s name ($playerName) in your comment. '
          '- Use natural Trinidadian cadence and competitive table talk (e.g., "Big talk on de table", "Leh we see what trump yuh calling", "Contract safe or look trouble"). '
          'Keep it spirited and strictly 1 sentence.';

      final response = await ai.generate(
        model: googleAI.gemini(narratorModel),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini bid won narration error: $e');
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
  int? scoreValue,
}) {
  if (pointType == 'Jack') {
    return isStolen
        ? 'Oh gosh! $playerName just hang de man Jack! Daylight robbery on de table!'
        : '$playerName play and save dey own Jack for 1 point. Safe play.';
  } else if (pointType == '5') {
    return '$playerName grab de 5! 5 big points in de bag!';
  } else if (pointType == '9') {
    return 'Lardits! $playerName just snatch de 9! 9 big points in de bag!';
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
  } else if (pointType == 'Game') {
    if (isStolen) {
      return 'Game point tied! Nobody get de Game point dis round!';
    }
    final scoreStr = scoreValue != null ? ' with $scoreValue card points' : '';
    return '$playerName win de Game point$scoreStr! Look value in de bag!';
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
  int? scoreValue,
}) async {
  final context = formatPointEventContext(
    playerName: playerName,
    pointType: pointType,
    isStolen: isStolen,
    cardRank: cardRank,
    isSafe: isSafe,
    scoreValue: scoreValue,
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
          '- When a player makes a clutch, fierce, or ruthless play (hanging a Jack, snatching the 9, or securing big points): react with high intensity using authentic Trini expressions. Saying "$playerName does play card for gramoxone!" is classic for ruthless or lethal play, but do NOT use it every time—vary your commentary across other fierce expressions like "Daylight robbery on de table!", "Cold-blooded robbery! De man Jack dead!", "Pressure in de savannah!", "Watch craft! De card talking!", or "Look pressure on de table!". '
          '- If it is a "Hang Jack" event, treat it as a dramatic robbery on the table. '
          '- For High/Low points, reflect authentic Pedro phrasing: "High till higher comes" or "Low till lower comes" (unless it is Ace or 2, which are permanently safe). '
          '- Omit "trump point" or "trump" suffixes when referring to point cards (e.g. say "holding High", "drop low", "snatch de 9", or "grab de 5", NOT "High trump point", "lowest trump", or "9 ah trump"). '
          '- Do not repeat the same catchphrase consecutively. '
          'Keep it spirited, humorous, and strictly 1 sentence.';

      final response = await ai.generate(
        model: googleAI.gemini(narratorModel),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini narration error: $e');
    }
  }

  await postCommentary(gameId, text);
}

String formatLiftResolutionContext({
  required String winnerName,
  bool stoleJack = false,
  bool savedJack = false,
  bool wonNine = false,
  bool wonFive = false,
  int cardPoints = 0,
}) {
  if (stoleJack) {
    if (wonNine && wonFive) {
      return 'Oh gosh! $winnerName hang de man Jack AND scoop de 9 and 5! Monster robbery on de table!';
    } else if (wonNine) {
      return 'Oh gosh! $winnerName hang de man Jack and snatch de 9! Daylight robbery on de table!';
    } else if (wonFive) {
      return 'Oh gosh! $winnerName hang de man Jack and take de 5! Massive robbery on de table!';
    }
    return 'Oh gosh! $winnerName just hang de man Jack! Daylight robbery on de table!';
  }
  if (wonNine && wonFive) {
    return 'Lardits! $winnerName scoop both de 9 and de 5! 14 big points in one sweep!';
  }
  if (wonNine) {
    return 'Lardits! $winnerName snatch de 9! 9 big points in de bag!';
  }
  if (wonFive) {
    return '$winnerName grab de 5! 5 big points in de bag!';
  }
  if (savedJack) {
    return '$winnerName play and save dey own Jack for 1 point. Safe play.';
  }
  return '';
}

Future<void> narrateLiftResolution({
  required String gameId,
  required String winnerName,
  bool stoleJack = false,
  bool savedJack = false,
  bool wonNine = false,
  bool wonFive = false,
  int cardPoints = 0,
}) async {
  final context = formatLiftResolutionContext(
    winnerName: winnerName,
    stoleJack: stoleJack,
    savedJack: savedJack,
    wonNine: wonNine,
    wonFive: wonFive,
    cardPoints: cardPoints,
  );

  if (context.isEmpty) return;

  String text = context;
  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty, lively card game narrator for a game of Pedro with an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'Event: $context '
          'Provide a single, short 1-sentence witty reaction summarizing this lift outcome. '
          'Key rules: '
          '- ALWAYS include the winner\'s name ($winnerName). '
          '- If an opponent\'s Jack was stolen (Hang Jack), treat it as an exhilarating, cold-blooded heist. Express high intensity with varied Trini picong—sayings like "$winnerName does play card for gramoxone!" are classic for lethal play, but also vary with "Daylight robbery on de table!", "De man Jack dead!", "Pressure in de savannah!", or "Cold-blooded robbery!". '
          '- If Pedro cards (9 or 5) were won, celebrate the point haul. '
          '- Only 1 sentence total. Never produce multiple messages or repeat the exact same catchphrase consecutively.';

      final response = await ai.generate(
        model: googleAI.gemini(narratorModel),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini lift narration error: $e');
    }
  }

  await postCommentary(gameId, text);
}

String formatRoundEndContext({
  required String bidWinnerName,
  required int bidValue,
  required int pointsWon,
  required bool bidSuccess,
  String? gamePointWinnerName,
  int? gamePointScore,
  bool isGameTied = false,
  String? matchWinnerName,
}) {
  if (matchWinnerName != null && matchWinnerName.isNotEmpty) {
    return 'Game over! $matchWinnerName reach de target score and take de crown! Total champion on de table!';
  }

  final contractResult = bidSuccess
      ? '$bidWinnerName make de $bidValue bid with $pointsWon points! Safe home!'
      : 'Lardits! $bidWinnerName get set! Bid $bidValue but only take $pointsWon points... minus $bidValue on dey head!';

  if (isGameTied) {
    return '$contractResult Game point tied dis round!';
  } else if (gamePointWinnerName != null && gamePointWinnerName.isNotEmpty) {
    final scoreStr = gamePointScore != null ? ' with $gamePointScore card points' : '';
    return '$contractResult And $gamePointWinnerName take de Game point$scoreStr!';
  }
  return contractResult;
}

Future<void> narrateRoundEnd({
  required String gameId,
  required String bidWinnerName,
  required int bidValue,
  required int pointsWon,
  required bool bidSuccess,
  String? gamePointWinnerName,
  int? gamePointScore,
  bool isGameTied = false,
  String? matchWinnerName,
}) async {
  final context = formatRoundEndContext(
    bidWinnerName: bidWinnerName,
    bidValue: bidValue,
    pointsWon: pointsWon,
    bidSuccess: bidSuccess,
    gamePointWinnerName: gamePointWinnerName,
    gamePointScore: gamePointScore,
    isGameTied: isGameTied,
    matchWinnerName: matchWinnerName,
  );

  String text = context;
  if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
    try {
      final ai = _getAi();
      final prompt =
          'You are a witty, lively card game narrator for Pedro speaking in an authentic Trinidad and Tobago (Trini) dialect, accent, and cadence. '
          'Round Outcome: $context '
          'Provide a short, 1-sentence witty reaction celebrating the round climax. '
          'Key rules: '
          '- If someone won the overall match, crown them with highest praise. '
          '- If the bidder got set (failed their contract), roast them with authentic Trini card-table picong (e.g., "De bid bite yuh!", "Who vex lose!", "Minus points on yuh head!"). '
          '- If the bidder made their bid, commend their bravery and card skill. '
          '- Strictly 1 sentence, spirited and concise.';

      final response = await ai.generate(
        model: googleAI.gemini(narratorModel),
        prompt: prompt,
      );
      text = response.text.trim();
    } catch (e) {
      print('Gemini round end narration error: $e');
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
        model: googleAI.gemini(narratorModel),
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
  'Aye $slowPlayerName, yuh studying de cards or writing ah CXC exam? $callerName waiting on yuh!',
  'Aye $slowPlayerName, yuh could stop eating for 2 seconds to play yuh know! $callerName waiting on yuh!',
  'Lardits $slowPlayerName, yuh gone to boil tea or what? Play de card nah, $callerName waiting!',
  'Aye $slowPlayerName, yuh fall asleep on de table? Make ah move nah man, $callerName getting impatient!',
  'Look $callerName calling yuh $slowPlayerName! Stop daydreaming and play yuh turn!',
  'Aye $slowPlayerName, yuh watching de cards like dey go play theyself? Throw ah card nah, $callerName waiting!',
  'Woi $slowPlayerName, lime over! Play yuh hand nah man, $callerName waiting!',
  'Lardits $slowPlayerName, yuh holding council with de cards? Make ah move, $callerName waiting!',
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
          'teasing them with a humorous suggestion of why they might be late (e.g. studying cards like a CXC exam, gone to boil tea, holding council with the cards, waiting for Christmas, counting money, falling asleep, daydreaming, or taking a lime break) '
          'and telling them $callerName is waiting for them to play. '
          'Treat cultural food references like doubles as occasional spice rather than every message. '
          'Keep it lighthearted, cheeky, and strictly 1 sentence.';

      final response = await ai.generate(
        model: googleAI.gemini(narratorModel),
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
