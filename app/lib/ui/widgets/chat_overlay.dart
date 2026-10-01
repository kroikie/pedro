import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/models/chat_message.dart';
import 'chat_toast_banner.dart';

class ChatOverlay extends StatefulWidget {
  const ChatOverlay({
    super.key,
    required this.gameId,
    this.chatRepository,
    this.playerRepository,
    this.expandedHeight,
    this.currentUserId,
  });

  final String gameId;
  final ChatRepository? chatRepository;
  final PlayerRepository? playerRepository;
  final double? expandedHeight;
  final String? currentUserId;

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay>
    with SingleTickerProviderStateMixin {
  late final ChatRepository _chatRepo =
      widget.chatRepository ?? ChatRepository();
  late final PlayerRepository _playerRepo =
      widget.playerRepository ?? PlayerRepository();
  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _overlayPortalController = OverlayPortalController();

  late final AnimationController _toastAnimController;
  StreamSubscription<List<ChatMessage>>? _messageSubscription;
  Timer? _toastTimer;

  bool _isExpanded = false;
  String? _cachedScreenName;
  bool _isInitialLoad = true;
  final Set<String> _seenMessageIds = {};
  int _unreadCount = 0;
  ChatMessage? _activeToastMessage;

  @override
  void initState() {
    super.initState();
    _toastAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadPlayerName();
    _subscribeToMessages();
  }

  @override
  void didUpdateWidget(covariant ChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _messageSubscription?.cancel();
      _toastTimer?.cancel();
      if (_overlayPortalController.isShowing) {
        _overlayPortalController.hide();
      }
      _activeToastMessage = null;
      _seenMessageIds.clear();
      _isInitialLoad = true;
      _unreadCount = 0;
      _subscribeToMessages();
    }
  }

  void _subscribeToMessages() {
    _messageSubscription =
        _chatRepo.watchMessages(widget.gameId).listen(
      (messages) {
        if (_isInitialLoad) {
          _seenMessageIds.addAll(messages.map((m) => m.id));
          _isInitialLoad = false;
          return;
        }

        final newMessages =
            messages.where((m) => !_seenMessageIds.contains(m.id)).toList();
        if (newMessages.isNotEmpty) {
          for (final m in newMessages) {
            _seenMessageIds.add(m.id);
          }

          if (!_isExpanded) {
            setState(() {
              _unreadCount += newMessages.length;
            });
            _showToast(newMessages.first);
          }
        }
      },
      onError: (error) {
        debugPrint('ChatOverlay messages subscription error: $error');
      },
    );
  }

  void _showToast(ChatMessage message) {
    _toastTimer?.cancel();
    setState(() {
      _activeToastMessage = message;
    });
    if (!_overlayPortalController.isShowing) {
      _overlayPortalController.show();
    }
    _toastAnimController.forward(from: 0.0);
    _toastTimer = Timer(const Duration(seconds: 5), () {
      _dismissToastWithAnimation();
    });
  }

  void _dismissToastWithAnimation() {
    _toastTimer?.cancel();
    if (_toastAnimController.status != AnimationStatus.dismissed) {
      _toastAnimController.reverse().then((_) {
        if (mounted && _toastAnimController.value == 0.0) {
          if (_overlayPortalController.isShowing) {
            _overlayPortalController.hide();
          }
          setState(() {
            _activeToastMessage = null;
          });
        }
      });
    }
  }

  void _expandAndDismissToast() {
    _toastTimer?.cancel();
    if (_overlayPortalController.isShowing) {
      _overlayPortalController.hide();
    }
    setState(() {
      _activeToastMessage = null;
      _isExpanded = true;
      _unreadCount = 0;
    });
  }

  void _toggleExpanded() {
    if (!_isExpanded) {
      _expandAndDismissToast();
    } else {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  Future<void> _loadPlayerName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? widget.currentUserId;
      if (uid != null) {
        final player = await _playerRepo.getPlayer(uid);
        if (mounted) {
          setState(() {
            _cachedScreenName =
                player?.screenName ?? user?.displayName ?? 'Anonymous';
          });
        }
      }
    } catch (_) {
      // Firebase not initialized in test environment
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    final uid = user?.uid ?? widget.currentUserId;
    if (uid == null) return;

    final senderName = _cachedScreenName ?? user?.displayName ?? 'Anonymous';
    if (_cachedScreenName == null) {
      _loadPlayerName();
    }

    await _chatRepo.sendMessage(
      gameId: widget.gameId,
      senderId: uid,
      senderName: senderName,
      text: text,
    );
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _toastTimer?.cancel();
    _toastAnimController.dispose();
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final viewInsetsBottom = mediaQuery.viewInsets.bottom;
    final availableHeight =
        screenHeight - viewInsetsBottom - mediaQuery.padding.vertical;
    final maxAllowedExpanded = viewInsetsBottom > 0
        ? (availableHeight * 0.75).clamp(160.0, 260.0)
        : 260.0;
    final defaultExpandedHeight = viewInsetsBottom > 0
        ? (screenHeight * 0.28).clamp(160.0, maxAllowedExpanded)
        : (screenHeight * 0.28).clamp(200.0, 260.0);
    final effectiveExpandedHeight =
        widget.expandedHeight ?? defaultExpandedHeight;

    return OverlayPortal(
      controller: _overlayPortalController,
      overlayChildBuilder: (context) {
        if (_activeToastMessage == null) return const SizedBox.shrink();
        final bottomOffset = (_isExpanded ? effectiveExpandedHeight : 60.0) +
            12.0 +
            mediaQuery.padding.bottom +
            viewInsetsBottom;
        return Positioned(
          bottom: bottomOffset,
          left: 16.0,
          right: 16.0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ChatToastBanner(
                message: _activeToastMessage!,
                onTap: _expandAndDismissToast,
                onDismiss: _dismissToastWithAnimation,
                animation: _toastAnimController,
              ),
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isExpanded ? effectiveExpandedHeight : 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: _toggleExpanded,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Game Chat',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        if (_unreadCount > 0 && !_isExpanded) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Icon(_isExpanded ? Icons.expand_more : Icons.expand_less),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxHeight < 100) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<ChatMessage>>(
                            stream: _chatRepo.watchMessages(widget.gameId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final messages = snapshot.data!;
                              return ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  String? currentUid;
                                  try {
                                    currentUid =
                                        FirebaseAuth.instance.currentUser?.uid;
                                  } catch (_) {}
                                  final isMe = msg.senderId == currentUid;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      msg.senderName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: msg.isAi
                                            ? Colors.purple
                                            : (isMe
                                                ? Colors.blue
                                                : Colors.black),
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
                                  focusNode: _messageFocusNode,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) {
                                    _messageFocusNode.unfocus();
                                  },
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
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
