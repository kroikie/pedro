import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    test('NotificationService singleton returns consistent instance', () {
      final service1 = NotificationService();
      final service2 = NotificationService.instance;
      expect(identical(service1, service2), isTrue);
    });

    test('setActiveGame updates activeGameId tracking correctly', () {
      final service = NotificationService.instance;
      expect(service.activeGameId, isNull);

      service.setActiveGame('test-game-123');
      expect(service.activeGameId, equals('test-game-123'));

      service.setActiveGame(null);
      expect(service.activeGameId, isNull);
    });
  });
}
