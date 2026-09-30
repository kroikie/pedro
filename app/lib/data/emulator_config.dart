import 'package:flutter/foundation.dart';

/// Resolves whether the application should connect to the local Firebase emulator suite.
///
/// Can be overridden via `--dart-define=USE_EMULATOR=true|false`.
/// By default, emulators are enabled during debug mode and disabled in release builds.
bool shouldConnectToFirebaseEmulator({
  bool isDebugMode = kDebugMode,
  bool isReleaseMode = kReleaseMode,
}) {
  const bool hasEnv = bool.hasEnvironment('USE_EMULATOR');
  if (hasEnv) {
    return const bool.fromEnvironment('USE_EMULATOR');
  }
  return isDebugMode && !isReleaseMode;
}

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
