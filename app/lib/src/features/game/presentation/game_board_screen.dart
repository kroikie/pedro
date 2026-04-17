import 'package:flutter/material.dart' hide Card;
import 'package:firebase_auth/firebase_auth.dart';
import '../data/game_repository.dart';
import '../domain/game_session.dart';
import '../domain/card.dart' as pedro;
import 'card_widget.dart';
import '../../player/domain/player.dart';
import '../../player/data/player_repository.dart';
import '../../../common_widgets/avatar_widget.dart';
import '../../chat/presentation/chat_overlay.dart';
import '../../lobby/application/bid_assistant_service.dart';
import '../../lobby/application/tactical_coach_service.dart';

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

  Future<void> _analyzeMove(List<pedro.Card> hand, Lift? lift, pedro.Suit? trump) async {
    setState(() => _isAnalyzingMove = true);
    final suggestion = await _tacticalCoach.getMoveSuggestion(
      hand: hand,
      currentLift: lift,
      trumpSuit: trump,
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
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final session = snapshot.data!;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Pedro: ${session.currentRound.phase.name}'),
            actions: [
              Text('Bid: ${session.currentRound.bidValue}', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 16),
              if (session.currentRound.trumpSuit != null) 
                Icon(_suitIcon(session.currentRound.trumpSuit!)),
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
                    ..._buildPlayerPositions(session.playerStates),
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
    if (lift == null) return const SizedBox();
    return Wrap(
      spacing: 8,
      children: lift.plays.values.map((card) => CardWidget(card: card)).toList(),
    );
  }

  List<Widget> _buildPlayerPositions(List<PlayerGameState> states) {
    return states.where((p) => p.uid != _uid).map((p) {
      return FutureBuilder<Player?>(
        future: _playerRepo.getPlayer(p.uid),
        builder: (context, snap) {
          final player = snap.data;
          return Align(
            alignment: Alignment.topCenter, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarWidget(avatarUrl: player?.avatarUrl, radius: 25),
                Text(player?.displayName ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Score: ${p.totalScore}'),
              ],
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildInteractionArea(GameSession session) {
    final round = session.currentRound;
    final localState = session.playerStates.firstWhere((p) => p.uid == _uid);
    final isMyTurn = session.playerStates[round.turnIndex % session.playerStates.length].uid == _uid;

    if (round.phase == RoundPhase.wadger && isMyTurn) {
      _analyzeHand(localState.hand);
    } else if (round.phase != RoundPhase.wadger) {
      _bidSuggestion = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (round.phase == RoundPhase.wadger && isMyTurn) ...[
            if (_isAnalyzingHand) const LinearProgressIndicator(),
            if (_bidSuggestion != null) 
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Coach: $_bidSuggestion', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
              ),
            _buildBidControls(session),
          ],
          if (round.phase == RoundPhase.playing && isMyTurn) ...[
            if (_isAnalyzingMove) const LinearProgressIndicator(),
            if (_moveSuggestion != null)
               Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Coach: $_moveSuggestion', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
              ),
            ElevatedButton.icon(
              onPressed: _isAnalyzingMove ? null : () => _analyzeMove(localState.hand, round.currentLift, round.trumpSuit),
              icon: const Icon(Icons.lightbulb),
              label: const Text('Get Hint'),
            ),
          ],
          if (round.phase == RoundPhase.discarding && isMyTurn && round.bidWinnerId == _uid)
            _buildTrumpSelector(session),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: localState.hand.map((card) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CardWidget(
                    card: card,
                    onTap: (round.phase == RoundPhase.playing && isMyTurn) 
                        ? () {
                            _gameRepo.playCard(widget.gameId, card);
                            setState(() => _moveSuggestion = null);
                          }
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          if (isMyTurn) const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('YOUR TURN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBidControls(GameSession session) {
    final currentBid = session.currentRound.bidValue;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int b = currentBid + 1; b <= 14; b++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => _gameRepo.submitBid(widget.gameId, b),
                child: Text('$b'),
              ),
            ),
          TextButton(
            onPressed: () => _gameRepo.submitBid(widget.gameId, null),
            child: const Text('Pass'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrumpSelector(GameSession session) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pedro.Suit.values.map((suit) {
        return IconButton(
          icon: Icon(_suitIcon(suit), color: _suitColor(suit)),
          onPressed: () => _gameRepo.setTrumpSuit(widget.gameId, suit),
        );
      }).toList(),
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
