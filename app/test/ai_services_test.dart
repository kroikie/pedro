import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart';
import 'package:pedro/data/services/bid_assistant_service.dart';
import 'package:pedro/data/services/game_name_service.dart';
import 'package:pedro/data/services/tactical_coach_service.dart';

void main() {
  group('AI Services Graceful Fallbacks (gemini-3.5-flash-lite)', () {
    test('BidAssistantService returns fallback when offline/uninitialized', () async {
      final service = BidAssistantService();
      final result = await service.getBidSuggestion([
        Card(suit: Suit.hearts, rank: Rank.ace),
        Card(suit: Suit.hearts, rank: Rank.jack),
      ]);
      expect(result, equals('AI coach is offline.'));
    });

    test('GameNameService returns fallback when offline/uninitialized', () async {
      final service = GameNameService();
      final result = await service.generateRoomName();
      expect(result, equals('lucky_player'));
    });

    test('TacticalCoachService returns fallback when offline/uninitialized', () async {
      final service = TacticalCoachService();
      final result = await service.getMoveSuggestion(
        hand: [Card(suit: Suit.hearts, rank: Rank.five)],
        currentLift: null,
        trumpSuit: Suit.hearts,
        playedCards: [],
      );
      expect(result, equals('AI coach is thinking...'));
    });
  });
}
