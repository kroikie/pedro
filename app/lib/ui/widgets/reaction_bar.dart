import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/reaction_repository.dart';
import '../../data/repositories/player_repository.dart';

class ReactionBar extends StatefulWidget {
  const ReactionBar({
    super.key,
    required this.gameId,
    this.reactionRepository,
    this.playerRepository,
  });

  final String gameId;
  final ReactionRepository? reactionRepository;
  final PlayerRepository? playerRepository;

  static const List<String> availableEmojis = [
    '👏',
    '🔥',
    '😂',
    '😱',
    '🎉',
    '👍',
    '🤦‍♂️',
  ];

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  late final ReactionRepository _reactionRepo =
      widget.reactionRepository ?? ReactionRepository();
  late final PlayerRepository _playerRepo =
      widget.playerRepository ?? PlayerRepository();
  String? _cachedScreenName;
  DateTime _lastSentTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final player = await _playerRepo.getPlayer(user.uid);
        if (mounted) {
          setState(() {
            _cachedScreenName =
                player?.screenName ?? user.displayName ?? 'Player';
          });
        }
      }
    } catch (_) {
      // Firebase not initialized in test environment
    }
  }

  Future<void> _onEmojiTapped(String emoji) async {
    final now = DateTime.now();
    if (now.difference(_lastSentTime).inMilliseconds < 400) {
      return; // Rate limit debounce
    }
    _lastSentTime = now;

    String? userId;
    String senderName = _cachedScreenName ?? 'Player';
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
        senderName = _cachedScreenName ?? user.displayName ?? 'Player';
      }
    } catch (_) {
      // Firebase not initialized in test environment
    }

    if (userId == null) {
      if (widget.reactionRepository != null) {
        userId = 'test_user';
      } else {
        debugPrint('Cannot send reaction: user is not authenticated.');
        return;
      }
    }

    try {
      await _reactionRepo.sendReaction(
        gameId: widget.gameId,
        senderId: userId,
        senderName: senderName,
        emoji: emoji,
      );
    } catch (e) {
      debugPrint('Error sending reaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: ReactionBar.availableEmojis.map((emoji) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _onEmojiTapped(emoji),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
