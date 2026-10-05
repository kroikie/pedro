import 'package:flutter/material.dart';

/// Holds background, foreground, and dot colors for a Pedro point badge.
class PointBadgeColors {
  final Color backgroundColor;
  final Color textColor;
  final Color dotColor;

  const PointBadgeColors({
    required this.backgroundColor,
    required this.textColor,
    required this.dotColor,
  });
}

/// Central helper for Pedro point types, colors, and badge styling.
///
/// Follows distinct circle colors:
/// - 🔵 High: Sky Blue (Colors.lightBlue)
/// - ⚫ Low: Deep Indigo (Colors.indigo)
/// - 🟠 Jack: Orange (Colors.orange)
/// - 🔴 Hang Jack: Red (Colors.red)
/// - 🟢 5 of Trump: Green (Colors.green)
/// - 🟣 9 of Trump: Purple (Colors.purple)
/// - 🟡 Game: Amber (Colors.amber)
class PointColorHelper {
  /// Returns the solid circle dot color for the given point.
  static Color getDotColor(String point) {
    switch (point) {
      case 'High':
        return Colors.lightBlue;
      case 'Low':
        return Colors.indigo.shade800;
      case 'Jack':
        return Colors.orange.shade700;
      case 'Hang Jack':
        return Colors.red.shade700;
      case '5':
      case 'Pedro':
        return Colors.green.shade600;
      case '9':
        return Colors.purple.shade600;
      case 'Game':
        return Colors.amber.shade700;
      case 'Pass':
        return Colors.grey.shade600;
      default:
        if (point.startsWith('Bid:')) {
          return Colors.orange.shade800;
        }
        return Colors.blue.shade700;
    }
  }

  /// Returns background, text, and dot colors for point chip badges.
  static PointBadgeColors getBadgeColors(String point) {
    switch (point) {
      case 'High':
        return PointBadgeColors(
          backgroundColor: Colors.lightBlue.shade100,
          textColor: Colors.lightBlue.shade900,
          dotColor: Colors.lightBlue,
        );
      case 'Low':
        return PointBadgeColors(
          backgroundColor: Colors.indigo.shade100,
          textColor: Colors.indigo.shade900,
          dotColor: Colors.indigo.shade800,
        );
      case 'Jack':
        return PointBadgeColors(
          backgroundColor: Colors.orange.shade100,
          textColor: Colors.orange.shade900,
          dotColor: Colors.orange.shade700,
        );
      case 'Hang Jack':
        return PointBadgeColors(
          backgroundColor: Colors.red.shade100,
          textColor: Colors.red.shade900,
          dotColor: Colors.red.shade700,
        );
      case '5':
      case 'Pedro':
        return PointBadgeColors(
          backgroundColor: Colors.green.shade100,
          textColor: Colors.green.shade900,
          dotColor: Colors.green.shade600,
        );
      case '9':
        return PointBadgeColors(
          backgroundColor: Colors.purple.shade100,
          textColor: Colors.purple.shade900,
          dotColor: Colors.purple.shade600,
        );
      case 'Game':
        return PointBadgeColors(
          backgroundColor: Colors.amber.shade200,
          textColor: Colors.amber.shade900,
          dotColor: Colors.amber.shade700,
        );
      case 'Pass':
        return PointBadgeColors(
          backgroundColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
          dotColor: Colors.grey.shade600,
        );
      default:
        if (point.startsWith('Bid:')) {
          return PointBadgeColors(
            backgroundColor: Colors.orange.shade100,
            textColor: Colors.orange.shade900,
            dotColor: Colors.orange.shade800,
          );
        }
        return PointBadgeColors(
          backgroundColor: Colors.blue.shade100,
          textColor: Colors.blue.shade900,
          dotColor: Colors.blue.shade700,
        );
    }
  }

  /// Returns user-friendly description and point value.
  static String getPointDescription(String point) {
    switch (point) {
      case 'High':
        return 'Highest trump played (1 pt)';
      case 'Low':
        return 'Lowest trump played (1 pt)';
      case 'Jack':
        return 'Saved Jack of trump (1 pt)';
      case 'Hang Jack':
        return 'Stole opponent\'s Jack of trump (3 pts)';
      case '5':
      case 'Pedro':
        return '5 of trump captured (5 pts)';
      case '9':
        return '9 of trump captured (9 pts)';
      case 'Game':
        return 'Most cards of value captured (1 pt)';
      default:
        return point;
    }
  }

  /// Returns numeric point value.
  static int getPointValue(String point) {
    switch (point) {
      case 'High':
      case 'Low':
      case 'Jack':
      case 'Game':
        return 1;
      case 'Hang Jack':
        return 3;
      case '5':
      case 'Pedro':
        return 5;
      case '9':
        return 9;
      default:
        return 0;
    }
  }
}
