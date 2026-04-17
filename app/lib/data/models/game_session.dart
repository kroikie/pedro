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

  const PlayerGameState({
    required this.uid,
    required this.hand,
    this.currentRoundPoints = 0,
    this.totalScore = 0,
    this.earnedPoints = const [],
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
    required this.plays,
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
  final List<Card> discardedCards;
  final List<Card> playedCards;
  final int turnIndex;

  const RoundState({
    required this.dealerId,
    this.bidWinnerId,
    this.bidValue = 0,
    this.trumpSuit,
    this.phase = RoundPhase.wadger,
    this.currentLift,
    this.discardedCards = const [],
    this.playedCards = const [],
    this.turnIndex = 0,
  });

  static const fromMap = RoundStateMapper.fromMap;
}

@MappableClass()
class GameSession with GameSessionMappable {
  final String gameId;
  final int targetScore;
  final List<PlayerGameState> playerStates;
  final RoundState currentRound;

  const GameSession({
    required this.gameId,
    this.targetScore = 35,
    required this.playerStates,
    required this.currentRound,
  });

  static const fromMap = GameSessionMapper.fromMap;
}
