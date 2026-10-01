import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService({
    PackageInfo? packageInfo,
    FirebaseAppCheck? appCheck,
  })  : _packageInfo = packageInfo,
        _appCheck = appCheck;

  PackageInfo? _packageInfo;
  final FirebaseAppCheck? _appCheck;

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

  Future<String> getDiagnosticsInfo({String? userId, String? gameId}) async {
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
      final token = await appCheck.getToken();
      if (token != null && token.isNotEmpty) {
        buffer.writeln('App Check: Token active');
      } else {
        buffer.writeln('App Check: No token returned');
      }
    } catch (e) {
      buffer.writeln('App Check: $e');
    }
    return buffer.toString().trim();
  }
}
