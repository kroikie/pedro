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
