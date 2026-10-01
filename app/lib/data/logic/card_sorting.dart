import '../models/card.dart';

/// Strategy for positioning the active trump suit when sorting a hand.
enum TrumpPosition {
  /// Maintain the standard alternating color suit order across all phases.
  none,

  /// Move the trump suit to the far left (first).
  left,

  /// Move the trump suit to the far right (last).
  right,
}

/// Standard suit display order alternating colors:
/// Clubs ♣ (Black) -> Diamonds ♦ (Red) -> Spades ♠ (Black) -> Hearts ♥ (Red).
///
/// This prevents adjacent suits of the same color from causing visual confusion.
const List<Suit> defaultSuitOrder = [
  Suit.clubs,
  Suit.diamonds,
  Suit.spades,
  Suit.hearts,
];

/// Sorts a player's [hand] by grouping cards by suit, and within each suit,
/// ordering ranks strictly from lowest (Rank.two) to highest (Rank.ace).
///
/// When rendered left-to-right, cards appear lowest on the left and highest on the right.
///
/// By default, [trumpPosition] is [TrumpPosition.none], which preserves the stable
/// [defaultSuitOrder] across all game phases.
List<Card> sortHand(
  List<Card> hand, {
  Suit? trumpSuit,
  TrumpPosition trumpPosition = TrumpPosition.none,
  List<Suit> suitOrder = defaultSuitOrder,
}) {
  if (hand.length <= 1) return List<Card>.from(hand);

  final List<Suit> effectiveSuitOrder = List<Suit>.from(suitOrder);
  if (trumpSuit != null && trumpPosition != TrumpPosition.none) {
    effectiveSuitOrder.remove(trumpSuit);
    if (trumpPosition == TrumpPosition.left) {
      effectiveSuitOrder.insert(0, trumpSuit);
    } else if (trumpPosition == TrumpPosition.right) {
      effectiveSuitOrder.add(trumpSuit);
    }
  }

  final sorted = List<Card>.from(hand);
  sorted.sort((a, b) {
    final aSuitIndex = effectiveSuitOrder.indexOf(a.suit);
    final bSuitIndex = effectiveSuitOrder.indexOf(b.suit);
    final effectiveASuit = aSuitIndex == -1 ? 999 : aSuitIndex;
    final effectiveBSuit = bSuitIndex == -1 ? 999 : bSuitIndex;

    if (effectiveASuit != effectiveBSuit) {
      return effectiveASuit.compareTo(effectiveBSuit);
    }
    // Same suit: order rank from lowest (left) to highest (right)
    return a.rank.index.compareTo(b.rank.index);
  });

  return sorted;
}

/// Extension providing convenient sorting on card lists.
extension CardSortingX on List<Card> {
  /// Returns a new list containing the cards sorted by suit and rank.
  List<Card> sortedHand({
    Suit? trumpSuit,
    TrumpPosition trumpPosition = TrumpPosition.none,
    List<Suit> suitOrder = defaultSuitOrder,
  }) {
    return sortHand(
      this,
      trumpSuit: trumpSuit,
      trumpPosition: trumpPosition,
      suitOrder: suitOrder,
    );
  }
}
