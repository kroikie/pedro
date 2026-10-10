import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static const String defaultBugFixesNote =
      'Bug fixes and stability improvements.';

  static const List<String> latestReleaseNotes = [
    'Sleeping trump cards (A, 2, J, 5, 9) shown in round summaries.',
    'Hall of Fame, Hall of Shame, and head-to-head rivalries.',
    'Live Wadger bids on seat cards and color-coded point pips.',
    'Automatic no under-trumping rule validation.',
  ];

  AppInfoService({
    PackageInfo? packageInfo,
    FirebaseAppCheck? appCheck,
    List<String>? releaseNotes,
  })  : _packageInfo = packageInfo,
        _appCheck = appCheck,
        _releaseNotes = releaseNotes;

  PackageInfo? _packageInfo;
  final FirebaseAppCheck? _appCheck;
  final List<String>? _releaseNotes;

  /// Returns the "What's New" items for the latest release.
  ///
  /// Falls back to [defaultBugFixesNote] when there are no user-facing changes.
  List<String> getReleaseNotes({List<String>? overrideNotes}) {
    final rawNotes = overrideNotes ?? _releaseNotes ?? latestReleaseNotes;
    final notes = rawNotes
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList(growable: false);
    if (notes.isEmpty) {
      return const [defaultBugFixesNote];
    }
    return notes;
  }

  Future<PackageInfo> getPackageInfo() async {
    if (_packageInfo != null) return _packageInfo!;
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      return _packageInfo!;
    } catch (e) {
      debugPrint('Error getting package info: $e');
      return PackageInfo(
        appName: 'Pedro',
        packageName: 'com.ool.pedro',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
        installerStore: null,
      );
    }
  }

  Future<String> getFormattedVersion() async {
    final info = await getPackageInfo();
    final version = info.version.isNotEmpty ? info.version : '1.0.0';
    final buildNumber = info.buildNumber.isNotEmpty ? info.buildNumber : '1';
    return 'Pedro v$version ($buildNumber)';
  }

  Future<String> getDiagnosticsInfo({
    String? userId,
    String? gameId,
    bool forceRefresh = true,
  }) async {
    final info = await getPackageInfo();
    final platformName = kIsWeb
        ? 'Web (${defaultTargetPlatform.name})'
        : defaultTargetPlatform.name;
    final buffer = StringBuffer();
    buffer.writeln(
      'App: ${info.appName.isNotEmpty ? info.appName : "Pedro"} v${info.version} (Build ${info.buildNumber})',
    );
    buffer.writeln('Package: ${info.packageName}');
    buffer.writeln('Platform: $platformName');
    if (userId != null && userId.isNotEmpty) {
      buffer.writeln('User ID: $userId');
    }
    if (gameId != null && gameId.isNotEmpty) {
      buffer.writeln('Game ID: $gameId');
    }
    try {
      final appCheck = _appCheck ?? FirebaseAppCheck.instance;
      final token = await appCheck.getToken(forceRefresh);
      if (token != null && token.isNotEmpty) {
        buffer.writeln(
          'App Check: Token active (${token.length} chars${forceRefresh ? ", fresh" : ", cached"})',
        );
      } else {
        buffer.writeln(
          'App Check: No token returned${forceRefresh ? " (fresh)" : ""}',
        );
      }
    } catch (e) {
      buffer.writeln('App Check: $e');
    }
    return buffer.toString().trim();
  }

  /// Explicitly tests App Check attestation by forcing a fresh token roundtrip.
  Future<String> testAppCheckAttestation({bool forceRefresh = true}) async {
    try {
      final appCheck = _appCheck ?? FirebaseAppCheck.instance;
      final token = await appCheck.getToken(forceRefresh);
      if (token != null && token.isNotEmpty) {
        return 'App Check attestation succeeded: token active (${token.length} chars${forceRefresh ? ", live refreshed" : ""})';
      }
      return 'App Check attestation returned null or empty token.';
    } catch (e) {
      return 'App Check attestation failed: $e';
    }
  }
}
