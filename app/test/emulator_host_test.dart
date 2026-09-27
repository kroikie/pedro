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
}
