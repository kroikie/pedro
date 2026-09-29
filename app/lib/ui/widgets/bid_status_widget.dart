import 'package:flutter/material.dart';
import '../../data/models/card.dart' as pedro;
import '../../data/models/game_session.dart';

/// Displays the current or winning bid status in the AppBar actions.
///
/// Indicates who is responsible for achieving the bid and tracks their
/// real-time point progress toward fulfilling their contract.
class BidStatusWidget extends StatelessWidget {
  final RoundState round;
  final int targetScore;
  final String? bidWinnerName;
  final int? bidWinnerPoints;
  final bool isLocalBidWinner;

  const BidStatusWidget({
    super.key,
    required this.round,
    required this.targetScore,
    this.bidWinnerName,
    this.bidWinnerPoints,
    this.isLocalBidWinner = false,
  });

  IconData _suitIcon(pedro.Suit suit) {
    switch (suit) {
      case pedro.Suit.clubs:
        return Icons.circle;
      case pedro.Suit.diamonds:
        return Icons.diamond;
      case pedro.Suit.hearts:
        return Icons.favorite;
      case pedro.Suit.spades:
        return Icons.architecture;
    }
  }

  Color _suitColor(pedro.Suit suit) {
    return (suit == pedro.Suit.hearts || suit == pedro.Suit.diamonds)
        ? Colors.red
        : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final isWadger = round.phase == RoundPhase.wadger;
    final hasBid = round.bidValue > 0;
    final currentPoints = bidWinnerPoints ?? 0;
    final isBidMet = !isWadger && hasBid && currentPoints >= round.bidValue;
    final displayName = isLocalBidWinner
        ? 'You'
        : (bidWinnerName != null && bidWinnerName!.isNotEmpty
            ? bidWinnerName!
            : 'Bidder');

    if (isWadger) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasBid ? 'Bid: ${round.bidValue} ($displayName)' : 'Bidding...',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              'Target: $targetScore',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isBidMet
            ? Colors.green.shade50.withValues(alpha: 0.95)
            : Colors.amber.shade50.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBidMet ? Colors.green.shade400 : Colors.amber.shade400,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (round.trumpSuit != null) ...[
            Icon(
              _suitIcon(round.trumpSuit!),
              size: 18,
              color: _suitColor(round.trumpSuit!),
            ),
            const SizedBox(width: 6),
          ],
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bid: ${round.bidValue}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      '($displayName)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLocalBidWinner
                            ? Colors.blue.shade800
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentPoints / ${round.bidValue} pts',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isBidMet ? FontWeight.bold : FontWeight.w500,
                      color: isBidMet
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                  if (isBidMet) ...[
                    const SizedBox(width: 2),
                    Icon(
                      Icons.check_circle,
                      size: 10,
                      color: Colors.green.shade800,
                    ),
                  ],
                  Text(
                    ' • Goal: $targetScore',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
