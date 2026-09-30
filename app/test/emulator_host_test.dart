import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/emulator_config.dart';

void main() {
  group('resolveEmulatorHost', () {
    test('returns 10.0.2.2 for Android when not on web', () {
      final host = resolveEmulatorHost(
        isWeb: false,
        platform: TargetPlatform.android,
      );
      expect(host, '10.0.2.2');
    });

    test('returns localhost for iOS simulator when not on web', () {
      final host = resolveEmulatorHost(
        isWeb: false,
        platform: TargetPlatform.iOS,
      );
      expect(host, 'localhost');
    });

    test('returns localhost for macOS desktop when not on web', () {
      final host = resolveEmulatorHost(
        isWeb: false,
        platform: TargetPlatform.macOS,
      );
      expect(host, 'localhost');
    });

    test('returns localhost for Web environment regardless of platform', () {
      final webAndroidHost = resolveEmulatorHost(
        isWeb: true,
        platform: TargetPlatform.android,
      );
      expect(webAndroidHost, 'localhost');

      final webIosHost = resolveEmulatorHost(
        isWeb: true,
        platform: TargetPlatform.iOS,
      );
      expect(webIosHost, 'localhost');
    });
  });

  group('shouldConnectToFirebaseEmulator', () {
    test('enables emulators during debug mode when not in release mode', () {
      final shouldUse = shouldConnectToFirebaseEmulator(
        isDebugMode: true,
        isReleaseMode: false,
      );
      expect(shouldUse, isTrue);
    });

    test('disables emulators during release mode even if debug flag is true', () {
      final shouldUse = shouldConnectToFirebaseEmulator(
        isDebugMode: true,
        isReleaseMode: true,
      );
      expect(shouldUse, isFalse);
    });

    test('disables emulators when both debug and release flags are false', () {
      final shouldUse = shouldConnectToFirebaseEmulator(
        isDebugMode: false,
        isReleaseMode: false,
      );
      expect(shouldUse, isFalse);
    });
  });
}
