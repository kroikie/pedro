import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/game_reaction.dart';
import '../../data/repositories/reaction_repository.dart';

class FloatingReactionsOverlay extends StatefulWidget {
  const FloatingReactionsOverlay({
    super.key,
    required this.gameId,
    this.reactionRepository,
  });

  final String gameId;
  final ReactionRepository? reactionRepository;

  @override
  State<FloatingReactionsOverlay> createState() =>
      _FloatingReactionsOverlayState();
}

class _FloatingReactionsOverlayState extends State<FloatingReactionsOverlay> {
  late final ReactionRepository _reactionRepo =
      widget.reactionRepository ?? ReactionRepository();
  StreamSubscription<List<GameReaction>>? _reactionSubscription;
  final Set<String> _seenReactionIds = {};
  bool _isInitialLoad = true;
  final List<GameReaction> _activeReactions = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _subscribeToReactions();
  }

  @override
  void didUpdateWidget(covariant FloatingReactionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _reactionSubscription?.cancel();
      _seenReactionIds.clear();
      _isInitialLoad = true;
      setState(() {
        _activeReactions.clear();
      });
      _subscribeToReactions();
    }
  }

  void _subscribeToReactions() {
    _reactionSubscription =
        _reactionRepo.watchRecentReactions(widget.gameId).listen((reactions) {
      if (_isInitialLoad) {
        _seenReactionIds.addAll(reactions.map((r) => r.id));
        _isInitialLoad = false;
        return;
      }

      final newReactions =
          reactions.where((r) => !_seenReactionIds.contains(r.id)).toList();
      if (newReactions.isNotEmpty) {
        for (final r in newReactions) {
          _seenReactionIds.add(r.id);
        }

        if (mounted) {
          setState(() {
            _activeReactions.addAll(newReactions);
          });
        }
      }
    });
  }

  void _removeReaction(GameReaction reaction) {
    if (mounted) {
      setState(() {
        _activeReactions.remove(reaction);
      });
    }
  }

  @override
  void dispose() {
    _reactionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: _activeReactions.map((reaction) {
              return _FloatingEmojiParticle(
                key: ValueKey('particle_${reaction.id}'),
                reaction: reaction,
                containerWidth: constraints.maxWidth,
                containerHeight: constraints.maxHeight,
                random: _random,
                onComplete: () => _removeReaction(reaction),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _FloatingEmojiParticle extends StatefulWidget {
  const _FloatingEmojiParticle({
    super.key,
    required this.reaction,
    required this.containerWidth,
    required this.containerHeight,
    required this.random,
    required this.onComplete,
  });

  final GameReaction reaction;
  final double containerWidth;
  final double containerHeight;
  final Random random;
  final VoidCallback onComplete;

  @override
  State<_FloatingEmojiParticle> createState() => _FloatingEmojiParticleState();
}

class _FloatingEmojiParticleState extends State<_FloatingEmojiParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _startX;
  late final double _wobbleAmplitude;
  late final double _wobbleFrequency;
  late final double _travelDistance;

  @override
  void initState() {
    super.initState();
    final width = widget.containerWidth > 0 ? widget.containerWidth : 300.0;
    // Spawn between 20% and 80% of width
    _startX = (width * 0.2) + (widget.random.nextDouble() * (width * 0.6));
    _wobbleAmplitude = 15.0 + (widget.random.nextDouble() * 20.0);
    _wobbleFrequency = 1.0 + (widget.random.nextDouble() * 1.5);
    final height = widget.containerHeight > 0 ? widget.containerHeight : 400.0;
    _travelDistance = height * 0.65;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // Fade in quickly, stay, then fade out
        final opacity = progress > 0.65
            ? ((1.0 - progress) / 0.35).clamp(0.0, 1.0)
            : (progress / 0.15).clamp(0.0, 1.0);

        // Scale pop effect
        final scale = progress < 0.2
            ? 0.5 + (progress / 0.2) * 0.6 // 0.5 -> 1.1
            : progress < 0.35
                ? 1.1 - ((progress - 0.2) / 0.15) * 0.1 // 1.1 -> 1.0
                : 1.0;

        // Position calculations
        final yOffset = progress * _travelDistance;
        final xOffset =
            sin(progress * 2 * pi * _wobbleFrequency) * _wobbleAmplitude;

        final startY =
            widget.containerHeight > 0 ? widget.containerHeight - 80.0 : 300.0;

        return Positioned(
          left: (_startX + xOffset)
              .clamp(10.0, max(10.0, widget.containerWidth - 80.0)),
          top: startY - yOffset,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.reaction.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.reaction.senderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
