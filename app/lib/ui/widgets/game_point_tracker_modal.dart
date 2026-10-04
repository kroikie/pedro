import 'package:flutter/material.dart';
import '../../data/logic/game_point_helper.dart';
import '../../data/models/card.dart' as pedro;
import '../../data/models/game_session.dart';
import '../../data/models/player.dart';
import 'avatar_widget.dart';
import 'card_widget.dart';

class GamePointTrackerModal extends StatelessWidget {
  const GamePointTrackerModal({
    super.key,
    required this.session,
    required this.currentPlayerId,
    required this.playerCache,
  });

  final GameSession session;
  final String currentPlayerId;
  final Map<String, Player?> playerCache;

  static Future<void> show({
    required BuildContext context,
    required GameSession session,
    required String currentPlayerId,
    required Map<String, Player?> playerCache,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GamePointTrackerModal(
        session: session,
        currentPlayerId: currentPlayerId,
        playerCache: playerCache,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final round = session.currentRound;
    final isRoundFinished = round.phase == RoundPhase.finished;

    // Use current round states or last round summary player summaries if available
    final sortedPlayerStates = List<PlayerGameState>.from(session.playerStates)
      ..sort((a, b) => b.gameValue.compareTo(a.gameValue));

    final leaderId = round.gamePointLeaderId;
    final leaderValue = round.gamePointLeaderValue;

    // Calculate total points accounted for (out of 80 total in a standard deck)
    int totalAccountedPoints = 0;
    for (final ps in sortedPlayerStates) {
      totalAccountedPoints += ps.gameValue;
    }
    const int totalDeckPoints = 80;
    final double progress = (totalAccountedPoints / totalDeckPoints).clamp(0.0, 1.0);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: Colors.amber.shade900,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Game Point Race',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '10=10 • A=4 • K=3 • Q=2 • J=1 (80 total in deck)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 11,
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

              // Deck Progress Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Captured: $totalAccountedPoints / $totalDeckPoints pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          leaderId != null
                              ? 'Leader: ${leaderValue} pts'
                              : (leaderValue > 0 ? 'Tied at ${leaderValue} pts' : 'No points yet'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: leaderId != null ? Colors.amber.shade900 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Player Standings List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedPlayerStates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ps = sortedPlayerStates[index];
                    final isSelf = ps.uid == currentPlayerId;
                    final isLeader = ps.uid == leaderId && leaderValue > 0;
                    final isTiedLead = leaderId == null && leaderValue > 0 && ps.gameValue == leaderValue;
                    final player = playerCache[ps.uid];

                    return Card(
                      elevation: isLeader ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isLeader
                              ? Colors.amber.shade600
                              : (isTiedLead ? Colors.orange.shade300 : Colors.grey.shade200),
                          width: isLeader ? 2 : 1,
                        ),
                      ),
                      color: isLeader
                          ? Colors.amber.shade50.withValues(alpha: 0.6)
                          : (isSelf ? Colors.blue.shade50.withValues(alpha: 0.3) : null),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Rank indicator
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isLeader
                                        ? Colors.amber.shade500
                                        : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: isLeader
                                      ? const Text('👑', style: TextStyle(fontSize: 12))
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                AvatarWidget(
                                  avatarUrl: player?.avatarUrl,
                                  radius: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              player?.screenName ?? '...',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isSelf ? Colors.blue.shade900 : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelf) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '(You)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isLeader)
                                        Text(
                                          'Leading Game point',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        )
                                      else if (isTiedLead)
                                        Text(
                                          'Tied for lead (no point if tied)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Score badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLeader
                                        ? Colors.amber.shade200
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isLeader
                                          ? Colors.amber.shade700
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    '${ps.gameValue} pts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isLeader
                                          ? Colors.amber.shade900
                                          : Colors.grey.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Captured Value Cards breakdown
                            if (ps.capturedValueCards.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              if (isSelf || isRoundFinished) ...[
                                Text(
                                  'Captured Value Cards (${ps.capturedValueCards.length}):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: ps.capturedValueCards.map((card) {
                                      final val = getCardGameValue(card);
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Column(
                                          children: [
                                            CardWidget(
                                              card: card,
                                              width: 34,
                                              height: 52,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '+$val',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.style_outlined,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${ps.capturedValueCards.length} value cards captured (face down)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
