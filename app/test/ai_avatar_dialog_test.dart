import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/services/avatar_generation_service.dart';
import 'package:pedro/ui/widgets/ai_avatar_dialog.dart';

class MockAvatarGenerationService extends AvatarGenerationService {
  MockAvatarGenerationService({this.onGenerate, this.onUpload});

  final Future<Uint8List> Function(AvatarCategory category, String prompt)? onGenerate;
  final Future<String> Function(String uid, Uint8List bytes, String screenName)? onUpload;

  @override
  Future<Uint8List> generateAvatarBytes({
    required AvatarCategory category,
    required String prompt,
  }) async {
    if (onGenerate != null) {
      return onGenerate!(category, prompt);
    }
    // Return dummy 1x1 transparent png bytes
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
  }

  @override
  Future<String> uploadAndSaveAvatar({
    required String uid,
    required Uint8List imageBytes,
    required String screenName,
  }) async {
    if (onUpload != null) {
      return onUpload!(uid, imageBytes, screenName);
    }
    return 'https://firebasestorage.googleapis.com/v0/b/test/o/avatars%2F${uid}_123.jpg';
  }
}

void main() {
  group('AiAvatarDialog Widget Tests', () {
    testWidgets('renders category segments, suggestion chips, and text field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiAvatarDialog(
              uid: 'user123',
              screenName: 'PlayerOne',
              avatarService: MockAvatarGenerationService(),
            ),
          ),
        ),
      );

      expect(find.text('Generate AI Avatar'), findsOneWidget);
      expect(find.text('Animal'), findsOneWidget);
      expect(find.text('Person'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Lion'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('selecting suggestion chip updates description input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiAvatarDialog(
              uid: 'user123',
              screenName: 'PlayerOne',
              avatarService: MockAvatarGenerationService(),
            ),
          ),
        ),
      );

      expect(find.text('Lion'), findsWidgets);
      await tester.tap(find.text('Fox'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Fox');
    });

    testWidgets('switching to Person shows darker skin tone helper text and person presets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiAvatarDialog(
              uid: 'user123',
              screenName: 'PlayerOne',
              avatarService: MockAvatarGenerationService(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Person'));
      await tester.pumpAndSettle();

      expect(
        find.text('Person avatars are generated as stylized cartoon headshots with darker skin tones.'),
        findsOneWidget,
      );
      expect(find.text('Army woman'), findsWidgets);
    });

    testWidgets('generating avatar displays preview image and Set as Avatar button', (tester) async {
      final mockService = MockAvatarGenerationService();

      String? savedUrl;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiAvatarDialog(
                uid: 'user123',
                screenName: 'PlayerOne',
                avatarService: mockService,
                onAvatarSaved: (url) => savedUrl = url,
              ),
            ),
          ),
        ),
      );

      // Tap generate button
      final generateBtn = find.text('Generate Avatar');
      await tester.ensureVisible(generateBtn);
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      // Preview should now be visible with "Set as Avatar" and "Try Again"
      final setAsAvatarBtn = find.text('Set as Avatar');
      expect(setAsAvatarBtn, findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Scroll and tap Set as Avatar
      await tester.ensureVisible(setAsAvatarBtn);
      await tester.tap(setAsAvatarBtn);
      await tester.pumpAndSettle();

      expect(savedUrl, contains('avatars%2Fuser123_123.jpg'));
    });
  });
}
