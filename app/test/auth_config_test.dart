import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/auth_config.dart';

void main() {
  group('buildAppAuthProviders', () {
    test('configures EmailAuthProvider and GoogleProvider with correct settings', () {
      final providers = buildAppAuthProviders();

      expect(providers.length, 2);
      expect(providers[0], isA<EmailAuthProvider>());
      expect(providers[1], isA<GoogleProvider>());

      final googleProvider = providers[1] as GoogleProvider;
      expect(googleProvider.clientId, kGoogleWebClientId);
      expect(googleProvider.iOSPreferPlist, isTrue);
    });

    test('supports custom overrides if provided', () {
      final providers = buildAppAuthProviders(
        googleClientId: 'custom-client-id.apps.googleusercontent.com',
        iOSPreferPlist: false,
      );

      final googleProvider = providers[1] as GoogleProvider;
      expect(googleProvider.clientId, 'custom-client-id.apps.googleusercontent.com');
      expect(googleProvider.iOSPreferPlist, isFalse);
    });
  });
}
