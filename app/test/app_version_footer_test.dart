import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedro/data/services/app_info_service.dart';
import 'package:pedro/ui/widgets/app_version_footer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppInfoService mockService;
  final List<MethodCall> platformCalls = [];

  setUp(() {
    platformCalls.clear();
    mockService = AppInfoService(
      packageInfo: PackageInfo(
        appName: 'Pedro',
        packageName: 'com.ool.pedro',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
        installerStore: null,
      ),
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      if (call.method == 'Clipboard.setData') {
        return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget buildTestWidget({Widget? child}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: child ??
              AppVersionFooter(
                appInfoService: mockService,
                userId: 'user-123',
                gameId: 'game-456',
              ),
        ),
      ),
    );
  }

  group('AppVersionFooter Widget', () {
    testWidgets('renders formatted version text from service', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pedro v1.2.3 (42)'), findsOneWidget);
    });

    testWidgets('tap copies version to clipboard and shows SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pedro v1.2.3 (42)'));
      await tester.pumpAndSettle();

      expect(find.text('App version copied to clipboard'), findsOneWidget);

      final clipboardCall = platformCalls.firstWhere(
        (c) => c.method == 'Clipboard.setData',
      );
      expect(
        (clipboardCall.arguments as Map)['text'],
        'Pedro v1.2.3 (42)',
      );
    });

    testWidgets('long press copies diagnostic details and shows SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Pedro v1.2.3 (42)'));
      await tester.pumpAndSettle();

      expect(
        find.text('Diagnostic details copied to clipboard'),
        findsOneWidget,
      );

      final clipboardCall = platformCalls.firstWhere(
        (c) => c.method == 'Clipboard.setData',
      );
      final text = (clipboardCall.arguments as Map)['text'] as String;
      expect(text, contains('App: Pedro v1.2.3 (Build 42)'));
      expect(text, contains('User ID: user-123'));
      expect(text, contains('Game ID: game-456'));
    });
  });

  group('showPedroAboutDialog', () {
    testWidgets('displays about dialog with version and diagnostics button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showPedroAboutDialog(
                  context,
                  gameId: 'game-789',
                  appInfoService: mockService,
                ),
                child: const Text('Open About'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open About'));
      await tester.pumpAndSettle();

      expect(find.text('Pedro'), findsOneWidget);
      expect(find.text('v1.2.3 (Build 42)'), findsOneWidget);
      expect(find.text('Copy Diagnostics'), findsOneWidget);
      expect(find.text('Test Attestation (Live)'), findsOneWidget);

      // Tap Copy Diagnostics inside dialog
      await tester.tap(find.text('Copy Diagnostics'));
      await tester.pumpAndSettle();

      expect(
        find.text('Diagnostic details copied to clipboard'),
        findsOneWidget,
      );

      // Tap Test Attestation (Live) inside dialog
      await tester.tap(find.text('Test Attestation (Live)'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('App Check attestation'),
        findsOneWidget,
      );
    });
  });
}
