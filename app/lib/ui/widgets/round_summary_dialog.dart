import 'package:flutter/material.dart';
import '../../data/models/card.dart' as pedro;
import '../../data/models/game_session.dart';
import '../../data/models/player.dart';
import 'avatar_widget.dart';
import 'point_color_helper.dart';

class RoundSummaryDialog extends StatelessWidget {
  const RoundSummaryDialog({
    super.key,
    required this.summary,
    required this.currentPlayerId,
    required this.playerCache,
    required this.onContinue,
  });

  final RoundSummary summary;
  final String currentPlayerId;
  final Map<String, Player?> playerCache;
  final VoidCallback onContinue;

  static Future<void> show({
    required BuildContext context,
    required RoundSummary summary,
    required String currentPlayerId,
    required Map<String, Player?> playerCache,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoundSummaryDialog(
        summary: summary,
        currentPlayerId: currentPlayerId,
        playerCache: playerCache,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bidder = playerCache[summary.bidWinnerId];
    final gameWinner = summary.gameWinnerId != null
        ? playerCache[summary.gameWinnerId]
        : null;
    final highPlayer = summary.highTrumpPlayerId != null
        ? playerCache[summary.highTrumpPlayerId]
        : null;
    final lowPlayer = summary.lowTrumpPlayerId != null
        ? playerCache[summary.lowTrumpPlayerId]
        : null;

    final sortedSummaries = List<PlayerRoundSummary>.from(summary.playerSummaries)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assessment_outlined,
                          color: Colors.amber.shade900,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Round ${summary.roundNumber} Recap',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (summary.trumpSuit != null)
                            Row(
                              children: [
                                Text(
                                  'Trump: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                _suitBadge(summary.trumpSuit!),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Dismiss',
                    onPressed: onContinue,
                  ),
                ],
              ),
              const Divider(height: 20),

              // Scrollable Body
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Contract Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: summary.bidSuccess
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: summary.bidSuccess
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            avatarUrl: bidder?.avatarUrl,
                            radius: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bidder?.screenName != null
                                      ? '${bidder!.screenName}\'s Contract'
                                      : 'Bid Contract',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Bid ${summary.bidValue} • ${summary.bidSuccess ? 'Made contract' : 'Set penalty (-${summary.bidValue})'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: summary.bidSuccess
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: summary.bidSuccess
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              summary.bidSuccess ? 'MADE' : 'SET',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Key Points Overview Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // High
                        if (summary.highTrumpPlayerId != null)
                          _keyPointChip(
                            label: 'High',
                            playerName: highPlayer?.screenName ?? 'Player',
                            card: summary.highTrumpPlayedCard,
                            color: Colors.blue,
                          ),
                        // Low
                        if (summary.lowTrumpPlayerId != null)
                          _keyPointChip(
                            label: 'Low',
                            playerName: lowPlayer?.screenName ?? 'Player',
                            card: summary.lowTrumpPlayedCard,
                            color: Colors.indigo,
                          ),
                        // Game
                        _gamePointChip(
                          isTied: summary.isGameTied,
                          winnerName: gameWinner?.screenName,
                          winningScore: summary.gameWinningScore,
                        ),
                      ],
                    ),
                    if (summary.sleepingCards.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _sleepingCardsBanner(summary.sleepingCards),
                    ],
                    const SizedBox(height: 16),

                    // Player Scoreboard
                    Text(
                      'Player Standings',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...sortedSummaries.map((ps) {
                      final isCurrent = ps.uid == currentPlayerId;
                      final player = playerCache[ps.uid];
                      final isGameWinner = ps.uid == summary.gameWinnerId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.blue.shade50.withValues(alpha: 0.5)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.blue.shade200
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AvatarWidget(
                                  avatarUrl: player?.avatarUrl,
                                  radius: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          player?.screenName ?? '...',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isCurrent
                                                ? Colors.blue.shade900
                                                : null,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '(You)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                      if (isGameWinner) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade200,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'GAME PT',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Round Points & Total Score
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${ps.roundPoints >= 0 ? '+' : ''}${ps.roundPoints} pts',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: ps.roundPoints > 0
                                            ? Colors.green.shade800
                                            : (ps.roundPoints < 0
                                                ? Colors.red.shade800
                                                : Colors.grey.shade700),
                                      ),
                                    ),
                                    Text(
                                      'Total: ${ps.totalScore}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${ps.wonLiftsCount} ${ps.wonLiftsCount == 1 ? 'lift' : 'lifts'} • ${ps.gameValue} card pts',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (ps.earnedPoints.isNotEmpty)
                                  Wrap(
                                    spacing: 3,
                                    children: ps.earnedPoints.map((ep) {
                                      final badgeColors =
                                          PointColorHelper.getBadgeColors(ep);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: badgeColors.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ep,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColors.textColor,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const Divider(height: 20),

              // Bottom Actions
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suitBadge(pedro.Suit suit) {
    Color color;
    String name;
    switch (suit) {
      case pedro.Suit.clubs:
        color = Colors.black;
        name = 'Clubs ♣';
        break;
      case pedro.Suit.diamonds:
        color = Colors.red;
        name = 'Diamonds ♦';
        break;
      case pedro.Suit.hearts:
        color = Colors.red;
        name = 'Hearts ♥';
        break;
      case pedro.Suit.spades:
        color = Colors.black;
        name = 'Spades ♠';
        break;
    }
    return Text(
      name,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _keyPointChip({
    required String label,
    required String playerName,
    required pedro.Card? card,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          Text(
            playerName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (card != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${_rankShort(card.rank)})',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _gamePointChip({
    required bool isTied,
    required String? winnerName,
    required int winningScore,
  }) {
    if (isTied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            Text(
              'Tied ($winningScore pts) • No pt',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👑 ', style: TextStyle(fontSize: 11)),
          Text(
            'Game: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          Text(
            '${winnerName ?? 'Player'} ($winningScore pts)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sleepingCardsBanner(List<pedro.Card> sleepingCards) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 16,
            color: Colors.blueGrey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            'Sleeping Cards: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sleepingCards.map(_sleepingCardBadge).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sleepingCardBadge(pedro.Card card) {
    final pointKey = _sleepingCardPointKey(card.rank);
    final badgeColors = PointColorHelper.getBadgeColors(pointKey);
    final label = '${_sleepingCardLabel(card.rank)} ${_suitSymbol(card.suit)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColors.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColors.dotColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: badgeColors.textColor,
        ),
      ),
    );
  }

  String _sleepingCardPointKey(pedro.Rank rank) {
    switch (rank) {
      case pedro.Rank.jack:
        return 'Jack';
      case pedro.Rank.five:
        return '5';
      case pedro.Rank.nine:
        return '9';
      case pedro.Rank.ace:
        return 'High';
      case pedro.Rank.two:
        return 'Low';
      default:
        return rank.name;
    }
  }

  String _sleepingCardLabel(pedro.Rank rank) {
    switch (rank) {
      case pedro.Rank.jack:
        return 'Jack';
      case pedro.Rank.five:
        return '5';
      case pedro.Rank.nine:
        return '9';
      case pedro.Rank.ace:
        return 'Ace';
      case pedro.Rank.two:
        return '2';
      default:
        return _rankShort(rank);
    }
  }

  String _suitSymbol(pedro.Suit suit) {
    switch (suit) {
      case pedro.Suit.clubs:
        return '♣';
      case pedro.Suit.diamonds:
        return '♦';
      case pedro.Suit.hearts:
        return '♥';
      case pedro.Suit.spades:
        return '♠';
    }
  }

  String _rankShort(pedro.Rank rank) {
    switch (rank) {
      case pedro.Rank.two:
        return '2';
      case pedro.Rank.three:
        return '3';
      case pedro.Rank.four:
        return '4';
      case pedro.Rank.five:
        return '5';
      case pedro.Rank.six:
        return '6';
      case pedro.Rank.seven:
        return '7';
      case pedro.Rank.eight:
        return '8';
      case pedro.Rank.nine:
        return '9';
      case pedro.Rank.ten:
        return '10';
      case pedro.Rank.jack:
        return 'J';
      case pedro.Rank.queen:
        return 'Q';
      case pedro.Rank.king:
        return 'K';
      case pedro.Rank.ace:
        return 'A';
    }
  }
}

