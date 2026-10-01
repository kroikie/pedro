import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/ui/widgets/avatar_widget.dart';

void main() {
  group('AvatarWidget', () {
    testWidgets('renders fallback person icon when avatarUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWidget(avatarUrl: null, radius: 24),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders fallback person icon when avatarUrl is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWidget(avatarUrl: '', radius: 24),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders Image.network for external HTTP Google photo URL', (tester) async {
      const googlePhotoUrl = 'https://lh3.googleusercontent.com/a/ACg8ocIExamplePhoto';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWidget(avatarUrl: googlePhotoUrl, radius: 24),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('handles storage URL gracefully without unhandled exception', (tester) async {
      const storageUrl = 'https://firebasestorage.googleapis.com/v0/b/pedro.appspot.com/o/avatars%2Fuser_123.jpg?alt=media';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWidget(avatarUrl: storageUrl, radius: 24),
          ),
        ),
      );

      // In unit test environment without real Firebase connection, it catches and shows error or placeholder without crashing
      expect(tester.takeException(), isNull);
    });
  });
}
