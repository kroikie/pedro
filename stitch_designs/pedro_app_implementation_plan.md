# Pedro App Implementation Plan
This plan details the development of Pedro, a cross-platform multiplayer card game built with Flutter and Firebase. The app will follow a clean Data/UI architectural pattern without complex state management libraries (like Riverpod), as requested. 
## Next Steps
> [!IMPORTANT]
> The app relies heavily on Firebase. I will utilize the `firebase-tools` and `flutterfire_cli` commands to handle the project creation, Firebase configuration, and setup steps for you seamlessly.
## Proposed Changes
### 1. Project Initialization & Tooling
- Separate the repository into an `app` directory for the Flutter application (`/home/arthurthompson/src/pedro/app`), a `functions` directory for Firebase Cloud Functions (`/home/arthurthompson/src/pedro/functions`), and a `website` directory for the promotional site (`/home/arthurthompson/src/pedro/website`).
- Initialize a new Flutter application (App Name: `Pedro`, Package Name: `com.ool.pedro`) inside the `app` directory, and initialize a VitePress site inside the `website` directory.
- Setup `pubspec.yaml` with required dependencies: 
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_storage`, `firebase_remote_config`, `firebase_crashlytics`, `firebase_performance`, `firebase_analytics`, `firebase_messaging`
  - `firebase_ai` (Firebase AI Logic)
  - `flutterfire_ui`
  - `dart_mappable`
  - `build_runner` (dev)
  - `dart_mappable_builder` (dev)
  - `flutter_launcher_icons` (dev)
- Format directory structure: `lib/data/`, `lib/ui/`, `lib/utils/`.
---
### 2. Firebase Configuration
- Use `flutterfire configure` to generate `firebase_options.dart`.
- Prepare the development environment to use the Firebase Emulator Suite. Provide a `firebase.json` at the root specifying emulator ports, and initialize Firebase inside `lib/main.dart` with conditional logic to route requests to the local emulator endpoints during development.
---
### 3. Data Layer Implementation
- **Data Models (`lib/data/models/`)** using `dart_mappable`:
  - `Player`, `GameRoom`, `Round`, `Card`, `PlayerState`, `Deck`, `Lift`
- **Data Repositories (`lib/data/repositories/`)**:
  - `AuthRepository`: Manages player authentication state using the `authStateChanges` stream to reactively update the app state. Authentication will initially rely exclusively on Google Sign-In, with scope to add other providers later.
  - `GameRepository`: Listens to Firestore collections to synchronize state and calls Cloud Functions for state mutations.
---
### 4. Game Logic & State Management (Cloud Functions vs Client)
- **Server-Side Game Engine (`functions/`)**:
  - Use Firebase Cloud Functions for backend orchestration, robust game logic (complex state transitions), and to avoid client cheating.
  - Implement endpoints/triggers: `createGame`, `joinGame`, `startGame`, `submitBid`, `setTrumpSuit`, `playCard`.
  - The server strictly handles all core game state transitions (e.g., advancing to the next lift, next phase, or the next round).
- **Social & AI Commentator**:
  - **In-Game Chat:** Implement real-time chat utilizing a Firestore collection synced across all connected clients.
  - **AI Logic SDK:** Leverage Firebase AI Logic (Gemini API) for an AI game narrator to provide play-by-play status updates, react to high-value plays (like hanging a jack or winning a 5/9 lift), and offer banter.
  - **Smart Sync:** Utilize the cloud-based **Firebase AI Logic SDK** (e.g. `FirebaseAI.googleAI().generativeModel(model: 'gemini-3-flash-preview')`), as Flutter does not natively support AI logic hybrid execution yet. The AI's narration will be appended to the Firestore chat collection so all players view the exact same commentary simultaneously.
---
### 5. UI Layer Implementation
- **Layout & Routing (`lib/ui/`)**:
  - Simple routing map setup in `main.dart`.
  - **Home Screen:** Features preview widgets. Options include: 'Games' showing the last 3 games (in reverse chronological order) with tap actions to jump into active games or view details of completed games, plus a link to view all nested matches. It should also preview the latest incoming game invitations.
  - **Inbox:** A view allowing the player to manage and accept incoming game invitations.
- **Authentication & Profile Screens**:
  - Utilizing `flutterfire_ui` templates for Google Sign-In.
  - **Player Profile:** A screen where players can define a custom player name and upload a separate profile picture if they prefer overriding their default Google account avatar.
- **Lobby Interface (`lib/ui/lobby/`)**:
  - Game creation wizard and Game Room waiting area.
- **Game Interface (`lib/ui/game/`)**:
  - Use Material 3 widgets with rich animations, drawing inspiration from the Flutter Card Game Template mapping physical cards handling to the digital board.
  - Ensure the real-time chat interface is directly accessible from the active game screen.
  - Widget components: `CardWidget`, `PlayerAvatarWidget`, `BidOverlay`, `TrumpSuitSelector`, `ScoreBoard`, `ChatOverlay`.
---
### 6. Website Implementation
- **VitePress Setup (`website/`)**:
  - Initialize a static site using VitePress to act as the marketing and documentation hub.
  - Implement pages detailed in `Pedro.md`: App Overview, Getting the App (download links), How to Play (rules), and Tech Stack breakdown.
- **Firebase Hosting**:
  - Configure `firebase.json` to deploy the `website/` output to Firebase Hosting.
## Verification Plan
### Automated Tests
- Run `flutter test` for Dart model logic tests.
- Unit test points-calculation logic.
### Manual Verification
- Deploy basic routing and verify Material 3 themes.
- Test user flows from Login -> Lobby -> Empty Game Room.
- Test end-to-end game state management using multiple simulated clients pointing to the Firebase Emulator.