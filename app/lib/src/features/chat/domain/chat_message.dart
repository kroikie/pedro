import 'package:dart_mappable/dart_mappable.dart';

part 'chat_message.mapper.dart';

@MappableClass()
class ChatMessage with ChatMessageMappable {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isAi;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isAi = false,
  });

  static const fromMap = ChatMessageMapper.fromMap;
}
