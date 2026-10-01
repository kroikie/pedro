import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedro/data/services/app_info_service.dart';

void main() {
  group('AppInfoService', () {
    test('returns formatted version string with version and build number', () async {
      final mockInfo = PackageInfo(
        appName: 'Pedro',
        packageName: 'com.ool.pedro',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
        installerStore: null,
      );
      final service = AppInfoService(packageInfo: mockInfo);

      final formatted = await service.getFormattedVersion();
      expect(formatted, 'Pedro v1.2.3 (42)');
    });

    test('generates complete diagnostic payload with userId and gameId', () async {
      final mockInfo = PackageInfo(
        appName: 'Pedro',
        packageName: 'com.ool.pedro',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
        installerStore: null,
      );
      final service = AppInfoService(packageInfo: mockInfo);

      final diag = await service.getDiagnosticsInfo(
        userId: 'user_xyz_123',
        gameId: 'game_abc_789',
      );

      expect(diag, contains('App: Pedro v1.2.3 (Build 42)'));
      expect(diag, contains('Package: com.ool.pedro'));
      expect(diag, contains('Platform:'));
      expect(diag, contains('User ID: user_xyz_123'));
      expect(diag, contains('Game ID: game_abc_789'));
    });

    test('omits optional userId and gameId when not provided', () async {
      final mockInfo = PackageInfo(
        appName: 'Pedro',
        packageName: 'com.ool.pedro',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
        installerStore: null,
      );
      final service = AppInfoService(packageInfo: mockInfo);

      final diag = await service.getDiagnosticsInfo();

      expect(diag, contains('App: Pedro v1.0.0 (Build 1)'));
      expect(diag, contains('Package: com.ool.pedro'));
      expect(diag, isNot(contains('User ID:')));
      expect(diag, isNot(contains('Game ID:')));
    });

    test('falls back gracefully to default values when version or build are empty', () async {
      final mockInfo = PackageInfo(
        appName: '',
        packageName: 'com.ool.pedro',
        version: '',
        buildNumber: '',
        buildSignature: '',
        installerStore: null,
      );
      final service = AppInfoService(packageInfo: mockInfo);

      final formatted = await service.getFormattedVersion();
      expect(formatted, 'Pedro v1.0.0 (1)');
    });
  });
}
