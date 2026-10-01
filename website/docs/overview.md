# Game & App Overview

**Pedro** is a modern, real-time multiplayer card game app designed for seamless social play, strategic decision-making, and AI-assisted gameplay.

---

## What Makes Pedro Special?

### 1. Seamless Multiplayer & Lobbies
- **Instant Synchronization:** Play in real-time with friends or opponents across devices.
- **Custom Game Rooms:** Easily create private game rooms or browse open lobbies. Game rooms feature fun, AI-generated room names.
- **Direct Player Invites:** Send game invitations straight to your friends' in-app inbox.

### 2. Interactive AI Companions
- **Global AI Narrator (Trinidad & Tobago Voice):** An in-game announcer observes key moments—such as aggressive bids, key trumps played, and clutch scoring—delivering live commentary and banter with an authentic, witty Trinidadian accent and cadence (featuring iconic expressions like *"Dat is ah brave bid!"*, *"Lardits!"*, *"Jah!"*, and *"Oh gosh! Arthur does play card for gramoxone!"*). Powered server-side by **Genkit** (`gemini-2.5-flash`) in Cloud Functions, authenticated via **Google Cloud Secret Manager** (`GEMINI_API_KEY`).
- **Personal AI Coach & Smart Room Naming:** 
  - **Bid Assistant:** Analyzes your hand during the Wadger phase and suggests competitive bid ranges with strategy tips.
  - **Tactical Insights:** Recommends optimal moves and highlights key remaining cards during gameplay to elevate your skills.
  - **Creative Room Names:** Automatically names newly created game rooms with playful card-themed titles.
  - **App Check & Fraud Defense Security:** Client-side AI calls via Firebase AI Logic are strictly protected by **Firebase App Check** enforced with **Fraud Defense (reCAPTCHA Enterprise)** across iOS, Android, and Web, preventing unauthorized API quota exploitation.

### 3. In-Game Social Interactions & Live Reactions
- **Transient Chat Notifications:** When comments are posted by the AI Narrator or fellow players, a floating notification banner appears over the board for a few seconds before smoothly fading down into the collapsed Game Chat bar. Players never have to keep the chat open to stay connected with the banter.
- **Adaptive Game Chat Drawer:** When opened, the Game Chat expands with a screen-proportionate, responsive height that leaves ample room for the live card table. Card lift areas, player avatars, and interaction panels dynamically scale and adapt to prevent pixel overflow across all device viewports.
- **Quick Emoji Reactions:** Located directly beneath the player's card hand, a row of reaction emojis (`👏`, `🔥`, `😂`, `😱`, `🎉`, `👍`, `🤦‍♂️`) enables one-tap expressive reactions. Triggered emojis float gracefully up the game table in real time for all players to see, without cluttering the persistent chat log.

### 4. Smart Notifications & "Call Player" (Nudge)
- **Real-Time Turn Alerts:** Push notifications inform players when it is their turn to bid, choose the trump suit, or play a card, keeping multiplayer sessions moving even when players have backgrounded the app.
- **Game Lifecycle Updates:** Immediate alerts when receiving a game invite, when a lobby match begins, or when a final winner is crowned.
- **AI Narrator "Call Player" Nudge:** If a player is taking too long to play, waiting players can tap the **"Call Player"** button on the board. This prompts the AI Narrator to poke the slow player with witty Trinidadian banter (e.g., *"Aye Bob, yuh could stop eating for 2 seconds to play yuh know! Alice waiting on yuh!"*), broadcasting live to the room chat and delivering a high-priority push notification directly to their device. A 30-second cooldown protects players from notification spam.

### 5. User Profiles & Customization
- **Flexible & Secure Sign-In:** Sign in easily and jump straight into the action with support for Email/Password and native one-tap Google Sign-In across Web, Android, and iOS release environments (configured with native iOS URL schemes, GID client descriptors, and seamless presentation lifecycle).
- **Personalized Avatars:** Choose your player nickname and upload custom avatar images to represent yourself at the table.

### 6. Adaptive & Accessible Design
- Clean, intuitive interface with smooth animations, clear card visuals, and adaptive layouts tailored for phones, tablets, and web browsers.
- **Dynamic Game Identification:** The navigation bar clearly presents the active game room's name with graceful text truncation, keeping game context prominent without encroaching on contract status indicators.
- **Adaptive Turn & Action Indicators:** The player interaction bar dynamically reorganizes turn status, bidder targets, and "Call Player" actions into responsive multi-axis layouts across varying screen dimensions and text scales, eliminating RenderFlex pixel clipping while preserving player name legibility.
- **Responsive Card Interactions & Debouncing:** Instant visual feedback (dimming and border emphasis) upon card selection, paired with proactive tap debouncing and server-side idempotency to eliminate accidental double-submissions and network race conditions.

### 7. Signature Branding & Visual Identity
- **Iconic Mobile & Web Presence:** Features a custom luxury emblem centered on a polished gold capital 'P' adorned with a playing card spade on a deep emerald green felt background, evoking the timeless atmosphere of classic card tables across iOS, Android, and Web platforms.

### 8. Backend Architecture & Cloud Functions Endpoints
- **Server-Side Authoritative Game Logic:** All game state transitions (game creation, player invitations, bidding, trump selection, card play, scoring, and player nudges) are orchestrated server-side in Cloud Functions to guarantee game state integrity.
- **Dart Cloud Functions & Cloud Run Deployment:** Cloud functions are authored in Dart using `firebase_functions` and deployed directly as Google Cloud Run services (`https://<function-name>-260654198138.us-central1.run.app`).
- **Dynamic Callable Routing:** The Flutter client seamlessly routes callable invocations through `PedroFunctionsExtension.callable`:
  - In local development and automated testing, functions automatically target the local Firebase Functions Emulator suite (`localhost:5001` or `10.0.2.2:5001`).
  - In production release builds across Android, iOS, and Web, functions target deterministic Cloud Run endpoints (`https://<function-name>-260654198138.us-central1.run.app`).
