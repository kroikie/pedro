# Pedro Development Plan & Sprints

This document outlines the development plan for the Pedro multiplayer card game, broken down into major sprints. Each sprint contains a set of tasks that are small enough to be tested for correctness independently.

## Sprint 1: Project Initialization & Infrastructure Setup
**Goal:** Set up the basic directory structure, initialize the core frameworks (Flutter, Cloud Functions, VitePress), and configure the Firebase development environment.

- **Task 1.1: Repository Scaffolding**
  - **Description:** Create the three main directories: `app/` (for Flutter), `functions/` (for Firebase Cloud Functions), and `website/` (for VitePress). 
  - **Validation:** Directories exist and are ready for initialization.

- **Task 1.2: Initialize Flutter App**
  - **Description:** Run `flutter create` with the package name `com.ool.pedro` inside the `app/` directory. Configure the app name as `Pedro`.
  - **Validation:** A clean Flutter app runs successfully on an emulator/simulator.

- **Task 1.3: Configure Flutter Dependencies**
  - **Description:** Update `pubspec.yaml` with the necessary packages (`firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `flutterfire_ui`, `dart_mappable`, `firebase_ai`, etc.).
  - **Validation:** `flutter pub get` completes without dependency conflicts.

- **Task 1.4: Initialize VitePress Website**
  - **Description:** Initialize the VitePress site inside the `website/` directory with a basic boilerplate.
  - **Validation:** The VitePress dev server can be started and serves a default page.

- **Task 1.5: Firebase Project & Emulator Setup**
  - **Description:** Initialize the Firebase project using `firebase-tools`. Set up the Firebase Emulator Suite for Auth, Firestore, Functions, and Storage. Generate `firebase_options.dart` using the `flutterfire_cli`.
  - **Validation:** The Flutter app can initialize Firebase and connect to the local emulator suite.

## Sprint 2: Authentication & User Profiles
**Goal:** Allow users to authenticate, create a profile, and store their data in Firestore.

- **Task 2.1: Authentication Repository**
  - **Description:** Implement the `AuthRepository` in Flutter to handle authentication state changes using `firebase_auth`.
  - **Validation:** The app state reacts to login/logout events.

- **Task 2.2: Login UI**
  - **Description:** Create the initial Login Screen using `flutterfire_ui` components, supporting Google Sign-In.
  - **Validation:** A user can successfully log in using Google Sign-In (or the emulator auth UI) and be routed to a placeholder Home Screen.

- **Task 2.3: User Data Model & Firestore Setup**
  - **Description:** Define the `Player` data model using `dart_mappable`. Create Firestore rules to secure user profiles.
  - **Validation:** Models serialize/deserialize correctly in unit tests.

- **Task 2.4: Player Profile Screen**
  - **Description:** Build the Player Profile UI allowing users to define a custom player name. Save this data to a Firestore `users` collection.
  - **Validation:** Changes made in the UI persist to Firestore and reload correctly.

- **Task 2.5: Cloud Storage Integration for Avatars**
  - **Description:** Integrate `firebase_storage` to allow users to upload a custom profile picture, overriding their default Google account avatar.
  - **Validation:** Images can be picked, uploaded to the emulator storage, and displayed on the profile screen.

## Sprint 3: Lobby & Matchmaking
**Goal:** Implement the ability to create, join, and wait in game lobbies.

- **Task 3.1: Game Room Data Models**
  - **Description:** Define the `GameRoom` model (host, players, status) using `dart_mappable`.
  - **Validation:** Models serialize/deserialize correctly.

- **Task 3.2: AI Game Name Generator**
  - **Description:** Implement the client-side "Inner Voice" AI feature (Firebase AI Logic) to generate playful room names (e.g., `sneeky_five`) when creating a game.
  - **Validation:** Pressing "Create Game" generates a unique, themed name locally.

- **Task 3.3: Game Creation Cloud Function**
  - **Description:** Create the `createGame` Cloud Function that initializes a game document in Firestore and sets the creator as the host.
  - **Validation:** Invoking the function creates the correct Firestore document.

- **Task 3.4: Lobby UI & Game Joining**
  - **Description:** Build the Home Screen UI to display a list of active/recent games. Implement the `joinGame` Cloud Function and the Game Room waiting area UI.
  - **Validation:** A second player can see the created game, join it, and both players see each other in the waiting room.

- **Task 3.5: Invitations & Inbox**
  - **Description:** Implement a system to send game invitations. Build an Inbox view for players to accept or decline invites.
  - **Validation:** Invitations appear in the target user's inbox and accepting routes them to the lobby.

## Sprint 4: Core Game Logic (Backend)
**Goal:** Implement the strict server-side rules and state transitions for playing a round of Pedro.

- **Task 4.1: Game Entities & Deck Logic**
  - **Description:** Define `Card`, `Deck`, `PlayerState`, `Round`, and `Lift` models. Write server-side utilities to generate and shuffle a standard 52-card deck.
  - **Validation:** Unit tests confirm accurate deck generation and shuffling.

- **Task 4.2: Start Game & Deal Cards**
  - **Description:** Implement the `startGame` Cloud Function. It must transition the game state, deal initial cards based on player count (e.g., 9 cards for 4 players), and start the Wadger phase.
  - **Validation:** Game document updates with player hands and sets the phase to 'Wadger'.

- **Task 4.3: Wadger Phase Logic**
  - **Description:** Implement the `submitBid` Cloud Function. Enforce bidding rules (minimum 1, increasing bids, passing). Determine the winner when all others pass.
  - **Validation:** Function correctly rejects invalid bids and accurately identifies the wadger winner.

- **Task 4.4: Trump Selection Logic**
  - **Description:** Implement the `setTrumpSuit` Cloud Function for the bid winner. The function must handle discarding non-trumps, reshuffling the deck, and dealing back up to 6 cards.
  - **Validation:** Players end up with exactly 6 cards, and the trump suit is stored in the game state.

- **Task 4.5: Game Play & Lift Logic**
  - **Description:** Implement the `playCard` Cloud Function. Evaluate lift winners based on trump and leading suit, calculate points, and handle the transition to the next lift or the end of the round.
  - **Validation:** Function correctly scores Pedro-specific rules (e.g., 5 of trumps = 5 points) and updates the total scores at the end of the round.

## Sprint 5: Game UI & Gameplay Sync
**Goal:** Build the visual game board and synchronize it with the Firestore backend state.

- **Task 5.1: Game Repository Sync**
  - **Description:** Implement the `GameRepository` to stream the active game document from Firestore to the UI.
  - **Validation:** Console logs reflect state changes made directly in the Firestore emulator.

- **Task 5.2: Game Board Layout**
  - **Description:** Build the main game UI using Material 3. Position Player Avatar Widgets around the board and create the central area for played cards.
  - **Validation:** UI accurately reflects the number of players and their relative positions.

- **Task 5.3: Player Hand UI**
  - **Description:** Implement `CardWidget` to display the local player's hand. Add interactions (drag/tap) to play a card, linked to the `playCard` function.
  - **Validation:** Playing a card updates the backend and moves the card to the center board.

- **Task 5.4: Wadger & Trump UI**
  - **Description:** Create overlays/modals for players to input bids and select trump suits during the Wadger phase. Disable inputs when it is not the local player's turn.
  - **Validation:** UI flows smoothly through the bidding process and into the gameplay phase.

- **Task 5.5: Scoreboard & Round End UI**
  - **Description:** Display current bids and trump suit on the board. Implement a summary modal at the end of a round showing point breakdowns and updated total scores.
  - **Validation:** Scoreboard displays accurate data matching the backend state.

## Sprint 6: Social & AI Features
**Goal:** Enhance the game with real-time chat and intelligent AI companions.

- **Task 6.1: In-Game Real-Time Chat**
  - **Description:** Implement a Chat Overlay UI and a synchronized Firestore collection for messages within a specific game room.
  - **Validation:** Messages sent by one player appear instantly for others in the room.

- **Task 6.2: Global AI Narrator (Genkit)**
  - **Description:** Implement server-side AI using Genkit via Cloud Functions. Trigger commentary based on game events (high bids, playing the 5 of trumps) and post messages into the chat.
  - **Validation:** AI commentary appears in the chat automatically during significant gameplay moments.

- **Task 6.3: Client-Side AI Coach (Bid Assistant)**
  - **Description:** Use Firebase AI Logic to analyze the player's local hand during the Wadger phase and suggest a bid range or confidence score.
  - **Validation:** AI provides reasonable bid suggestions based on the dealt cards.

- **Task 6.4: Client-Side AI Coach (Tactical Insights)**
  - **Description:** Implement local AI tooltips for strategic card suggestions and real-time odds calculation (e.g., probability of a high trump remaining) during the Game Play phase.
  - **Validation:** Helpful UI tooltips appear alongside specific cards in the player's hand.

## Sprint 7: Website, Analytics & Polish
**Goal:** Build the marketing site, integrate analytics, polish the UI, and prepare for deployment.

- **Task 7.1: Website Content Creation**
  - **Description:** Populate the VitePress pages: App Overview, Download Links, and How to Play.
  - **Validation:** The website provides complete and accurate information about the game.

- **Task 7.2: Analytics & Performance Integration**
  - **Description:** Add Firebase Analytics, Performance Monitoring, and Crashlytics to the Flutter app.
  - **Validation:** Events and non-fatal errors appear in the Firebase Emulator dashboard.

- **Task 7.3: Theming & Animations**
  - **Description:** Polish the Material 3 design. Add smooth animations for card dealing, playing, and collecting lifts. Ensure responsiveness across mobile and web screen sizes.
  - **Validation:** App looks professional and interactions feel fluid.

- **Task 7.4: Deployment Preparation**
  - **Description:** Configure Firebase Hosting for the Website and Flutter Web App. Set up Android and iOS build configurations (icons using `flutter_launcher_icons`, bundle IDs).
  - **Validation:** Successful production builds can be generated for all targets.
