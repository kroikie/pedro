# Overview
Pedro is a multi player card game. It is played with a standard 52 card deck. The game is played in rounds. Each round has two phases
the wadger phase (or betting phase) and the game play phase. An arbitrary point total is set as the goal and the first player to reach
that goal wins.

# Wadger (betting) Phase
In the wadger phase, players bid on the number of points they think they will accumulate during the game play phase. The player to the dealer's right starts the bidding, the initial bid must be at least 1 point. Each subsequent player in anti-clockwise order may either increase the bid or pass. After all but the player with the highest bid have passed, the winner of the wadger phase chooses the trump suit. All players return their non trump cards to the board. The returned cards are shuffeled and returned to the bottom of the deck.

From the deck the dealer deals cards to the players in anti-clockwise order starting with the play that won the wadger phase. Each player gets the number of cards to make the total number of cards in their hand 6. The remaining cards are placed face down on the board.

The number of cards players use to bid is determined by the number of players in the game. Pedro supports a minimum of 4 players and a maximum or 8 players.

- 4 players bid with 9 cards each
- 5 players bid with 6 cards each
- 6 players bid with 4 cards each
- 7 players bid with 3 cards each
- 8 players bid with 2 cards each

# Game Play Phase
In the game play phase, players attempt to gain as many points as possible. The ways of gaining points are:

- Playing the highest card of the trump suit (1 point)
- Playing the lowest card of the trump suit (1 point)
- Winning a lift with the 5 of the trump suit (5 points)
- Winning a lift with the 9 of the trump suit (9 points)
- Winning a lift with the Jack of the trump suit (1 point if played by you, 3 points if played by an opponent)
- Winning combined lifts with the most cards of value (1 point)
  - Cards of value are as follows:
    - 10 (10 points)
    - Jack (1 point)
    - Queen (2 points)
    - King (3 points)
    - Ace (4 points)

During the game play phase, players play cards in turns in anti-clockwise order starting with the player that won the wadger phase. Each turn consists of playing one card to the board. The player that plays the highest card of the trump suit wins the lift. If no trump cards are played, the player that plays the highest card of the suit that was led wins the lift. The winner of the lift collects the cards and places them face down in front of them. The winner of the lift leads the next lift.

After all cards have been played the players count the points they have accumulated. All players add their points to their total score except the player that won the wadger phase. If the player that won the wadger phase has accumulated the points they bid or more, they add the points to their total score. Otherwise they subtract the points they bid from their total score.

# Game End
The game ends when a player reaches the target score. The target score is arbitrary and is set at the beginning of the game.

# App Overview
The Pedro app allows users to play pedro with other players from their mobile phone or desktop.

## Game Creation
The app should provide players with the ability to create and/or join Pedro games. When a game is created players join in a Lobby before the game creator starts (or cancels) the game. The game creator should be able to send invites to other players via a link or in-game invite.

## Game Play
Once in a game there should be a representation of the players around the board and a visual representation of the cards as they are played by players. Players should be able to review their own lifts but not the lifts of others till it is time to accumulate points. The bid and the trump suit should be displayed in the game interface. The total points accumulated by each player should be displayed in the game interface. At the end of a round the points accumulated by each player should be displayed in the game interface and the total score for each player should be updated. The game should proceed to the next round with the player to the right of the previous round's dealer becoming the new dealer.

## Player Profiles
The app should include a player profile screen where players can define their custom player name. Players should also be able to change their profile picture if they want it to be different from their default Google account picture.

## Social & AI Features
The app includes features to enhance the social experience and provide dynamic feedback during gameplay.

### In-game Chat
Players can communicate with each other via a real-time chat feature available in both the game lobby and during active gameplay. This allows for strategizing, social interaction, and friendly competition.

### AI Game Commentator (Global Narrator)
An AI-driven commentary system provides real-time narration of game events. Since this operates on global app state and broadcasts to all players, it is implemented on the server-side using an agentic framework like **Genkit** via Firebase Cloud Functions.
- **Features:** 
    - Narrating significant bids during the wager phase.
    - Reacting to high-value plays (e.g., Hanging a jack or winning a 5 or 9 of trumps).
    - Providing status updates and "play-by-play" text in the global chat.
    - Offering lighthearted banter to make the game feel more dynamic and alive.

### AI Strategy Coach (The "Inner Voice")
A private AI assistant available only to the local player, implemented using **Firebase AI Logic** on the client side.
- **Bid Assistant:** During the wager phase, the AI analyzes the player's personal hand and provides a "confidence score" or a suggested bid range.
- **Move Suggestions:** During gameplay, it highlights cards with high "strategic value" or offers a brief tooltip explaining why a specific card might be better to play now versus later.
- **Tactical Insights:** It provides real-time odds, such as "There is a 40% chance the Jack is still in the deck."
- **Funny Game Name Generator:** When creating a game, the active AI locally generates a playful, Docker-style room name based on playing card themes (e.g. `jovial_spade` or `sneeky_five`) to avoid relying on a cryptic database ID.

## Technology Stack
The Pedro app is a Flutter app built on Firebase. It uses flutterfire to handle the Flutter Firebase integration. The app uses a basic Data/UI pattern to handle the game state. A data directory contains the models and how those models are retrieved from and persisted to Firebase. A ui directory contains the widgets and how they are displayed to the user. A utils directory contains the utilities that are used by the app. A main.dart file contains the entry point of the app.

Note: Advanced state management like RiverPod is not required for this project.

### Firebase Products
Several Firebase products are used to provide the app's functionality:

- Firebase Authentication: Used to authenticate users.
- Firebase Firestore: Used to store the game state and synced chat/AI messages.
- Firebase AI Logic: Used for both on-device and cloud-based AI commentary.
- Firebase Cloud Functions: Used for backend orchestration and complex game state transitions.
- Firebase Cloud Messaging: Used to send notifications to users.
- Firebase Cloud Storage: Used to store user profile pictures and other dynamic binary assets.
- Firebase Remote Config: Used to store the game configuration and AI model parameters.
- Firebase Crashlytics: Used to report crashes and errors.
- Firebase Performance Monitoring: Used to monitor the app's performance.
- Firebase Analytics: Used to track app usage and user behavior.

### Deployment Targets
The app will be deployed to several targets:

- Android
- iOS
- Web

The mobile (Android/iOS) app will be distributed via the Google Play Store and the Apple App Store. The web app will be distributed via the Firebase Hosting. The web app will be accessible via a URL. The mobile versions of the app will use the package name `com.ool.pedro` and app name `Pedro`.

## Website
A marketing and documentation website for Pedro is located in the `website/` directory. It is built using **VitePress** and provides:
- **App Overview:** A landing page explaining the game's features.
- **Getting the App:** Links to download the app for Android, iOS, and access the Web version.
- **How to Play:** Comprehensive rules and gameplay instructions.
- **Tech Stack:** Details on how the app was built.

The website is deployed to **Firebase Hosting**.

### Flutter Libraries
In addition to other libraries, the following Flutter libraries are used:

- flutterfire: Used to handle the Flutter Firebase integration.
- flutterfire_ui: Used to handle the Flutter Firebase UI integration. In particular authentication.
- flutter_launcher_icons: Used to generate app icons for the app.
- dart_mappable: Used to handle the mapping of Dart objects to and from JSON.

## App Design
A clean material design 3 app. The app should be easy to navigate and use. The app should be visually appealing and easy to understand. The app should be responsive and work on different screen sizes.

### Flutter Card Game Template
Use the flutter card game template as inspiration for the app's UI. The template is available at https://github.com/flutter/flutter/blob/master/examples/flutter_card_game/lib/main.dart. Note that this is a very basic template and will need to be significantly expanded to meet the requirements of the app.
