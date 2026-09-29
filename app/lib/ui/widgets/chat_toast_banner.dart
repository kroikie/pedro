import 'package:flutter/material.dart';
import '../../data/models/chat_message.dart';

class ChatToastBanner extends StatelessWidget {
  const ChatToastBanner({
    super.key,
    required this.message,
    required this.onTap,
    required this.onDismiss,
    required this.animation,
  });

  final ChatMessage message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final isAi = message.isAi || message.senderId == 'ai_narrator';
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: animation,
        child: Dismissible(
          key: ValueKey('chat_toast_${message.id}'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => onDismiss(),
          child: Material(
            color: isAi ? const Color(0xFFF7F2FA) : Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isAi ? Colors.deepPurple.shade300 : Colors.blue.shade300,
                width: 1.5,
              ),
            ),
            shadowColor: Colors.black38,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isAi
                            ? Colors.purple.shade100
                            : Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAi ? Icons.auto_awesome : Icons.person,
                        size: 18,
                        color: isAi
                            ? Colors.purple.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                message.senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isAi
                                      ? Colors.purple.shade900
                                      : Colors.blue.shade900,
                                ),
                              ),
                              if (isAi) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              const Text(
                                'Tap to open',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isAi ? FontWeight.w600 : FontWeight.normal,
                              color: isAi
                                  ? Colors.purple.shade900
                                  : Colors.black87,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon:
                          const Icon(Icons.close, size: 16, color: Colors.grey),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: onDismiss,
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
