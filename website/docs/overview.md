# Game & App Overview

**Pedro** is a modern, real-time multiplayer card game app designed for seamless social play, strategic decision-making, and AI-assisted gameplay.

---

## What Makes Pedro Special?

### 1. Seamless Multiplayer & Lobbies
- **Instant Synchronization:** Play in real-time with friends or opponents across devices.
- **Custom Game Rooms:** Easily create private game rooms or browse open lobbies. Game rooms feature fun, AI-generated room names.
- **Direct Player Invites:** Send game invitations straight to your friends' in-app inbox.
- **Game Management & Deletion:** Game creators maintain full administrative control over their games, with the option to permanently delete games they created directly from the lobby waiting room, the Home feed's recent games list, or the active game board. Deletion includes a confirmation safeguard and thoroughly removes the game document along with all associated chat messages and reactions across all players.

### 2. Interactive AI Companions
- **Global AI Narrator (Trinidad & Tobago Voice):** An in-game announcer observes key moments—such as aggressive bids, key trumps played, and clutch scoring—delivering live commentary and banter with an authentic, witty Trinidadian accent and cadence (featuring iconic expressions like *"Dat is ah brave bid!"*, *"Lardits!"*, *"Jah!"*, and *"Oh gosh! Arthur does play card for gramoxone!"*). Powered server-side by **Genkit** (`gemini-3.5-flash-lite`) in Cloud Functions, authenticated via **Google Cloud Secret Manager** (`GEMINI_API_KEY`).
- **Personal AI Coach & Smart Room Naming (`gemini-3.5-flash-lite`):** 
  - **Bid Assistant:** Analyzes your hand during the Wadger phase and suggests competitive bid ranges with strategy tips.
  - **Tactical Insights:** Recommends optimal moves and highlights key remaining cards during gameplay to elevate your skills.
  - **Creative Room Names:** Automatically names newly created game rooms with playful card-themed titles.
  - **App Check Security & Anti-Fraud Defense:** Client-side AI calls via Firebase AI Logic are strictly protected by **Firebase App Check** enforced with **Fraud Defense (reCAPTCHA Enterprise)** across iOS, Android, and Web (`enforcementMode: ENFORCED`). Client inference requests use standard App Check tokens (`FirebaseAI.googleAI()`), matching the architecture used in Capiche to ensure reliable cross-platform execution while avoiding upstream iOS FlutterFire token drops ([#18718](https://github.com/firebase/flutterfire/issues/18718)). On iOS, the Google Cloud reCAPTCHA Enterprise key enforces bundle ID integrity (`com.ool.pedro`) and risk assessment scoring (minimum valid score threshold of 0.5), with native runtime symbols preserved via `-ObjC`. All services stream runtime diagnostic errors directly to **Firebase Crashlytics**.

### 3. In-Game Social Interactions & Live Reactions
- **Transient Chat Notifications:** When comments are posted by the AI Narrator or fellow players, a floating notification banner appears over the board for a few seconds before smoothly fading down into the collapsed Game Chat bar. Players never have to keep the chat open to stay connected with the banter.
- **Adaptive Game Chat Drawer & Safe Keyboard Handling:** When opened, the Game Chat expands with a screen-proportionate, responsive height that leaves ample room for the live card table. When typing on mobile devices, the layout adaptively preserves full visibility of the text field and send controls directly above the soft keyboard without pixel overflow. Hitting "Done" on the keyboard dismisses the keyboard safely without prematurely sending draft messages; message transmission is strictly controlled via the UI send button.
- **Quick Emoji Reactions:** Located directly beneath the player's card hand, a row of reaction emojis (`👏`, `🔥`, `😂`, `😱`, `🎉`, `👍`, `🤦‍♂️`) enables one-tap expressive reactions. Triggered emojis float gracefully up the game table in real time for all players to see, without cluttering the persistent chat log.

### 4. Smart Notifications & "Call Player" (Nudge)
- **Real-Time Turn Alerts:** Push notifications inform players when it is their turn to bid, choose the trump suit, or play a card, keeping multiplayer sessions moving even when players have backgrounded the app.
- **Game Lifecycle Updates:** Immediate alerts when receiving a game invite, when a lobby match begins, or when a final winner is crowned.
- **AI Narrator "Call Player" Nudge:** If a player is taking too long to play, waiting players can tap the **"Call Player"** button on the board. This prompts the AI Narrator to poke the slow player with witty Trinidadian banter (e.g., *"Aye Bob, yuh could stop eating for 2 seconds to play yuh know! Alice waiting on yuh!"*), broadcasting live to the room chat and delivering a high-priority push notification directly to their device. A 30-second cooldown protects players from notification spam.
- **Cross-Platform Push Architecture (Android & iOS):** Notifications are delivered via Firebase Cloud Messaging (FCM). On iOS devices, the app utilizes native Apple Push Notification service (APNs) integration configured with `aps-environment` entitlements, `remote-notification` background modes, foreground presentation delegation via `UNUserNotificationCenter`, and asynchronous APNs device token synchronization with Firestore player profiles.

### 5. User Profiles & Customization
- **Flexible & Secure Sign-In:** Sign in easily and jump straight into the action with support for Email/Password and native one-tap Google Sign-In across Web, Android, and iOS release environments (configured with native iOS URL schemes, GID client descriptors, and seamless presentation lifecycle).
- **Initial Google Account Avatar:** When signing in with Google, the photo from the user's Google account is automatically used as their initial avatar. Players can also re-sync or revert to their Google profile photo at any time from their profile settings.
- **AI Avatar Generator (`gemini-3.1-flash-image`):** Players can generate stylized, vibrant cartoon avatars directly within the app using Firebase AI Logic:
  - **Cartoon Animals:** Create cartoon portraits of favorite animals (e.g. a majestic lion, clever fox, sly wolf, or wise owl).
  - **Cartoon Persons:** Generate stylized cartoon headshots based on custom descriptions, specifically designed with darker skin tones (deep melanin and rich brown complexions, e.g. army woman, astronaut, detective, or gamer).
  - **In-App Interactive Preview:** Allows players to preview generated artwork in a circular frame, refine prompts, and confirm before setting as their active avatar.
- **Custom Image Upload:** Players can continue to upload their own images from their device photo gallery.
- **Firebase Cloud Storage & FirebaseUI Storage:** All generated and uploaded avatars are saved to Firebase Cloud Storage under timestamped, user-scoped paths (`avatars/{userId}_{timestamp}.jpg`). Avatars are efficiently rendered and cached across the app using FirebaseUI Storage (`StorageImage`), with authenticated-only read access and user-isolated write validation in `storage.rules`.
- **Administrative Backfill Tool:** An administrative CLI utility (`scripts/backfill_google_avatars.sh` / `functions/bin/backfill_google_avatars.dart`) allows operators to scan existing accounts and backfill missing avatar URLs for players who previously authenticated via Google Sign-In.
- **Offline-Resilient Profile Initialization & Cache Fallback:** Profile loading during app startup (`AuthGate`) leverages a multi-tiered resilience strategy. Remote Firestore queries feature non-blocking timeouts with immediate fallback to local Firestore cache (`Source.cache`) and persisted Firebase Authentication credentials, ensuring users are never blocked or stuck on timeout error screens during cold starts or transient cellular connectivity drops.
- **Version Identification & Diagnostics Reporting:** Players and beta testers can quickly identify and copy their exact app version and build number (`vX.Y.Z (Build N)`) from the footer of the Sign-In screen, the bottom of the User Profile screen, or via the **About Pedro** info dialog in game lobbies and tables. A single tap copies the version string, while a long press copies a full diagnostic bundle (Version, Build, Platform, Firebase UID, Active Game ID, and live Firebase App Check token status) for frictionless bug reporting.

### 6. Adaptive & Accessible Design
- Clean, intuitive interface with smooth animations, clear card visuals, and adaptive layouts tailored for phones, tablets, and web browsers.
- **Dynamic Game Identification:** The navigation bar clearly presents the active game room's name with graceful text truncation, keeping game context prominent without encroaching on contract status indicators.
- **Adaptive Turn & Action Indicators:** The player interaction bar dynamically reorganizes turn status, bidder targets, and "Call Player" actions into responsive multi-axis layouts across varying screen dimensions and text scales, eliminating RenderFlex pixel clipping while preserving player name legibility.
- **Adaptive Multi-Row Trick Grid (5 to 8 Players):** To preserve complete visual clarity and situational awareness during multiplayer games with 5 to 8 players, trick cards in the live lift area and the Previous Trick modal adaptively organize into a 2-row layout bounded by a safe central corridor. Cards automatically scale responsively, with side player badges adjusting their alignments and footprints in 7–8 player sessions so no cards or player attribution labels are ever blocked.
- **Responsive Card Interactions & Debouncing:** Instant visual feedback (dimming and border emphasis) upon card selection, paired with proactive tap debouncing and server-side idempotency to eliminate accidental double-submissions and network race conditions.

### 7. Signature Branding & Visual Identity
- **Iconic Mobile & Web Presence:** Features a custom luxury emblem centered on a polished gold capital 'P' adorned with a playing card spade on a deep emerald green felt background, evoking the timeless atmosphere of classic card tables across iOS, Android, and Web platforms.

### 8. Backend Architecture & Cloud Functions Endpoints
- **Server-Side Authoritative Game Logic:** All game state transitions (game creation, game deletion, player invitations, bidding, trump selection, card play, scoring, and player nudges) are orchestrated server-side in Cloud Functions to guarantee game state integrity.
- **Dart Cloud Functions & Cloud Run Deployment:** Cloud functions are authored in Dart using `firebase_functions` and deployed directly as Google Cloud Run services (`https://<function-name>-260654198138.us-central1.run.app`).
- **Dynamic Callable Routing:** The Flutter client seamlessly routes callable invocations through `PedroFunctionsExtension.callable`:
  - In local development and automated testing, functions automatically target the local Firebase Functions Emulator suite (`localhost:5001` or `10.0.2.2:5001`).
  - In production release builds across Android, iOS, and Web, functions target deterministic Cloud Run endpoints (`https://<function-name>-260654198138.us-central1.run.app`).
- **End-to-End Authentication & Transport Security:** Cloud Run services allow public HTTP transport invocation (`allUsers` with `roles/run.invoker`) so client callable requests reach the Dart container, where request credentials are cryptographically authenticated against Firebase Authentication (`request.auth`). Client repositories proactively verify authentication state (`_auth.currentUser`) and force fresh ID token resolution before dispatching sensitive lifecycle operations like game deletion.

