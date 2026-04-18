import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/player.dart';

class ChatOverlay extends StatefulWidget {
  const ChatOverlay({super.key, required this.gameId});
  final String gameId;

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final _chatRepo = ChatRepository();
  final _playerRepo = PlayerRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isExpanded = false;
  String? _cachedScreenName;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final player = await _playerRepo.getPlayer(user.uid);
      if (mounted) {
        setState(() {
          _cachedScreenName = player?.screenName ?? user.displayName ?? 'Anonymous';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Use cached name if available, otherwise fallback and trigger reload
    final senderName = _cachedScreenName ?? user.displayName ?? 'Anonymous';
    if (_cachedScreenName == null) {
      _loadPlayerName();
    }

    await _chatRepo.sendMessage(
      gameId: widget.gameId,
      senderId: user.uid,
      senderName: senderName,
      text: text,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 400 : 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Game Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(_isExpanded ? Icons.expand_more : Icons.expand_less),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatRepo.watchMessages(widget.gameId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!;
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == FirebaseAuth.instance.currentUser?.uid;
                      return ListTile(
                        dense: true,
                        title: Text(
                          msg.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: msg.isAi ? Colors.purple : (isMe ? Colors.blue : Colors.black),
                          ),
                        ),
                        subtitle: Text(msg.text),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
