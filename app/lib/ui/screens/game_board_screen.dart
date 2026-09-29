import 'dart:async';
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
import '../../data/logic/card_play_validator.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key, required this.gameId});
  final String gameId;

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  final _gameRepo = GameRepository();
  final _playerRepo = PlayerRepository();
  final _bidAssistant = BidAssistantService();
  final _tacticalCoach = TacticalCoachService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;

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

  String? _lastObservedWinnerId;
  bool _isReviewCooldownActive = false;
  Timer? _reviewCooldownTimer;

  @override
  void dispose() {
    _reviewCooldownTimer?.cancel();
    super.dispose();
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

  Future<void> _analyzeHand(List<pedro.Card> hand) async {
    if (_bidSuggestion != null || _isAnalyzingHand) return;
    setState(() => _isAnalyzingHand = true);
    final suggestion = await _bidAssistant.getBidSuggestion(hand);
    if (mounted) {
      setState(() {
        _bidSuggestion = suggestion;
        _isAnalyzingHand = false;
      });
    }
  }

  Future<void> _analyzeMove(List<pedro.Card> hand, Lift? lift,
      pedro.Suit? trump, List<pedro.Card> playedCards) async {
    setState(() => _isAnalyzingMove = true);
    final suggestion = await _tacticalCoach.getMoveSuggestion(
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
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameSession?>(
      stream: _gameRepo.watchGameSession(widget.gameId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        final session = snapshot.data!;
        _checkLiftCompletion(session.currentRound.currentLift);

        return Scaffold(
          appBar: AppBar(
            title:
                Text('Pedro: ${session.currentRound.phase.name.toUpperCase()}'),
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
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: const Alignment(0, 0.08),
                        child: _buildLiftArea(
                          session.currentRound.currentLift,
                          session.playerStates,
                          lastLift: session.currentRound.lastLift,
                        ),
                      ),
                    ),
                    ..._buildPlayerPositions(session),
                    FloatingReactionsOverlay(gameId: widget.gameId),
                  ],
                ),
              ),
              _buildInteractionArea(session),
              ChatOverlay(gameId: widget.gameId),
            ],
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
      return Container(
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
      );
    }

    final orderedPlays = getOrderedLiftPlays(lift: lift, playerStates: states);
    final leadCard = lift.plays[lift.leadPlayerId] ?? orderedPlays.first.value;
    final leadSuit = leadCard.suit;
    final isLiftComplete = lift.winnerId != null;

    return Container(
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
                  future: _playerRepo.getPlayer(lift.winnerId!),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: orderedPlays.map((entry) {
                final isLead = entry.key == lift.leadPlayerId;
                final isWinner = entry.key == lift.winnerId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                              width: 52,
                              height: 78,
                            ),
                          ),
                          if (isWinner)
                            Positioned(
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 8, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text(
                                      'WINNER',
                                      style: TextStyle(
                                        fontSize: 8,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
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
                                child: const Text(
                                  'LEAD',
                                  style: TextStyle(
                                    fontSize: 8,
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
                        constraints: const BoxConstraints(maxWidth: 60),
                        child: FutureBuilder<Player?>(
                          future: _playerRepo.getPlayer(entry.key),
                          builder: (context, snap) => Text(
                            snap.data?.screenName ?? '...',
                            style: TextStyle(
                              fontSize: 10,
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
              }).toList(),
            ),
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
                future: _playerRepo.getPlayer(lift.winnerId!),
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
                        future: _playerRepo.getPlayer(lastLift.winnerId!),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: orderedPlays.map((entry) {
                      final isWinner = entry.key == lastLift.winnerId;
                      final isLead = entry.key == lastLift.leadPlayerId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CardWidget(
                              card: entry.value,
                              width: 52,
                              height: 78,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isWinner ? '★ WINNER' : (isLead ? 'LEAD' : ''),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isWinner ? Colors.green.shade700 : Colors.amber.shade800,
                              ),
                            ),
                            FutureBuilder<Player?>(
                              future: _playerRepo.getPlayer(entry.key),
                              builder: (context, snap) => Text(
                                snap.data?.screenName ?? '...',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
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
        const Alignment(0.92, -0.15),
        const Alignment(0.65, -0.88),
        const Alignment(-0.65, -0.88),
        const Alignment(-0.92, -0.15),
      ],
      6: [
        const Alignment(0.92, -0.15),
        const Alignment(0.65, -0.88),
        const Alignment(0.0, -0.92),
        const Alignment(-0.65, -0.88),
        const Alignment(-0.92, -0.15),
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
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            child: FutureBuilder<Player?>(
              future: _getPlayer(playerState.uid),
              initialData: _playerCache[playerState.uid],
              builder: (context, snap) {
                final player = snap.data;
                return Container(
                  constraints: const BoxConstraints(maxWidth: 82),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
                      AvatarWidget(avatarUrl: player?.avatarUrl, radius: 18),
                      const SizedBox(height: 2),
                      Text(
                        player?.screenName ?? '...',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 11),
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
                      if (playerState.earnedPoints.isNotEmpty)
                        _buildPointsChips(playerState.earnedPoints),
                    ],
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

    if (round.phase == RoundPhase.wadger && isMyTurn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _analyzeHand(localState.hand);
      });
    } else if (round.phase != RoundPhase.wadger && _bidSuggestion != null) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLocalBidder) ...[
                    Row(
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
                  ] else ...[
                    Text('Points: ${localState.currentRoundPoints}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.blue)),
                  ],
                  _buildPointsChips(localState.earnedPoints),
                  Text('Total: ${localState.totalScore}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              if (isMyTurn)
                Text(
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
                )
              else
                const Text('Waiting...',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (round.phase == RoundPhase.wadger && isMyTurn) ...[
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: localState.hand.map((card) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CardWidget(
                    card: card,
                    onTap: (round.phase == RoundPhase.playing &&
                            isMyTurn &&
                            !_isReviewCooldownActive)
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
          ),
          const SizedBox(height: 6),
          ReactionBar(gameId: widget.gameId),
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

    setState(() => _isSubmittingCard = true);
    try {
      await _gameRepo.playCard(widget.gameId, card);
      if (mounted) setState(() => _moveSuggestion = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server Error: $e'),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingCard = false);
      }
    }
  }

  Widget _buildBidControls(GameSession session) {
    final currentBid = session.currentRound.bidValue;
    return Column(
      children: [
        const Text('Place your bid (1-20) or Pass',
            style: TextStyle(fontSize: 11)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int b = currentBid + 1; b <= 20; b++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ActionChip(
                    label: Text('$b', style: const TextStyle(fontSize: 10)),
                    onPressed: () => _gameRepo.submitBid(widget.gameId, b),
                    backgroundColor: Colors.blue[100],
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ActionChip(
                  label: const Text('Pass', style: TextStyle(fontSize: 10)),
                  onPressed: () => _gameRepo.submitBid(widget.gameId, null),
                  backgroundColor: Colors.red[100],
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
