import 'package:flutter/material.dart';
import '../../data/models/game_session.dart';
import '../../data/models/player.dart';
import 'avatar_widget.dart';
import 'game_point_tracker_modal.dart';
import 'point_color_helper.dart';
import 'won_lifts_modal.dart';

/// Modal bottom sheet presenting a player's round points breakdown, contract status,
/// discards, and links to won lifts and game points.
class PlayerRoundDetailsModal extends StatelessWidget {
  const PlayerRoundDetailsModal({
    super.key,
    required this.session,
    required this.targetPlayerId,
    required this.currentPlayerId,
    required this.playerCache,
  });

  final GameSession session;
  final String targetPlayerId;
  final String currentPlayerId;
  final Map<String, Player?> playerCache;

  static Future<void> show({
    required BuildContext context,
    required GameSession session,
    required String targetPlayerId,
    required String currentPlayerId,
    required Map<String, Player?> playerCache,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlayerRoundDetailsModal(
        session: session,
        targetPlayerId: targetPlayerId,
        currentPlayerId: currentPlayerId,
        playerCache: playerCache,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelf = targetPlayerId == currentPlayerId;
    final round = session.currentRound;
    final isRoundFinished = round.phase == RoundPhase.finished;
    final targetPlayer = playerCache[targetPlayerId];
    final targetName = isSelf
        ? 'You'
        : (targetPlayer?.screenName ?? 'Player');

    final playerState = session.playerStates.firstWhere(
      (p) => p.uid == targetPlayerId,
      orElse: () => PlayerGameState(uid: targetPlayerId, hand: []),
    );

    final isBidder = round.bidWinnerId == targetPlayerId &&
        round.phase != RoundPhase.wadger;
    final hasPassedInWadger = round.phase == RoundPhase.wadger &&
        (round.passedPlayerIds.contains(targetPlayerId) ||
            playerState.earnedPoints.contains('Pass'));
    String? wadgerBidLabel;
    if (round.phase == RoundPhase.wadger && !hasPassedInWadger) {
      for (final p in playerState.earnedPoints) {
        if (p.startsWith('Bid:')) {
          wadgerBidLabel = p.toUpperCase();
          break;
        }
      }
      if (wadgerBidLabel == null &&
          round.bidWinnerId == targetPlayerId &&
          round.bidValue > 0) {
        wadgerBidLabel = 'BID: ${round.bidValue}';
      }
    }

    final earnedPoints = playerState.earnedPoints
        .where((p) => p != 'Pass' && !p.startsWith('Bid:'))
        .toList();

    final wonLiftsCount = (isRoundFinished && session.lastRoundSummary != null)
        ? session.lastRoundSummary!.completedLifts
            .where((l) => l.winnerId == targetPlayerId)
            .length
        : round.completedLifts
            .where((l) => l.winnerId == targetPlayerId)
            .length;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    AvatarWidget(
                      avatarUrl: targetPlayer?.avatarUrl,
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  targetName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBidder) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.amber.shade800,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'BIDDER: ${round.bidValue}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ] else if (hasPassedInWadger) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'PASSED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ] else if (wadgerBidLabel != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: round.bidWinnerId == targetPlayerId
                                        ? Colors.amber.shade200
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: round.bidWinnerId == targetPlayerId
                                          ? Colors.amber.shade800
                                          : Colors.orange.shade400,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    wadgerBidLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: round.bidWinnerId == targetPlayerId
                                          ? Colors.amber.shade900
                                          : Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Score: ${playerState.totalScore}  •  Round Points: ${playerState.currentRoundPoints}${isBidder ? ' / ${round.bidValue}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Section 1: Points Captured This Round
                    _buildSectionHeader(
                      context,
                      title: 'Points Captured This Round',
                      icon: Icons.stars_rounded,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(height: 8),
                    if (earnedPoints.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'No points captured yet this round.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: earnedPoints.map((point) {
                          final badgeColors = PointColorHelper.getBadgeColors(point);
                          final desc = PointColorHelper.getPointDescription(point);
                          final val = PointColorHelper.getPointValue(point);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: badgeColors.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: badgeColors.dotColor.withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: badgeColors.dotColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: badgeColors.dotColor
                                            .withValues(alpha: 0.4),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point == '5'
                                            ? '5 of Trump'
                                            : (point == '9'
                                                ? '9 of Trump'
                                                : point),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: badgeColors.textColor,
                                        ),
                                      ),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: badgeColors.textColor
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+$val ${val == 1 ? 'pt' : 'pts'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: badgeColors.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Section 2: Discard & Round Activity
                    _buildSectionHeader(
                      context,
                      title: 'Discards & Activity',
                      icon: Icons.swap_horiz_rounded,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.recycling,
                              size: 18, color: Colors.purple.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              playerState.cardsDiscarded != null
                                  ? '$targetName discarded and replaced ${playerState.cardsDiscarded} ${playerState.cardsDiscarded == 1 ? 'card' : 'cards'}'
                                  : 'No cards replaced during wadger phase',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Section 3: Won Lifts & Game Points Shortcuts
                    _buildSectionHeader(
                      context,
                      title: 'Tricks & Game Points',
                      icon: Icons.layers_rounded,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.of(context).pop();
                              WonLiftsModal.show(
                                context: context,
                                session: session,
                                targetPlayerId: targetPlayerId,
                                currentPlayerId: currentPlayerId,
                                playerCache: playerCache,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.layers,
                                          size: 16, color: Colors.blue.shade800),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Won Lifts',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$wonLiftsCount ${wonLiftsCount == 1 ? 'lift' : 'lifts'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to view tricks',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.of(context).pop();
                              GamePointTrackerModal.show(
                                context: context,
                                session: session,
                                currentPlayerId: currentPlayerId,
                                playerCache: playerCache,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: round.gamePointLeaderId == targetPlayerId
                                    ? Colors.amber.shade100
                                    : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: round.gamePointLeaderId == targetPlayerId
                                      ? Colors.amber.shade600
                                      : Colors.amber.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (round.gamePointLeaderId ==
                                          targetPlayerId) ...[
                                        const Text('👑',
                                            style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                      ] else ...[
                                        Icon(Icons.military_tech_rounded,
                                            size: 16,
                                            color: Colors.amber.shade800),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        'Game Value',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${playerState.gameValue} pts',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to view tracker',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
