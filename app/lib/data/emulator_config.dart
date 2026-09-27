import 'package:flutter/foundation.dart';

/// Resolves the Firebase emulator host based on the current platform.
///
/// Android emulators use 10.0.2.2 to reach the host machine loopback.
/// iOS simulator, desktop, and web connect directly via localhost.
String resolveEmulatorHost({bool isWeb = kIsWeb, TargetPlatform? platform}) {
  final targetPlatform = platform ?? defaultTargetPlatform;
  return (!isWeb && targetPlatform == TargetPlatform.android)
      ? '10.0.2.2'
      : 'localhost';
}
