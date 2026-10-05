import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/ui/widgets/point_color_helper.dart';

void main() {
  group('PointColorHelper', () {
    test('returns correct dot colors matching design specs', () {
      expect(PointColorHelper.getDotColor('High'), equals(Colors.lightBlue));
      expect(PointColorHelper.getDotColor('Low'), equals(Colors.indigo.shade800));
      expect(PointColorHelper.getDotColor('Jack'), equals(Colors.orange.shade700));
      expect(PointColorHelper.getDotColor('Hang Jack'), equals(Colors.red.shade700));
      expect(PointColorHelper.getDotColor('5'), equals(Colors.green.shade600));
      expect(PointColorHelper.getDotColor('Pedro'), equals(Colors.green.shade600));
      expect(PointColorHelper.getDotColor('9'), equals(Colors.purple.shade600));
      expect(PointColorHelper.getDotColor('Game'), equals(Colors.amber.shade700));
      // Fallback
      expect(PointColorHelper.getDotColor('Unknown'), equals(Colors.blue.shade700));
    });

    test('returns correct badge colors', () {
      final highBadge = PointColorHelper.getBadgeColors('High');
      expect(highBadge.backgroundColor, equals(Colors.lightBlue.shade100));
      expect(highBadge.textColor, equals(Colors.lightBlue.shade900));

      final lowBadge = PointColorHelper.getBadgeColors('Low');
      expect(lowBadge.backgroundColor, equals(Colors.indigo.shade100));
      expect(lowBadge.textColor, equals(Colors.indigo.shade900));

      final jackBadge = PointColorHelper.getBadgeColors('Jack');
      expect(jackBadge.backgroundColor, equals(Colors.orange.shade100));
      expect(jackBadge.textColor, equals(Colors.orange.shade900));

      final hangJackBadge = PointColorHelper.getBadgeColors('Hang Jack');
      expect(hangJackBadge.backgroundColor, equals(Colors.red.shade100));
      expect(hangJackBadge.textColor, equals(Colors.red.shade900));

      final fiveBadge = PointColorHelper.getBadgeColors('5');
      expect(fiveBadge.backgroundColor, equals(Colors.green.shade100));
      expect(fiveBadge.textColor, equals(Colors.green.shade900));

      final nineBadge = PointColorHelper.getBadgeColors('9');
      expect(nineBadge.backgroundColor, equals(Colors.purple.shade100));
      expect(nineBadge.textColor, equals(Colors.purple.shade900));

      final gameBadge = PointColorHelper.getBadgeColors('Game');
      expect(gameBadge.backgroundColor, equals(Colors.amber.shade200));
      expect(gameBadge.textColor, equals(Colors.amber.shade900));

      final passBadge = PointColorHelper.getBadgeColors('Pass');
      expect(passBadge.backgroundColor, equals(Colors.grey.shade300));
      expect(passBadge.textColor, equals(Colors.grey.shade700));
    });

    test('returns accurate descriptions and point values', () {
      expect(PointColorHelper.getPointDescription('High'), contains('Highest trump played'));
      expect(PointColorHelper.getPointValue('High'), equals(1));

      expect(PointColorHelper.getPointDescription('Low'), contains('Lowest trump played'));
      expect(PointColorHelper.getPointValue('Low'), equals(1));

      expect(PointColorHelper.getPointDescription('Jack'), contains('Jack of trump'));
      expect(PointColorHelper.getPointValue('Jack'), equals(1));

      expect(PointColorHelper.getPointDescription('Hang Jack'), contains('Jack of trump'));
      expect(PointColorHelper.getPointValue('Hang Jack'), equals(3));

      expect(PointColorHelper.getPointDescription('5'), contains('5 of trump captured'));
      expect(PointColorHelper.getPointValue('5'), equals(5));

      expect(PointColorHelper.getPointDescription('9'), contains('9 of trump captured'));
      expect(PointColorHelper.getPointValue('9'), equals(9));

      expect(PointColorHelper.getPointDescription('Game'), contains('Most cards of value'));
      expect(PointColorHelper.getPointValue('Game'), equals(1));
    });
  });
}
