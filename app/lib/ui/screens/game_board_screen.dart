import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/game_session.dart';
import '../../data/models/card.dart' as pedro;
import '../widgets/card_widget.dart';
import '../../data/models/player.dart';
import '../../data/repositories/player_repository.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/chat_overlay.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/floating_reactions_overlay.dart';
import '../widgets/bid_status_widget.dart';
import '../../data/services/bid_assistant_service.dart';
import '../../data/services/tactical_coach_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/logic/card_play_validator.dart';
import '../../data/logic/card_sorting.dart';
import '../../data/repositories/reaction_repository.dart';
import '../../data/repositories/chat_repository.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({
    super.key,
    required this.gameId,
    this.gameName,
    this.gameRepository,
    this.playerRepository,
    this.reactionRepository,
    this.chatRepository,
    this.bidAssistantService,
    this.tacticalCoachService,
    this.currentUserId,
  });
  final String gameId;
  final String? gameName;
  final GameRepository? gameRepository;
  final PlayerRepository? playerRepository;
  final ReactionRepository? reactionRepository;
  final ChatRepository? chatRepository;
  final BidAssistantService? bidAssistantService;
  final TacticalCoachService? tacticalCoachService;
  final String? currentUserId;

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  late final GameRepository _gameRepo = widget.gameRepository ?? GameRepository();
  late final PlayerRepository _playerRepo = widget.playerRepository ?? PlayerRepository();
  late final String? _uid = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

  final Map<String, Player> _playerCache = {};
  final Map<String, Future<Player?>> _playerFutureCache = {};

  Future<Player?> _getPlayer(String uid) {
    return _playerFutureCache.putIfAbsent(uid, () async {
      final player = await _playerRepo.getPlayer(uid);
      if (player != null && mounted) {
        _playerCache[uid] = player;
      }
      return player;
    });
  }

  String? _bidSuggestion;
  bool _isAnalyzingHand = false;

  String? _moveSuggestion;
  bool _isAnalyzingMove = false;
  bool _isSubmittingCard = false;
  pedro.Card? _submittedCard;
  DateTime? _lastCardSubmitTime;
  Timer? _cardSubmissionSafetyTimer;

  String? _lastObservedWinnerId;
  bool _isReviewCooldownActive = false;
  Timer? _reviewCooldownTimer;

  late Stream<GameSession?> _gameSessionStream;

  @override
  void initState() {
    super.initState();
    _gameSessionStream = _gameRepo.watchGameSession(widget.gameId);
    NotificationService.instance.setActiveGame(widget.gameId);
  }

  @override
  void didUpdateWidget(covariant GameBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId ||
        oldWidget.gameRepository != widget.gameRepository) {
      _gameSessionStream = _gameRepo.watchGameSession(widget.gameId);
    }
  }

  @override
  void dispose() {
    NotificationService.instance.setActiveGame(null);
    _reviewCooldownTimer?.cancel();
    _cardSubmissionSafetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmDeleteGame(BuildContext context, GameSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text(
          'Are you sure you want to delete "${session.name ?? 'this game'}"? This action cannot be undone and will end the game for all players.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _gameRepo.deleteGame(session.gameId);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Game "${session.name ?? 'Pedro'}" deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete game: $e')),
          );
        }
      }
    }
  }

  void _checkLiftCompletion(Lift? lift) {
    if (lift?.winnerId != null) {
      if (_lastObservedWinnerId != lift!.winnerId) {
        _lastObservedWinnerId = lift.winnerId;
        _isReviewCooldownActive = true;
        _reviewCooldownTimer?.cancel();
        _reviewCooldownTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() => _isReviewCooldownActive = false);
          }
        });
      }
    } else {
      if (_lastObservedWinnerId != null) {
        _lastObservedWinnerId = null;
        _isReviewCooldownActive = false;
        _reviewCooldownTimer?.cancel();
      }
    }
  }

  void _checkSubmissionCompletion(GameSession session) {
    if (_submittedCard != null) {
      final round = session.currentRound;
      final localIndex = session.playerStates.indexWhere((p) => p.uid == _uid);
      if (localIndex == -1) return;
      final localState = session.playerStates[localIndex];
      final isMyTurn = round.turnIndex == localIndex;
      final cardStillInHand = localState.hand.any(
        (c) => c.suit == _submittedCard!.suit && c.rank == _submittedCard!.rank,
      );
      if (!cardStillInHand || !isMyTurn) {
        _submittedCard = null;
        _isSubmittingCard = false;
        _cardSubmissionSafetyTimer?.cancel();
      }
    }
  }

  Future<void> _analyzeHand(List<pedro.Card> hand) async {
    if (_bidSuggestion != null || _isAnalyzingHand) return;
    setState(() => _isAnalyzingHand = true);
    try {
      final assistant = widget.bidAssistantService ?? BidAssistantService();
      final suggestion = await assistant.getBidSuggestion(hand);
      if (mounted) {
        setState(() {
          _bidSuggestion = suggestion;
          _isAnalyzingHand = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAnalyzingHand = false);
      }
    }
  }

  Future<void> _analyzeMove(List<pedro.Card> hand, Lift? lift,
      pedro.Suit? trump, List<pedro.Card> playedCards) async {
    setState(() => _isAnalyzingMove = true);
    try {
      final coach = widget.tacticalCoachService ?? TacticalCoachService();
      final suggestion = await coach.getMoveSuggestion(
        hand: hand,
        currentLift: lift,
        trumpSuit: trump,
        playedCards: playedCards,
      );
      if (mounted) {
        setState(() {
          _moveSuggestion = suggestion;
          _isAnalyzingMove = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAnalyzingMove = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameSession?>(
      stream: _gameSessionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data;
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.gameName ?? 'Pedro')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('This game has ended or was deleted.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Home'),
                  ),
                ],
              ),
            ),
          );
        }
        _checkLiftCompletion(session.currentRound.currentLift);
        _checkSubmissionCompletion(session);

        final isHost = session.hostId != null && session.hostId == _uid;
        final gameTitle =
            (session.name != null && session.name!.trim().isNotEmpty)
                ? session.name!
                : (widget.gameName != null && widget.gameName!.trim().isNotEmpty)
                    ? widget.gameName!
                    : 'Pedro';

        final mediaQuery = MediaQuery.of(context);
        final viewInsetsBottom = mediaQuery.viewInsets.bottom;
        final availableHeight = mediaQuery.size.height -
            viewInsetsBottom -
            mediaQuery.padding.vertical -
            kToolbarHeight;
        final shouldHideInteractionArea =
            viewInsetsBottom > 0 && availableHeight < 560;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              gameTitle,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              Builder(builder: (context) {
                final round = session.currentRound;
                final bidWinnerId = round.bidWinnerId;
                final isLocalBidWinner =
                    bidWinnerId != null && bidWinnerId == _uid;
                final bidWinnerState = bidWinnerId != null
                    ? session.playerStates
                        .where((p) => p.uid == bidWinnerId)
                        .firstOrNull
                    : null;
                final bidWinnerPoints = bidWinnerState?.currentRoundPoints;

                if (bidWinnerId != null && !isLocalBidWinner) {
                  return FutureBuilder<Player?>(
                    future: _getPlayer(bidWinnerId),
                    initialData: _playerCache[bidWinnerId],
                    builder: (context, snap) {
                      return BidStatusWidget(
                        round: round,
                        targetScore: session.targetScore,
                        bidWinnerName: snap.data?.screenName,
                        bidWinnerPoints: bidWinnerPoints,
                        isLocalBidWinner: false,
                      );
                    },
                  );
                }

                return BidStatusWidget(
                  round: round,
                  targetScore: session.targetScore,
                  bidWinnerName: isLocalBidWinner ? 'You' : null,
                  bidWinnerPoints: bidWinnerPoints,
                  isLocalBidWinner: isLocalBidWinner,
                );
              }),
              if (isHost)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Game options',
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeleteGame(context, session);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Delete Game',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 12),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final boardWidth = constraints.maxWidth;
                          final numPlayers = session.playerStates.length;
                          final maxCenterWidth = (boardWidth * (numPlayers >= 7 ? 0.64 : 0.60))
                              .clamp(190.0, 260.0);
                          return Align(
                            alignment: const Alignment(0, 0.06),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxCenterWidth),
                              child: _buildLiftArea(
                                session.currentRound.currentLift,
                                session.playerStates,
                                lastLift: session.currentRound.lastLift,
                              ),
                            ),
                          );
                        },
                      ),
                      ..._buildPlayerPositions(session),
                      FloatingReactionsOverlay(
                        gameId: widget.gameId,
                        reactionRepository: widget.reactionRepository,
                      ),
                    ],
                  ),
                ),
                if (!shouldHideInteractionArea) _buildInteractionArea(session),
                ChatOverlay(
                  gameId: widget.gameId,
                  chatRepository: widget.chatRepository,
                  playerRepository: _playerRepo,
                  currentUserId: _uid,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiftArea(
    Lift? lift,
    List<PlayerGameState> states, {
    Lift? lastLift,
  }) {
    if (lift == null || lift.plays.isEmpty) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Waiting for plays...',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (lastLift != null && lastLift.plays.isNotEmpty) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _showPreviousLiftModal(context, lastLift, states),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 12, color: Colors.blueGrey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'View Previous Trick',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final orderedPlays = getOrderedLiftPlays(lift: lift, playerStates: states);
    final leadCard = lift.plays[lift.leadPlayerId] ?? orderedPlays.first.value;
    final leadSuit = leadCard.suit;
    final isLiftComplete = lift.winnerId != null;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLiftComplete
            ? Colors.amber.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLiftComplete ? Colors.amber.shade300 : Colors.grey.shade200,
          width: isLiftComplete ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLiftComplete)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  'Lift Won by ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                FutureBuilder<Player?>(
                  future: _getPlayer(lift.winnerId!),
                  initialData: _playerCache[lift.winnerId!],
                  builder: (context, snap) => Text(
                    snap.data?.screenName ?? '...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lead: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Icon(_suitIcon(leadSuit), size: 13, color: _suitColor(leadSuit)),
                const SizedBox(width: 3),
                Text(
                  leadSuit.name[0].toUpperCase() + leadSuit.name.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _suitColor(leadSuit),
                  ),
                ),
                if (lastLift != null && lastLift.plays.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showPreviousLiftModal(context, lastLift, states),
                    child: Icon(Icons.history, size: 14, color: Colors.blueGrey.shade400),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 6),
          _buildTrickCardsGrid(
            orderedPlays: orderedPlays,
            totalPlayers: states.length,
            leadPlayerId: lift.leadPlayerId,
            winnerId: lift.winnerId,
          ),
          if (isLiftComplete) ...[
            const SizedBox(height: 6),
            if (_isReviewCooldownActive)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reviewing lift...',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              )
            else
              FutureBuilder<Player?>(
                future: _getPlayer(lift.winnerId!),
                initialData: _playerCache[lift.winnerId!],
                builder: (context, snap) {
                  final winnerName = snap.data?.screenName ?? 'Winner';
                  final isLocalWinner = lift.winnerId == _uid;
                  final text = isLocalWinner
                      ? 'You won the lift! Play a card to lead next.'
                      : '$winnerName won the lift and leads next.';
                  return Text(
                    text,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isLocalWinner ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  );
                },
              ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildTrickCardsGrid({
    required List<MapEntry<String, pedro.Card>> orderedPlays,
    required int totalPlayers,
    required String? leadPlayerId,
    required String? winnerId,
  }) {
    if (orderedPlays.isEmpty) {
      return const SizedBox.shrink();
    }

    final int cardsPerRow = totalPlayers <= 4
        ? 4
        : (totalPlayers <= 6 ? 3 : 4);
    final double cardWidth = totalPlayers <= 4
        ? 52.0
        : (totalPlayers <= 6 ? 46.0 : 40.0);
    final double cardHeight = totalPlayers <= 4
        ? 78.0
        : (totalPlayers <= 6 ? 69.0 : 60.0);
    final double cardSpacing = totalPlayers <= 4
        ? 4.0
        : (totalPlayers <= 6 ? 3.0 : 2.5);
    final double nameMaxWidth = totalPlayers <= 4
        ? 60.0
        : (totalPlayers <= 6 ? 52.0 : 44.0);
    final double nameFontSize = totalPlayers <= 4
        ? 10.0
        : (totalPlayers <= 6 ? 9.5 : 9.0);

    final List<List<MapEntry<String, pedro.Card>>> rows = [];
    for (int i = 0; i < orderedPlays.length; i += cardsPerRow) {
      rows.add(orderedPlays.sublist(
        i,
        (i + cardsPerRow).clamp(0, orderedPlays.length),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: rows[r].map((entry) {
                final isLead = entry.key == leadPlayerId;
                final isWinner = entry.key == winnerId;
                return _buildTrickCardItem(
                  entry: entry,
                  isLead: isLead,
                  isWinner: isWinner,
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  cardSpacing: cardSpacing,
                  nameMaxWidth: nameMaxWidth,
                  nameFontSize: nameFontSize,
                  isCompact: totalPlayers >= 7,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrickCardItem({
    required MapEntry<String, pedro.Card> entry,
    required bool isLead,
    required bool isWinner,
    required double cardWidth,
    required double cardHeight,
    required double cardSpacing,
    required double nameMaxWidth,
    required double nameFontSize,
    required bool isCompact,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardSpacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: CardWidget(
                  card: entry.value,
                  width: cardWidth,
                  height: cardHeight,
                ),
              ),
              if (isWinner)
                Positioned(
                  top: -8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 4.0 : 5.0,
                      vertical: 1.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: isCompact ? 7.0 : 8.0, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          'WINNER',
                          style: TextStyle(
                            fontSize: isCompact ? 7.5 : 8.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isLead)
                Positioned(
                  top: -8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 4.0 : 5.0,
                      vertical: 1.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'LEAD',
                      style: TextStyle(
                        fontSize: isCompact ? 7.5 : 8.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: nameMaxWidth),
            child: FutureBuilder<Player?>(
              future: _getPlayer(entry.key),
              initialData: _playerCache[entry.key],
              builder: (context, snap) => Text(
                snap.data?.screenName ?? '...',
                style: TextStyle(
                  fontSize: nameFontSize,
                  fontWeight:
                      (isWinner || isLead) ? FontWeight.bold : FontWeight.normal,
                  color: isWinner ? Colors.amber.shade900 : null,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviousLiftModal(
    BuildContext context,
    Lift lastLift,
    List<PlayerGameState> states,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final orderedPlays = getOrderedLiftPlays(lift: lastLift, playerStates: states);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Previous Trick',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (lastLift.winnerId != null)
                      FutureBuilder<Player?>(
                        future: _getPlayer(lastLift.winnerId!),
                        initialData: _playerCache[lastLift.winnerId!],
                        builder: (context, snap) => Text(
                          'Won by ${snap.data?.screenName ?? '...'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTrickCardsGrid(
                  orderedPlays: orderedPlays,
                  totalPlayers: states.length,
                  leadPlayerId: lastLift.leadPlayerId,
                  winnerId: lastLift.winnerId,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPlayerPositions(GameSession session) {
    final states = session.playerStates;
    final round = session.currentRound;
    final localIndex = states.indexWhere((p) => p.uid == _uid);
    if (localIndex == -1) return [];

    final otherPlayers = <Widget>[];
    final numPlayers = states.length;

    final Map<int, List<Alignment>> layouts = {
      4: [
        const Alignment(0.92, -0.3),
        const Alignment(0.0, -0.92),
        const Alignment(-0.92, -0.3),
      ],
      5: [
        const Alignment(0.92, -0.26),
        const Alignment(0.65, -0.88),
        const Alignment(-0.65, -0.88),
        const Alignment(-0.92, -0.26),
      ],
      6: [
        const Alignment(0.92, -0.26),
        const Alignment(0.65, -0.88),
        const Alignment(0.0, -0.92),
        const Alignment(-0.65, -0.88),
        const Alignment(-0.92, -0.26),
      ],
      7: [
        const Alignment(0.92, 0.3),
        const Alignment(0.92, -0.35),
        const Alignment(0.55, -0.88),
        const Alignment(-0.55, -0.88),
        const Alignment(-0.92, -0.35),
        const Alignment(-0.92, 0.3),
      ],
      8: [
        const Alignment(0.92, 0.3),
        const Alignment(0.92, -0.35),
        const Alignment(0.55, -0.88),
        const Alignment(0.0, -0.92),
        const Alignment(-0.55, -0.88),
        const Alignment(-0.92, -0.35),
        const Alignment(-0.92, 0.3),
      ],
    };

    final playerPositions = layouts[numPlayers] ?? layouts[4]!;
    final isCompact = numPlayers >= 7;
    final badgeMaxWidth = isCompact ? 72.0 : 82.0;
    final avatarRadius = isCompact ? 16.0 : 18.0;
    final badgePadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 4.0 : 6.0,
      vertical: isCompact ? 4.0 : 5.0,
    );
    final badgeOuterPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 4.0 : 6.0,
      vertical: isCompact ? 6.0 : 8.0,
    );

    for (int i = 1; i < numPlayers; i++) {
      final index = (localIndex + i) % numPlayers;
      final playerState = states[index];
      final isHisTurn = round.turnIndex == index;
      final isBidder = round.bidWinnerId == playerState.uid &&
          round.phase != RoundPhase.wadger;
      final alignment = playerPositions[i - 1];

      otherPlayers.add(
        Align(
          alignment: alignment,
          child: Padding(
            padding: badgeOuterPadding,
            child: FutureBuilder<Player?>(
              future: _getPlayer(playerState.uid),
              initialData: _playerCache[playerState.uid],
              builder: (context, snap) {
                final player = snap.data;
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: badgeMaxWidth),
                    padding: badgePadding,
                    decoration: BoxDecoration(
                    color: isHisTurn
                        ? Colors.green.withValues(alpha: 0.1)
                        : (isBidder
                            ? Colors.amber.shade50.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.8)),
                    borderRadius: BorderRadius.circular(12),
                    border: isHisTurn
                        ? Border.all(color: Colors.green, width: 2)
                        : (isBidder
                            ? Border.all(
                                color: Colors.amber.shade600, width: 1.5)
                            : Border.all(color: Colors.grey.shade300)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBidder)
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade200,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.amber.shade800, width: 0.8),
                          ),
                          child: Text(
                            'BIDDER: ${round.bidValue}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      AvatarWidget(avatarUrl: player?.avatarUrl, radius: avatarRadius),
                      const SizedBox(height: 2),
                      Text(
                        player?.screenName ?? '...',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 10.0 : 11.0),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text('Score: ${playerState.totalScore}',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                      if (isBidder)
                        Text(
                          'Pts: ${playerState.currentRoundPoints} / ${round.bidValue}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color:
                                playerState.currentRoundPoints >= round.bidValue
                                    ? Colors.green.shade800
                                    : Colors.orange.shade900,
                          ),
                        )
                      else if (playerState.currentRoundPoints > 0)
                        Text(
                          'Round: ${playerState.currentRoundPoints}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (playerState.cardsDiscarded != null &&
                          round.phase == RoundPhase.playing)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.purple.shade200, width: 0.8),
                          ),
                          child: Text(
                            'Replaced: ${playerState.cardsDiscarded}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ),
                      if (round.phase == RoundPhase.wadger &&
                          round.passedPlayerIds.contains(playerState.uid) &&
                          !playerState.earnedPoints.contains('Pass'))
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.grey.shade400, width: 0.8),
                          ),
                          child: Text(
                            'Passed',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      if (playerState.earnedPoints.isNotEmpty)
                        _buildPointsChips(playerState.earnedPoints),
                    ],
                  ),
                ),
              );
            },
            ),
          ),
        ),
      );
    }
    return otherPlayers;
  }

  Widget _buildPointsChips(List<String> points) {
    return Wrap(
      spacing: 2,
      children: points.map((p) {
        Color bgColor = Colors.blue.shade100;
        Color textColor = Colors.blue.shade900;

        if (p == 'Hang Jack') {
          bgColor = Colors.red.shade100;
          textColor = Colors.red.shade900;
        } else if (p.startsWith('Bid:')) {
          bgColor = Colors.orange.shade100;
          textColor = Colors.orange.shade900;
        } else if (p == 'Pass') {
          bgColor = Colors.grey.shade300;
          textColor = Colors.grey.shade700;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            p,
            style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.bold, color: textColor),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractionArea(GameSession session) {
    final round = session.currentRound;
    final localIndex = session.playerStates.indexWhere((p) => p.uid == _uid);
    final localState = session.playerStates[localIndex];
    final isMyTurn = round.turnIndex == localIndex;
    final isLocalBidder =
        round.bidWinnerId == _uid && round.phase != RoundPhase.wadger;

    if ((round.phase != RoundPhase.wadger || !isMyTurn) &&
        _bidSuggestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _bidSuggestion != null) {
          setState(() => _bidSuggestion = null);
        }
      });
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyTurn ? Colors.green[50] : Colors.grey[100],
        border: Border(
            top: BorderSide(
                color: isMyTurn ? Colors.green : Colors.grey, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLocalBidder) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.amber.shade800, width: 0.8),
                              ),
                              child: Text(
                                'YOU BID ${round.bidValue}',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Target: ${localState.currentRoundPoints} / ${round.bidValue} pts',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: localState.currentRoundPoints >=
                                        round.bidValue
                                    ? Colors.green.shade800
                                    : Colors.orange.shade900,
                              ),
                            ),
                            if (localState.currentRoundPoints >=
                                round.bidValue) ...[
                              const SizedBox(width: 2),
                              Icon(Icons.check_circle,
                                  size: 12, color: Colors.green.shade800),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      Text('Points: ${localState.currentRoundPoints}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.blue)),
                    ],
                    if (localState.cardsDiscarded != null &&
                        round.phase == RoundPhase.playing)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.purple.shade200, width: 0.8),
                        ),
                        child: Text(
                          'You replaced ${localState.cardsDiscarded} cards',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                    if (round.phase == RoundPhase.wadger &&
                        round.passedPlayerIds.contains(_uid) &&
                        !localState.earnedPoints.contains('Pass'))
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.grey.shade400, width: 0.8),
                        ),
                        child: Text(
                          'You Passed',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    _buildPointsChips(localState.earnedPoints),
                    Text('Total: ${localState.totalScore}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isMyTurn)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _isReviewCooldownActive
                          ? 'REVIEWING LIFT...'
                          : (round.currentLift?.winnerId != null
                              ? 'YOUR TURN TO LEAD'
                              : 'YOUR TURN'),
                      style: TextStyle(
                        color: _isReviewCooldownActive
                            ? Colors.orange.shade800
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: _WaitingAndCallArea(
                    session: session,
                    currentUserId: _uid,
                    gameRepo: _gameRepo,
                    getPlayer: _getPlayer,
                    playerCache: _playerCache,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (round.phase == RoundPhase.wadger &&
              isMyTurn &&
              !round.passedPlayerIds.contains(_uid)) ...[
            if (_isAnalyzingHand) const LinearProgressIndicator(),
            if (_bidSuggestion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text('Coach: $_bidSuggestion',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey,
                        fontSize: 11)),
              ),
            ElevatedButton.icon(
              onPressed: _isAnalyzingHand
                  ? null
                  : () => _analyzeHand(localState.hand),
              icon: const Icon(Icons.lightbulb, size: 16),
              label: const Text('Get Hint'),
              style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 6),
            _buildBidControls(session),
          ],
          if (round.phase == RoundPhase.playing && isMyTurn) ...[
            if (_isAnalyzingMove) const LinearProgressIndicator(),
            if (_moveSuggestion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text('Coach: $_moveSuggestion',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey,
                        fontSize: 11)),
              ),
            ElevatedButton.icon(
              onPressed: _isAnalyzingMove
                  ? null
                  : () => _analyzeMove(localState.hand, round.currentLift,
                      round.trumpSuit, round.playedCards),
              icon: const Icon(Icons.lightbulb, size: 16),
              label: const Text('Get Hint'),
              style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact),
            ),
          ],
          if (round.phase == RoundPhase.discarding &&
              isMyTurn &&
              round.bidWinnerId == _uid)
            _buildTrumpSelector(session),
          if (_isSubmittingCard) ...[
            const SizedBox(height: 4),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 8),
          const Text('Your Hand',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 4),
          Builder(builder: (context) {
            final sortedHand = localState.hand.sortedHand(
              trumpSuit: round.trumpSuit,
              trumpPosition: TrumpPosition.none,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sortedHand.asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  final isLastInSuit = index < sortedHand.length - 1 &&
                      sortedHand[index + 1].suit != card.suit;
                  final isSubmittingThisCard =
                      _isSubmittingCard && _submittedCard == card;
                  return Padding(
                    key: ValueKey('${card.suit.name}_${card.rank.name}'),
                    padding: EdgeInsets.only(right: isLastInSuit ? 12.0 : 6.0),
                    child: CardWidget(
                      card: card,
                      isSubmitting: isSubmittingThisCard,
                      onTap: (round.phase == RoundPhase.playing &&
                              isMyTurn &&
                              !_isReviewCooldownActive &&
                              !_isSubmittingCard)
                          ? () => _playCard(
                                card: card,
                                hand: localState.hand,
                                round: round,
                                isMyTurn: isMyTurn,
                              )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 6),
          ReactionBar(
            gameId: widget.gameId,
            reactionRepository: widget.reactionRepository,
            playerRepository: _playerRepo,
          ),
        ],
      ),
    );
  }

  Future<void> _playCard({
    required pedro.Card card,
    required List<pedro.Card> hand,
    required RoundState round,
    required bool isMyTurn,
  }) async {
    final now = clock.now();
    if (_lastCardSubmitTime != null &&
        now.difference(_lastCardSubmitTime!).inMilliseconds < 500) {
      return;
    }
    _lastCardSubmitTime = now;

    if (_isSubmittingCard) return;

    final validation = validateCardPlay(
      card: card,
      hand: hand,
      currentLift: round.currentLift,
      trumpSuit: round.trumpSuit,
      phase: round.phase,
      isMyTurn: isMyTurn,
    );

    if (!validation.isLegal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid Move: ${validation.reason}'),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingCard = true;
      _submittedCard = card;
    });

    _cardSubmissionSafetyTimer?.cancel();
    _cardSubmissionSafetyTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isSubmittingCard) {
        setState(() {
          _isSubmittingCard = false;
          _submittedCard = null;
        });
      }
    });

    try {
      await _gameRepo.playCard(widget.gameId, card);
      if (mounted) setState(() => _moveSuggestion = null);
    } catch (e) {
      _cardSubmissionSafetyTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSubmittingCard = false;
          _submittedCard = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server Error: $e'),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBidControls(GameSession session) {
    final currentBid = session.currentRound.bidValue;
    final isInitialBid = currentBid == 0;
    return Column(
      children: [
        Text(
          isInitialBid
              ? 'Place opening bid (1-20)'
              : 'Place your bid (${currentBid + 1}-20) or Pass',
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ActionChip(
                  label: Text(
                    'Pass',
                    style: TextStyle(
                      fontSize: 10,
                      color: isInitialBid
                          ? Colors.grey.shade500
                          : Colors.red.shade900,
                    ),
                  ),
                  onPressed: isInitialBid
                      ? null
                      : () {
                          if (mounted) {
                            setState(() => _bidSuggestion = null);
                          }
                          _gameRepo.submitBid(widget.gameId, null);
                        },
                  backgroundColor:
                      isInitialBid ? Colors.grey.shade200 : Colors.red[100],
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
              for (int b = currentBid + 1; b <= 20; b++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ActionChip(
                    label: Text('$b', style: const TextStyle(fontSize: 10)),
                    onPressed: () {
                      if (mounted) {
                        setState(() => _bidSuggestion = null);
                      }
                      _gameRepo.submitBid(widget.gameId, b);
                    },
                    backgroundColor: Colors.blue[100],
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrumpSelector(GameSession session) {
    return Column(
      children: [
        const Text('Choose Trump Suit',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pedro.Suit.values.map((suit) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: IconButton.filled(
                icon: Icon(_suitIcon(suit), color: _suitColor(suit), size: 20),
                onPressed: () => _gameRepo.setTrumpSuit(widget.gameId, suit),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    visualDensity: VisualDensity.compact),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

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
}

class _WaitingAndCallArea extends StatefulWidget {
  const _WaitingAndCallArea({
    required this.session,
    required this.currentUserId,
    required this.gameRepo,
    required this.getPlayer,
    required this.playerCache,
  });

  final GameSession session;
  final String? currentUserId;
  final GameRepository gameRepo;
  final Future<Player?> Function(String) getPlayer;
  final Map<String, Player> playerCache;

  @override
  State<_WaitingAndCallArea> createState() => _WaitingAndCallAreaState();
}

class _WaitingAndCallAreaState extends State<_WaitingAndCallArea> {
  bool _isCallingPlayer = false;
  Timer? _callCooldownTicker;

  @override
  void dispose() {
    _callCooldownTicker?.cancel();
    super.dispose();
  }

  void _ensureCooldownTicker() {
    if (_callCooldownTicker != null && _callCooldownTicker!.isActive) return;
    _callCooldownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _callCurrentPlayer(GameSession session) async {
    if (_isCallingPlayer) return;
    setState(() => _isCallingPlayer = true);
    try {
      await widget.gameRepo.callPlayer(session.gameId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nudge sent! AI Narrator is calling the player.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not call player: $e'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCallingPlayer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.session.currentRound;
    final activeIndex = round.turnIndex;
    final activeUid = (activeIndex >= 0 && activeIndex < widget.session.playerStates.length)
        ? widget.session.playerStates[activeIndex].uid
        : null;

    int cooldownRemaining = 0;
    if (round.lastCalledAt != null) {
      final diff = DateTime.now().toUtc().difference(round.lastCalledAt!.toUtc());
      if (diff.inSeconds < 30) {
        cooldownRemaining = 30 - diff.inSeconds;
        _ensureCooldownTicker();
      }
    }

    final showCallButton =
        widget.session.currentRound.phase != RoundPhase.finished &&
            activeUid != null &&
            activeUid != widget.currentUserId;

    final waitingTextWidget = (activeUid != null)
        ? FutureBuilder<Player?>(
            future: widget.getPlayer(activeUid),
            initialData: widget.playerCache[activeUid],
            builder: (context, snap) {
              final name = snap.data?.screenName ?? 'player';
              return Text(
                'Waiting for $name...',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            },
          )
        : const Text(
            'Waiting...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          );

    if (!showCallButton) {
      return waitingTextWidget;
    }

    final callButton = cooldownRemaining > 0
        ? OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.notifications_paused, size: 13),
            label: Text('Called (${cooldownRemaining}s)',
                style: const TextStyle(fontSize: 10)),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            ),
          )
        : OutlinedButton.icon(
            onPressed:
                _isCallingPlayer ? null : () => _callCurrentPlayer(widget.session),
            icon: const Icon(Icons.notifications_active,
                size: 13, color: Color(0xFF00694B)),
            label: const Text('Call Player',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00694B))),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 260) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: waitingTextWidget),
              const SizedBox(width: 8),
              callButton,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            waitingTextWidget,
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: callButton,
            ),
          ],
        );
      },
    );
  }
}

