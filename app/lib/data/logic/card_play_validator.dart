import '../models/card.dart';
import '../models/game_session.dart';

class MoveValidationResult {
  final bool isLegal;
  final String? reason;

  const MoveValidationResult.legal()
      : isLegal = true,
        reason = null;

  const MoveValidationResult.illegal(this.reason)
      : isLegal = false;
}

MoveValidationResult validateCardPlay({
  required Card card,
  required List<Card> hand,
  required Lift? currentLift,
  required Suit? trumpSuit,
  required RoundPhase phase,
  required bool isMyTurn,
}) {
  if (phase != RoundPhase.playing) {
    return const MoveValidationResult.illegal('Not in playing phase.');
  }

  if (!isMyTurn) {
    return const MoveValidationResult.illegal('Not your turn.');
  }

  final inHand = hand.any((c) => c.suit == card.suit && c.rank == card.rank);
  if (!inHand) {
    return const MoveValidationResult.illegal('Card not in hand.');
  }

  if (currentLift != null && currentLift.plays.isNotEmpty) {
    final leadCard = currentLift.plays[currentLift.leadPlayerId] ??
        (currentLift.plays.isNotEmpty ? currentLift.plays.values.first : null);

    if (leadCard != null) {
      final leadSuit = leadCard.suit;
      if (card.suit != trumpSuit && card.suit != leadSuit) {
        final hasLeadSuit = hand.any((c) => c.suit == leadSuit);
        if (hasLeadSuit) {
          return MoveValidationResult.illegal(
            'Must follow suit (${leadSuit.name}) or play Trump.',
          );
        }
      }
    }
  }

  return const MoveValidationResult.legal();
}

/// Returns the cards played in the [lift] ordered chronologically according to the
/// table seating order in [playerStates], starting with the [Lift.leadPlayerId].
List<MapEntry<String, Card>> getOrderedLiftPlays({
  required Lift lift,
  required List<PlayerGameState> playerStates,
}) {
  if (lift.plays.isEmpty) return const [];

  final leadIndex = playerStates.indexWhere((p) => p.uid == lift.leadPlayerId);
  if (leadIndex != -1) {
    final ordered = <MapEntry<String, Card>>[];
    for (int i = 0; i < playerStates.length; i++) {
      final uid = playerStates[(leadIndex + i) % playerStates.length].uid;
      if (lift.plays.containsKey(uid)) {
        ordered.add(MapEntry(uid, lift.plays[uid]!));
      }
    }
    // Append any extra plays if they weren't in playerStates
    for (final entry in lift.plays.entries) {
      if (!ordered.any((e) => e.key == entry.key)) {
        ordered.add(entry);
      }
    }
    return ordered;
  }

  // Fallback: put lead player first if present
  final entries = lift.plays.entries.toList();
  if (lift.plays.containsKey(lift.leadPlayerId)) {
    final leadEntry =
        MapEntry(lift.leadPlayerId, lift.plays[lift.leadPlayerId]!);
    entries.removeWhere((e) => e.key == lift.leadPlayerId);
    entries.insert(0, leadEntry);
  }
  return entries;
}
