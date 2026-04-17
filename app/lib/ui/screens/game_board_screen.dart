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
import '../../data/services/bid_assistant_service.dart';
import '../../data/services/tactical_coach_service.dart';

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
  
  String? _bidSuggestion;
  bool _isAnalyzingHand = false;
  
  String? _moveSuggestion;
  bool _isAnalyzingMove = false;

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

  Future<void> _analyzeMove(List<pedro.Card> hand, Lift? lift, pedro.Suit? trump, List<pedro.Card> playedCards) async {
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
        if (snapshot.hasError) return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final session = snapshot.data!;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Pedro: ${session.currentRound.phase.name.toUpperCase()}'),
            actions: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Target: ${session.targetScore}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('Bid: ${session.currentRound.bidValue}', style: const TextStyle(fontSize: 14)),
                  if (session.currentRound.trumpSuit != null) 
                    Icon(_suitIcon(session.currentRound.trumpSuit!), size: 16),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: _buildLiftArea(session.currentRound.currentLift, session.playerStates),
                    ),
                    ..._buildPlayerPositions(session),
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

  Widget _buildLiftArea(Lift? lift, List<PlayerGameState> states) {
    if (lift == null || lift.plays.isEmpty) return const Text('Waiting for plays...', style: TextStyle(color: Colors.grey));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: lift.plays.entries.map((entry) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CardWidget(card: entry.value),
            const SizedBox(height: 4),
            FutureBuilder<Player?>(
              future: _playerRepo.getPlayer(entry.key),
              builder: (context, snap) => Text(snap.data?.displayName ?? '...', style: const TextStyle(fontSize: 10)),
            ),
          ],
        );
      }).toList(),
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
      4: [Alignment.centerRight, Alignment.topCenter, Alignment.centerLeft],
      5: [Alignment.centerRight, Alignment.topRight, Alignment.topLeft, Alignment.centerLeft],
      6: [Alignment.centerRight, Alignment.topRight, Alignment.topCenter, Alignment.topLeft, Alignment.centerLeft],
      7: [Alignment.bottomRight, Alignment.centerRight, Alignment.topRight, Alignment.topLeft, Alignment.centerLeft, Alignment.bottomLeft],
      8: [Alignment.bottomRight, Alignment.centerRight, Alignment.topRight, Alignment.topCenter, Alignment.topLeft, Alignment.centerLeft, Alignment.bottomLeft],
    };

    final playerPositions = layouts[numPlayers] ?? layouts[4]!;

    for (int i = 1; i < numPlayers; i++) {
      final index = (localIndex + i) % numPlayers;
      final playerState = states[index];
      final isHisTurn = round.turnIndex == index;
      final alignment = playerPositions[i - 1];

      otherPlayers.add(
        Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: FutureBuilder<Player?>(
              future: _playerRepo.getPlayer(playerState.uid),
              builder: (context, snap) {
                final player = snap.data;
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isHisTurn ? Colors.green.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: isHisTurn ? Border.all(color: Colors.green, width: 2) : Border.all(color: Colors.grey.shade300),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarWidget(avatarUrl: player?.avatarUrl, radius: 20),
                      Text(
                        player?.displayName ?? '...', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Score: ${playerState.totalScore}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textColor),
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

    if (round.phase == RoundPhase.wadger && isMyTurn) {
      _analyzeHand(localState.hand);
    } else if (round.phase != RoundPhase.wadger) {
      _bidSuggestion = null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyTurn ? Colors.green[50] : Colors.grey[100],
        border: Border(top: BorderSide(color: isMyTurn ? Colors.green : Colors.grey, width: 2)),
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
                  Text('Points: ${localState.currentRoundPoints}', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                  _buildPointsChips(localState.earnedPoints),
                  Text('Total: ${localState.totalScore}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              if (isMyTurn) 
                const Text('YOUR TURN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))
              else
                const Text('Waiting...', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (round.phase == RoundPhase.wadger && isMyTurn) ...[
            if (_isAnalyzingHand) const LinearProgressIndicator(),
            if (_bidSuggestion != null) 
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text('Coach: $_bidSuggestion', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey, fontSize: 11)),
              ),
            _buildBidControls(session),
          ],
          if (round.phase == RoundPhase.playing && isMyTurn) ...[
            if (_isAnalyzingMove) const LinearProgressIndicator(),
            if (_moveSuggestion != null)
               Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text('Coach: $_moveSuggestion', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey, fontSize: 11)),
              ),
            ElevatedButton.icon(
              onPressed: _isAnalyzingMove ? null : () => _analyzeMove(localState.hand, round.currentLift, round.trumpSuit, round.playedCards),
              icon: const Icon(Icons.lightbulb, size: 16),
              label: const Text('Get Hint'),
              style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
          if (round.phase == RoundPhase.discarding && isMyTurn && round.bidWinnerId == _uid)
            _buildTrumpSelector(session),
          const SizedBox(height: 8),
          const Text('Your Hand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: localState.hand.map((card) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CardWidget(
                    card: card,
                    onTap: (round.phase == RoundPhase.playing && isMyTurn) 
                        ? () async {
                            try {
                              await _gameRepo.playCard(widget.gameId, card);
                              setState(() => _moveSuggestion = null);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invalid Move: $e')),
                                );
                              }
                            }
                          }
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidControls(GameSession session) {
    final currentBid = session.currentRound.bidValue;
    return Column(
      children: [
        const Text('Place your bid (1-20) or Pass', style: TextStyle(fontSize: 11)),
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
        const Text('Choose Trump Suit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pedro.Suit.values.map((suit) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: IconButton.filled(
                icon: Icon(_suitIcon(suit), color: _suitColor(suit), size: 20),
                onPressed: () => _gameRepo.setTrumpSuit(widget.gameId, suit),
                style: IconButton.styleFrom(backgroundColor: Colors.white, visualDensity: VisualDensity.compact),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _suitIcon(pedro.Suit suit) {
    switch (suit) {
      case pedro.Suit.clubs: return Icons.circle;
      case pedro.Suit.diamonds: return Icons.diamond;
      case pedro.Suit.hearts: return Icons.favorite;
      case pedro.Suit.spades: return Icons.architecture;
    }
  }
  
  Color _suitColor(pedro.Suit suit) {
    return (suit == pedro.Suit.hearts || suit == pedro.Suit.diamonds) ? Colors.red : Colors.black;
  }
}
