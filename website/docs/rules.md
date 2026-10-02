# How to Play Pedro

Welcome to the complete player's guide for **Pedro**! Pedro is an exciting, strategic trick-taking card game played with a standard 52-card deck.

---

## 🎯 The Objective

The goal of Pedro is to be the first player (or team) to reach the target winning score by bidding accurately and capturing high-value trump cards during gameplay lifts.

---

## 🃏 Game Setup & Deal

1. **Players:** Designed for 4 to 8 players.
2. **The Deal:** Each player is dealt an initial hand of cards.
3. **Card Rank:** Standard card ranking applies within suits (Ace is High, 2 is Low).
4. **Hand Organization:** Player hands are automatically organized matching physical card etiquette:
   - **Grouped by Suit:** Cards are clustered by suit in alternating colors (♣ Clubs $\rightarrow$ ♦ Diamonds $\rightarrow$ ♠ Spades $\rightarrow$ ♥ Hearts) to prevent confusing adjacent suits of the same color.
   - **Rank Order:** Within each suit, cards are ordered from lowest rank (2) on the left to highest rank (Ace) on the right.
   - **Suit Separation:** Subtle visual spacing separates distinct suit clusters for effortless, tactile readability.

---

## 🔄 Game Phases

### Phase 1: The Wadger (Bidding)
- Players bid on the number of point cards they predict they can win during the round.
- **Opening Bidder:** The player to the dealer's right starts the bidding. The opening bid must be at least **1** point; the opening bidder cannot pass ("Pass" is disabled).
- **Pass Button Ordering:** The **Pass** option is positioned on the far left of the bid controls for quick, scroll-free access.
- **Auction-Style Pass Elimination:** In turn order, players must either **raise the bid** or **pass**. Once a player passes, they are eliminated from making any further bids in that round. Bidding rotates anti-clockwise exclusively among remaining active bidders until all but the highest bidder have passed.
- The highest bidder wins the Wadger and names the **Trump Suit** for the round.

### Phase 2: Discard & Draw
- Once trump is named, all players return their non-trump cards to the board for replacement.
- The deck is redistributed so each player holds a tight 6-card hand of trumps and high-value cards.
- **Card Replacement Transparency:** The game board displays a `Replaced: X` badge on every player's seat around the table (and in the player info area), revealing exactly how many non-trump cards each player returned for replacement. This provides vital strategic intelligence about how many trumps each player holds.

### Phase 3: Gameplay & Lifts
- The bid winner leads the first card (lift).
- The first card played in each lift defines the **Lead Suit** for that trick. The game board displays cards in the exact order they are played, with a prominent **LEAD** badge and a header indicating the called lead suit.
- Players play one card per turn. You must follow the lead suit if you hold it, or you may play a trump card. Playing an off-suit card while holding the lead suit is an illegal move and will be rejected.
- The highest trump card played wins the lift. If no trump is played, the highest card of the lead suit wins.
- **Lift Review & Board Clearing:** At the end of each lift, all played cards remain on the board with a prominent **WINNER** badge on the winning card, allowing all players a review window to inspect the final card and outcome. The cards stay on the board until the player who won the trick plays their lead card for the next lift, at which point the table clears automatically.
- **Previous Trick History:** Players can tap "View Previous Trick" at any time during gameplay to review the cards played and the winner of the previous trick.
- **Bid Winner & Point Contract Tracking:** 
  - The top-right game header displays the winning bid value, who is responsible for achieving it, and their live point progress (e.g. `Bid: 10 by Alice • 4 / 10 pts`).
  - When the bid winner accumulates enough points to satisfy the contract (`currentRoundPoints >= bidValue`), the indicator highlights in green with a checkmark (`10 / 10 pts ✓`).
  - On the table, the bidder's seat displays a distinct `BIDDER` badge and round progress tracker (`Pts: 4 / 10`), allowing all players to monitor whether the bidder will achieve their contract or suffer a set penalty.
- The winner of the lift leads the next trick.

---

## 🏆 Scoring & Point Cards

Points are scored by playing or capturing specific high-value cards during the round:

| Point Card | Points | Description |
| :--- | :--- | :--- |
| **High Trump** | **1 Point** | Awarded to the player who played the highest trump card in the round ("High till higher comes"). Ace of Trumps locks this permanently. |
| **Low Trump** | **1 Point** | Awarded to the player who played the lowest trump card in the round ("Low till lower comes"). 2 of Trumps locks this permanently. |
| **Jack of Trumps** | **1 to 3 Points** | 1 point if saved/won by the player who played it; 3 bonus points ("Hang Jack") if captured by an opponent! |
| **5 of Trumps (Pedro)** | **5 Points** | The famous Pedro card—worth a massive 5 points! Captured in the winning lift. |
| **9 of Trumps** | **9 Points** | The highest single point value card in the game! Captured in the winning lift. |
| **Game Point** | **1 Point** | Awarded to the player with the highest total face card values in captured lifts across the round (10=10, Jack=1, Queen=2, King=3, Ace=4). |

### Dynamic High & Low Mechanics ("Low Till Lower Comes")
In Pedro, **High** and **Low** are dynamic points assessed across all lifts in the round:
- When a player plays the first trump card of the round, they temporarily hold both High and Low claims.
- **"High till higher comes"**: If another player plays a higher trump in any subsequent lift, the High point and badge immediately transfer to that player. Playing the Ace of trumps permanently secures High for the round.
- **"Low till lower comes"**: If another player plays a lower trump in any subsequent lift, the Low point and badge immediately transfer to that player. Playing the 2 of trumps permanently secures Low for the round.
- Unlike 5, 9, or Jack (which are captured by the winner of the lift), the player who **plays** High or Low retains the point even if they lose the lift—provided no higher or lower trump is played later in the round.

---

## 💡 Player Tips & Strategy

- **Use the AI Bid Assistant:** When you're unsure about your hand, consult the in-game Bid Assistant for confidence scores and recommendations.
- **Protect the 5 of Trumps:** The 5 of Trumps (Pedro) is worth 5 points—don't lose it to an opponent's higher trump!
- **Watch the Chat Narrator:** Pay attention to the live AI Narrator in chat for real-time game commentary and tactical updates.
