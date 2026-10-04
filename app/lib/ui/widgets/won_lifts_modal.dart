import 'package:flutter/material.dart';
import '../../data/logic/game_point_helper.dart';
import '../../data/models/card.dart' as pedro;
import '../../data/models/game_session.dart';
import '../../data/models/player.dart';
import 'avatar_widget.dart';
import 'card_widget.dart';

class WonLiftsModal extends StatelessWidget {
  const WonLiftsModal({
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
      builder: (ctx) => WonLiftsModal(
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
    final isRoundFinished = session.currentRound.phase == RoundPhase.finished;
    final targetPlayer = playerCache[targetPlayerId];
    final targetName = isSelf
        ? 'Your'
        : (targetPlayer?.screenName != null
            ? "${targetPlayer!.screenName}'s"
            : "Player's");

    final liftsSource = isRoundFinished && session.lastRoundSummary != null
        ? session.lastRoundSummary!.completedLifts
        : session.currentRound.completedLifts;

    final wonLifts = liftsSource
        .where((lift) => lift.winnerId == targetPlayerId)
        .toList();

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
                      radius: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$targetName Won Lifts',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${wonLifts.length} ${wonLifts.length == 1 ? 'lift' : 'lifts'} won this round',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
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

              // Content
              Expanded(
                child: (!isSelf && !isRoundFinished)
                    ? _buildEtiquettePrivacyNotice(context, wonLifts.length)
                    : wonLifts.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: wonLifts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final lift = wonLifts[index];
                              return _buildLiftCard(
                                context,
                                lift: lift,
                                liftNumber: index + 1,
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

  Widget _buildEtiquettePrivacyNotice(BuildContext context, int liftCount) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300, width: 2),
              ),
              child: Icon(
                Icons.visibility_off_outlined,
                size: 48,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Face-Down Etiquette',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '$liftCount won ${liftCount == 1 ? 'lift' : 'lifts'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'In Pedro, opponents\' captured tricks remain face down until round scoring concludes. You can inspect all played cards when this round finishes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No lifts won yet this round.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiftCard(
    BuildContext context, {
    required Lift lift,
    required int liftNumber,
  }) {
    int totalGameValue = 0;
    for (final card in lift.plays.values) {
      totalGameValue += getCardGameValue(card);
    }

    final trumpSuit = session.currentRound.trumpSuit ??
        session.lastRoundSummary?.trumpSuit;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lift #$liftNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                    if (totalGameValue > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.shade400,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '+$totalGameValue Game pts',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${lift.plays.length} cards',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: lift.plays.entries.map((entry) {
                  final playerId = entry.key;
                  final card = entry.value;
                  final player = playerCache[playerId];
                  final isLeader = playerId == lift.leadPlayerId;
                  final gameVal = getCardGameValue(card);
                  final isTrump = trumpSuit != null && card.suit == trumpSuit;

                  String? specialPointLabel;
                  if (isTrump) {
                    if (card.rank == pedro.Rank.five) specialPointLabel = 'Pedro (5)';
                    if (card.rank == pedro.Rank.nine) specialPointLabel = '9 Pts';
                    if (card.rank == pedro.Rank.jack) specialPointLabel = 'Jack';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text(
                          player?.screenName ?? '...',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isLeader)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LEAD',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 11),
                        CardWidget(
                          card: card,
                          width: 48,
                          height: 72,
                        ),
                        const SizedBox(height: 4),
                        if (specialPointLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              specialPointLabel,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          )
                        else if (gameVal > 0)
                          Text(
                            '+$gameVal pts',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          )
                        else
                          const SizedBox(height: 13),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
