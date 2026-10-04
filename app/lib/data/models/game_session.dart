import 'package:dart_mappable/dart_mappable.dart';
import 'card.dart';

part 'game_session.mapper.dart';

@MappableEnum()
enum RoundPhase {
  wadger,
  discarding,
  playing,
  finished
}

@MappableClass()
class PlayerGameState with PlayerGameStateMappable {
  final String uid;
  final List<Card> hand;
  final int currentRoundPoints;
  final int totalScore;
  final List<String> earnedPoints;
  final int? cardsDiscarded;
  final int gameValue;
  final List<Card> capturedValueCards;

  const PlayerGameState({
    required this.uid,
    required this.hand,
    this.currentRoundPoints = 0,
    this.totalScore = 0,
    this.earnedPoints = const [],
    this.cardsDiscarded,
    this.gameValue = 0,
    this.capturedValueCards = const [],
  });

  static const fromMap = PlayerGameStateMapper.fromMap;
}

@MappableClass()
class Lift with LiftMappable {
  final String leadPlayerId;
  final Map<String, Card> plays;
  final String? winnerId;

  const Lift({
    required this.leadPlayerId,
    this.plays = const {},
    this.winnerId,
  });

  static const fromMap = LiftMapper.fromMap;
}

@MappableClass()
class RoundState with RoundStateMappable {
  final String dealerId;
  final String? bidWinnerId;
  final int bidValue;
  final Suit? trumpSuit;
  final RoundPhase phase;
  final Lift? currentLift;
  final Lift? lastLift;
  final List<Lift> completedLifts;
  final List<Card> discardedCards;
  final List<Card> playedCards;
  final List<String> passedPlayerIds;
  final int turnIndex;
  final DateTime? lastCalledAt;
  final String? gamePointLeaderId;
  final int gamePointLeaderValue;
  final String? highTrumpPlayerId;
  final Card? highTrumpPlayedCard;
  final String? lowTrumpPlayerId;
  final Card? lowTrumpPlayedCard;

  const RoundState({
    required this.dealerId,
    this.bidWinnerId,
    this.bidValue = 0,
    this.trumpSuit,
    this.phase = RoundPhase.wadger,
    this.currentLift,
    this.lastLift,
    this.completedLifts = const [],
    this.discardedCards = const [],
    this.playedCards = const [],
    this.passedPlayerIds = const [],
    this.turnIndex = 0,
    this.lastCalledAt,
    this.gamePointLeaderId,
    this.gamePointLeaderValue = 0,
    this.highTrumpPlayerId,
    this.highTrumpPlayedCard,
    this.lowTrumpPlayerId,
    this.lowTrumpPlayedCard,
  });

  static const fromMap = RoundStateMapper.fromMap;
}

@MappableClass()
class PlayerRoundSummary with PlayerRoundSummaryMappable {
  final String uid;
  final int roundPoints;
  final List<String> earnedPoints;
  final int totalScore;
  final int gameValue;
  final List<Card> capturedValueCards;
  final int wonLiftsCount;

  const PlayerRoundSummary({
    required this.uid,
    this.roundPoints = 0,
    this.earnedPoints = const [],
    this.totalScore = 0,
    this.gameValue = 0,
    this.capturedValueCards = const [],
    this.wonLiftsCount = 0,
  });

  static const fromMap = PlayerRoundSummaryMapper.fromMap;
}

@MappableClass()
class RoundSummary with RoundSummaryMappable {
  final int roundNumber;
  final Suit? trumpSuit;
  final String bidWinnerId;
  final int bidValue;
  final bool bidSuccess;
  final String? highTrumpPlayerId;
  final Card? highTrumpPlayedCard;
  final String? lowTrumpPlayerId;
  final Card? lowTrumpPlayedCard;
  final String? gameWinnerId;
  final int gameWinningScore;
  final bool isGameTied;
  final List<PlayerRoundSummary> playerSummaries;
  final List<Lift> completedLifts;

  const RoundSummary({
    this.roundNumber = 1,
    this.trumpSuit,
    required this.bidWinnerId,
    this.bidValue = 0,
    this.bidSuccess = false,
    this.highTrumpPlayerId,
    this.highTrumpPlayedCard,
    this.lowTrumpPlayerId,
    this.lowTrumpPlayedCard,
    this.gameWinnerId,
    this.gameWinningScore = 0,
    this.isGameTied = false,
    this.playerSummaries = const [],
    this.completedLifts = const [],
  });

  static const fromMap = RoundSummaryMapper.fromMap;
}

@MappableClass()
class GameSession with GameSessionMappable {
  final String gameId;
  final String? hostId;
  final String? name;
  final int targetScore;
  final List<PlayerGameState> playerStates;
  final RoundState currentRound;
  final RoundSummary? lastRoundSummary;
  final List<String> viewerIds;
  final Map<String, int> viewerHeartbeats;
  final bool isOpen;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const GameSession({
    required this.gameId,
    this.hostId,
    this.name,
    this.targetScore = 35,
    required this.playerStates,
    required this.currentRound,
    this.lastRoundSummary,
    this.viewerIds = const [],
    this.viewerHeartbeats = const {},
    this.isOpen = false,
    this.updatedAt,
    this.createdAt,
  });

  List<String> get activeViewerIds {
    final now = DateTime.now().millisecondsSinceEpoch;
    return viewerIds.where((uid) {
      final hb = viewerHeartbeats[uid];
      if (hb == null) return true;
      return (now - hb) <= 60000;
    }).toList();
  }

  int get viewerCount => activeViewerIds.length;

  static const fromMap = GameSessionMapper.fromMap;
}
