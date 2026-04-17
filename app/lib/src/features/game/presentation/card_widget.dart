import 'package:flutter/material.dart' hide Card;
import '../domain/card.dart' as pedro;

class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.isFaceUp = true,
  });

  final pedro.Card card;
  final VoidCallback? onTap;
  final bool isFaceUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 90,
        decoration: BoxDecoration(
          color: isFaceUp ? Colors.white : Colors.blue[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        child: isFaceUp
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _suitIcon(card.suit),
                  Text(
                    _rankLabel(card.rank),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _suitColor(card.suit),
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(Icons.apps, color: Colors.white.withOpacity(0.5)),
              ),
      ),
    );
  }

  Widget _suitIcon(pedro.Suit suit) {
    IconData icon;
    Color color = _suitColor(suit);
    switch (suit) {
      case pedro.Suit.clubs: icon = Icons.circle; break;
      case pedro.Suit.diamonds: icon = Icons.diamond; break;
      case pedro.Suit.hearts: icon = Icons.favorite; break;
      case pedro.Suit.spades: icon = Icons.architecture; break; // Placeholder for spade
    }
    return Icon(icon, color: color, size: 24);
  }

  Color _suitColor(pedro.Suit suit) {
    return (suit == pedro.Suit.hearts || suit == pedro.Suit.diamonds) ? Colors.red : Colors.black;
  }

  String _rankLabel(pedro.Rank rank) {
    switch (rank) {
      case pedro.Rank.two: return '2';
      case pedro.Rank.three: return '3';
      case pedro.Rank.four: return '4';
      case pedro.Rank.five: return '5';
      case pedro.Rank.six: return '6';
      case pedro.Rank.seven: return '7';
      case pedro.Rank.eight: return '8';
      case pedro.Rank.nine: return '9';
      case pedro.Rank.ten: return '10';
      case pedro.Rank.jack: return 'J';
      case pedro.Rank.queen: return 'Q';
      case pedro.Rank.king: return 'K';
      case pedro.Rank.ace: return 'A';
    }
  }
}
