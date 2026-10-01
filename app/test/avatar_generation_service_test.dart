import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/services/avatar_generation_service.dart';

void main() {
  group('AvatarGenerationService Prompt Engineering', () {
    late AvatarGenerationService service;

    setUp(() {
      service = AvatarGenerationService();
    });

    test('builds animal cartoon prompt with description and style directives', () {
      final prompt = service.buildPrompt(AvatarCategory.animal, 'a majestic lion');
      expect(prompt, contains('cartoon avatar'));
      expect(prompt, contains('a majestic lion'));
      expect(prompt, contains('stylized vector illustration'));
      expect(prompt, contains('circular frame'));
    });

    test('builds person cartoon headshot prompt with darker skin tone directives', () {
      final prompt = service.buildPrompt(AvatarCategory.person, 'army woman');
      expect(prompt, contains('cartoon headshot avatar'));
      expect(prompt, contains('army woman'));
      expect(prompt, contains('dark skin tone'));
      expect(prompt, contains('deep melanin'));
      expect(prompt, contains('rich brown complexion'));
      expect(prompt, contains('circular profile badge'));
    });

    test('trims whitespace from input description', () {
      final prompt = service.buildPrompt(AvatarCategory.animal, '   cute fox   ');
      expect(prompt, contains('cute fox,'));
      expect(prompt, isNot(contains('   cute fox   ')));
    });
  });
}
