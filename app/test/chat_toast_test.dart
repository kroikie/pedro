import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/chat_message.dart';
import 'package:pedro/data/repositories/chat_repository.dart';
import 'package:pedro/ui/widgets/chat_overlay.dart';
import 'package:pedro/ui/widgets/chat_toast_banner.dart';

class FakeChatRepository implements ChatRepository {
  final _controller = StreamController<List<ChatMessage>>.broadcast();
  final List<ChatMessage> sentMessages = [];

  void emitMessages(List<ChatMessage> messages) {
    _controller.add(messages);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String gameId) {
    return _controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String gameId,
    required String senderId,
    required String senderName,
    required String text,
    bool isAi = false,
  }) async {
    final msg = ChatMessage(
      id: 'sent_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      isAi: isAi,
    );
    sentMessages.add(msg);
    _controller.add([msg, ...sentMessages]);
  }
}

void main() {
  group('ChatToastBanner Widget', () {
    testWidgets('Displays AI Narrator styling and badge correctly',
        (tester) async {
      bool tapped = false;
      bool dismissed = false;

      final message = ChatMessage(
        id: 'msg_1',
        senderId: 'ai_narrator',
        senderName: 'AI Narrator',
        text: 'Dat is ah brave bid de Arthur!',
        timestamp: DateTime.now(),
        isAi: true,
      );

      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      )..value = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatToastBanner(
              message: message,
              onTap: () => tapped = true,
              onDismiss: () => dismissed = true,
              animation: animController,
            ),
          ),
        ),
      );

      expect(find.text('AI Narrator'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Dat is ah brave bid de Arthur!'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      await tester.tap(find.text('Dat is ah brave bid de Arthur!'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('Displays player message styling correctly', (tester) async {
      final message = ChatMessage(
        id: 'msg_2',
        senderId: 'player_123',
        senderName: 'Arthur',
        text: 'Lardits, watch that trump!',
        timestamp: DateTime.now(),
        isAi: false,
      );

      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      )..value = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatToastBanner(
              message: message,
              onTap: () {},
              onDismiss: () {},
              animation: animController,
            ),
          ),
        ),
      );

      expect(find.text('Arthur'), findsOneWidget);
      expect(find.text('Lardits, watch that trump!'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('AI'), findsNothing);
    });
  });

  group('ChatOverlay with Toast and Unread Counter', () {
    testWidgets('New message shows toast and unread badge when collapsed',
        (tester) async {
      final fakeRepo = FakeChatRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatOverlay(
              gameId: 'game_test',
              chatRepository: fakeRepo,
            ),
          ),
        ),
      );

      // Initial load: 1 historical message should not trigger toast
      fakeRepo.emitMessages([
        ChatMessage(
          id: 'hist_1',
          senderId: 'player_0',
          senderName: 'Bob',
          text: 'Old message',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ]);
      await tester.pump();

      expect(find.text('Old message'), findsNothing);
      expect(find.text('1'), findsNothing);

      // New incoming message while collapsed
      fakeRepo.emitMessages([
        ChatMessage(
          id: 'new_1',
          senderId: 'ai_narrator',
          senderName: 'AI Narrator',
          text: 'Oh gosh! Arthur does play card for gramoxone!',
          timestamp: DateTime.now(),
          isAi: true,
        ),
        ChatMessage(
          id: 'hist_1',
          senderId: 'player_0',
          senderName: 'Bob',
          text: 'Old message',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Toast appears over UI
      expect(find.text('Oh gosh! Arthur does play card for gramoxone!'),
          findsOneWidget);
      // Unread count badge shows 1
      expect(find.text('1'), findsOneWidget);

      // Tapping toast opens the chat and dismisses toast
      await tester.tap(find.byType(ChatToastBanner));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Badge is cleared
      expect(find.text('1'), findsNothing);
      // Chat input field is visible
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
