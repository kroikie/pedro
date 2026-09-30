import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/functions_config.dart';

void main() {
  group('resolveFunctionUrl', () {
    test('resolves default Cloud Run URL with expected project number and region', () {
      final url = resolveFunctionUrl('create-game');
      expect(url, 'https://create-game-260654198138.us-central1.run.app');
    });

    test('resolves all game and lobby callable function endpoints correctly', () {
      const endpoints = [
        'create-game',
        'join-game',
        'invite-player',
        'uninvite-player',
        'start-game',
        'submit-bid',
        'set-trump-suit',
        'play-card',
        'call-player',
      ];

      for (final endpoint in endpoints) {
        expect(
          resolveFunctionUrl(endpoint),
          'https://$endpoint-260654198138.us-central1.run.app',
        );
      }
    });

    test('supports custom project numbers and regions', () {
      final customUrl = resolveFunctionUrl(
        'custom-function',
        projectNumber: '123456789012',
        region: 'us-east1',
      );
      expect(customUrl, 'https://custom-function-123456789012.us-east1.run.app');
    });
  });

  group('constants', () {
    test('default constants match production deployment', () {
      expect(defaultFunctionsProjectNumber, '260654198138');
      expect(defaultFunctionsRegion, 'us-central1');
    });
  });
}
