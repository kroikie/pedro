import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/card.dart' as pedro;
import 'package:pedro/data/models/chat_message.dart';
import 'package:pedro/data/models/game_reaction.dart';
import 'package:pedro/data/models/game_room.dart';
import 'package:pedro/data/models/game_session.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/data/repositories/chat_repository.dart';
import 'package:pedro/data/repositories/game_repository.dart';
import 'package:pedro/data/repositories/lobby_repository.dart';
import 'package:pedro/data/repositories/player_repository.dart';
import 'package:pedro/data/repositories/reaction_repository.dart';
import 'package:pedro/ui/screens/game_board_screen.dart';
import 'package:pedro/ui/screens/game_room_screen.dart';
import 'package:pedro/ui/screens/home_feed_view.dart';

const kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _FakeFirestore extends Fake implements FirebaseFirestore {}

class _FakeUser extends Fake implements User {
  bool tokenRefreshed = false;

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    tokenRefreshed = true;
    return 'fake-token';
  }
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _user;

  _FakeFirebaseAuth([this._user]);

  @override
  User? get currentUser => _user;
}

class _FakeHttpsCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  final T _data;
  _FakeHttpsCallableResult(this._data);

  @override
  T get data => _data;
}

class _FakeHttpsCallable extends Fake implements HttpsCallable {
  Map<String, dynamic>? calledWith;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    calledWith = parameters as Map<String, dynamic>?;
    return _FakeHttpsCallableResult<T>({'success': true} as T);
  }
}

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final Map<String, _FakeHttpsCallable> callables = {};

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    final callable = _FakeHttpsCallable();
    callables[name] = callable;
    return callable;
  }

  @override
  HttpsCallable httpsCallableFromUrl(String url, {HttpsCallableOptions? options}) {
    final callable = _FakeHttpsCallable();
    callables[url] = callable;
    return callable;
  }
}

class MockLobbyRepository implements LobbyRepository {
  GameRoom? mockRoom;
  List<GameRoom> myGames = [];
  List<GameRoom> invitations = [];
  String? deletedGameId;

  @override
  Stream<GameRoom?> watchGame(String gameId) => Stream.value(mockRoom);

  @override
  Stream<List<GameRoom>> watchMyGames() => Stream.value(myGames);

  @override
  Stream<List<GameRoom>> watchInvitations() => Stream.value(invitations);

  @override
  Future<String> createGame(String roomName, {int targetScore = 35}) async => 'new_game';

  @override
  Future<void> joinGame(String gameId) async {}

  @override
  Future<void> invitePlayer(String gameId, String targetPlayerId) async {}

  @override
  Future<void> uninvitePlayer(String gameId, String targetPlayerId) async {}

  @override
  Future<void> deleteGame(String gameId) async {
    deletedGameId = gameId;
  }

  @override
  Stream<List<GameRoom>> watchLiveGames() => const Stream.empty();

  @override
  Future<void> joinGameAsViewer(String gameId) async {}

  @override
  Future<void> heartbeatViewer(String gameId) async {}

  @override
  Future<void> leaveGameViewer(String gameId) async {}
}

class MockPlayerRepository implements PlayerRepository {
  final Map<String, Player> players = {
    'host_uid': const Player(id: 'host_uid', screenName: 'Host Player'),
    'my_uid': const Player(id: 'my_uid', screenName: 'My Player'),
    'other_uid': const Player(id: 'other_uid', screenName: 'Other Player'),
  };

  @override
  Future<Player?> getPlayer(
    String uid, {
    Source source = Source.serverAndCache,
    Duration? timeout,
  }) async {
    return players[uid] ?? Player(id: uid, screenName: 'Player $uid');
  }

  @override
  Future<Player?> getPlayerFromCache(String uid) async => getPlayer(uid);

  @override
  Future<void> updatePlayer(Player player) async {}

  @override
  Future<void> addFcmToken(String uid, String token, String platform) async {}

  @override
  Future<void> removeFcmToken(String uid, String token) async {}

  @override
  Stream<Player?> watchPlayer(String uid) {
    return Stream.value(players[uid] ?? Player(id: uid, screenName: 'Player $uid'));
  }

  @override
  Stream<List<Player>> watchAllPlayers() {
    return Stream.value(players.values.toList());
  }
}

class MockGameRepository implements GameRepository {
  GameSession? currentSession;
  String? deletedGameId;

  @override
  Stream<GameSession?> watchGameSession(String gameId) => Stream.value(currentSession);

  @override
  Future<void> playCard(String gameId, pedro.Card card) async {}

  @override
  Future<void> startGame(String gameId) async {}

  @override
  Future<void> submitBid(String gameId, int? bid) async {}

  @override
  Future<void> setTrumpSuit(String gameId, pedro.Suit suit) async {}

  @override
  Future<void> callPlayer(String gameId) async {}

  @override
  Future<void> deleteGame(String gameId) async {
    deletedGameId = gameId;
  }

  @override
  Future<void> joinGameAsViewer(String gameId) async {}

  @override
  Future<void> heartbeatViewer(String gameId) async {}

  @override
  Future<void> leaveGameViewer(String gameId) async {}
}

class MockReactionRepository implements ReactionRepository {
  @override
  Stream<List<GameReaction>> watchRecentReactions(String gameId) {
    return const Stream.empty();
  }

  @override
  Future<void> sendReaction({
    required String gameId,
    required String senderId,
    required String senderName,
    required String emoji,
  }) async {}
}

class MockChatRepository implements ChatRepository {
  @override
  Stream<List<ChatMessage>> watchMessages(String gameId) {
    return Stream.value([]);
  }

  @override
  Future<void> sendMessage({
    required String gameId,
    required String senderId,
    required String senderName,
    required String text,
    bool isAi = false,
  }) async {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Delete Game in GameRoomScreen (Lobby)', () {
    testWidgets('Displays delete button if current user is host', (tester) async {
      final lobbyRepo = MockLobbyRepository();
      lobbyRepo.mockRoom = GameRoom(
        id: 'game1',
        hostId: 'host_uid',
        name: 'Fun Room',
        playerIds: ['host_uid'],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameRoomScreen(
            gameId: 'game1',
            lobbyRepository: lobbyRepo,
            playerRepository: MockPlayerRepository(),
            chatRepository: MockChatRepository(),
            currentUserId: 'host_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('Does not display delete button if current user is not host', (tester) async {
      final lobbyRepo = MockLobbyRepository();
      lobbyRepo.mockRoom = GameRoom(
        id: 'game1',
        hostId: 'host_uid',
        name: 'Fun Room',
        playerIds: ['host_uid', 'other_uid'],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameRoomScreen(
            gameId: 'game1',
            lobbyRepository: lobbyRepo,
            playerRepository: MockPlayerRepository(),
            chatRepository: MockChatRepository(),
            currentUserId: 'other_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('Tapping delete button shows dialog and calls deleteGame on confirmation', (tester) async {
      final lobbyRepo = MockLobbyRepository();
      lobbyRepo.mockRoom = GameRoom(
        id: 'game1',
        hostId: 'host_uid',
        name: 'Fun Room',
        playerIds: ['host_uid'],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameRoomScreen(
            gameId: 'game1',
            lobbyRepository: lobbyRepo,
            playerRepository: MockPlayerRepository(),
            chatRepository: MockChatRepository(),
            currentUserId: 'host_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Game'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Fun Room"? This action cannot be undone and will remove the game for all players.'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(lobbyRepo.deletedGameId, 'game1');
    });

    testWidgets('Shows deleted message and Return to Lobby button when room is null', (tester) async {
      final lobbyRepo = MockLobbyRepository();
      lobbyRepo.mockRoom = null;

      await tester.pumpWidget(
        MaterialApp(
          home: GameRoomScreen(
            gameId: 'game1',
            lobbyRepository: lobbyRepo,
            playerRepository: MockPlayerRepository(),
            chatRepository: MockChatRepository(),
            currentUserId: 'host_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Game not found or has been deleted.'), findsOneWidget);
      expect(find.text('Return to Lobby'), findsOneWidget);
    });
  });

  group('Delete Game in HomeFeedView', () {
    testWidgets('Displays delete option in popup menu for games created by current user', (tester) async {
      final lobbyRepo = MockLobbyRepository();
      lobbyRepo.myGames = [
        GameRoom(
          id: 'hosted_game',
          hostId: 'my_uid',
          name: 'My Hosted Game',
          playerIds: ['my_uid'],
          createdAt: DateTime.now(),
        ),
        GameRoom(
          id: 'joined_game',
          hostId: 'other_uid',
          name: 'Someone Else Game',
          playerIds: ['my_uid', 'other_uid'],
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeFeedView(
              onCreateGameTap: () {},
              onViewAllGamesTap: () {},
              lobbyRepository: lobbyRepo,
              playerRepository: MockPlayerRepository(),
              currentUserId: 'my_uid',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 1 popup menu for the game created by my_uid
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Delete Game'), findsOneWidget);

      await tester.tap(find.text('Delete Game'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to delete "My Hosted Game"? This action cannot be undone and will remove the game for all players.'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(lobbyRepo.deletedGameId, 'hosted_game');
    });
  });

  group('Delete Game in GameBoardScreen', () {
    testWidgets('Displays delete option when session hostId matches current user', (tester) async {
      final gameRepo = MockGameRepository();
      gameRepo.currentSession = const GameSession(
        gameId: 'game_active',
        hostId: 'my_uid',
        name: 'Championship Board',
        playerStates: [
          PlayerGameState(
            uid: 'my_uid',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.ten)],
          ),
          PlayerGameState(
            uid: 'other_uid',
            hand: [pedro.Card(suit: pedro.Suit.diamonds, rank: pedro.Rank.five)],
          ),
        ],
        currentRound: RoundState(
          dealerId: 'my_uid',
          phase: RoundPhase.playing,
          bidWinnerId: 'my_uid',
          bidValue: 4,
          trumpSuit: pedro.Suit.diamonds,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'game_active',
            gameRepository: gameRepo,
            playerRepository: MockPlayerRepository(),
            reactionRepository: MockReactionRepository(),
            chatRepository: MockChatRepository(),
            currentUserId: 'my_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Delete Game'), findsOneWidget);

      await tester.tap(find.text('Delete Game'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to delete "Championship Board"? This action cannot be undone and will end the game for all players.'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(gameRepo.deletedGameId, 'game_active');
    });

    testWidgets('Shows deleted message and Return to Home button when session is null', (tester) async {
      final gameRepo = MockGameRepository();
      gameRepo.currentSession = null;

      await tester.pumpWidget(
        MaterialApp(
          home: GameBoardScreen(
            gameId: 'deleted_game',
            gameRepository: gameRepo,
            playerRepository: MockPlayerRepository(),
            reactionRepository: MockReactionRepository(),
            chatRepository: MockChatRepository(),
            currentUserId: 'my_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This game has ended or was deleted.'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
    });
  });

  group('Repository Authentication Checks', () {
    test('LobbyRepository.deleteGame throws unauthenticated exception when not logged in', () async {
      final fakeFunctions = _FakeFirebaseFunctions();
      final fakeAuth = _FakeFirebaseAuth(null);
      final repo = LobbyRepository(
        firestore: _FakeFirestore(),
        functions: fakeFunctions,
        auth: fakeAuth,
      );

      expect(
        () => repo.deleteGame('game123'),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (e) => e.code,
            'code',
            'unauthenticated',
          ),
        ),
      );
      expect(fakeFunctions.callables.isEmpty, isTrue);
    });

    test('LobbyRepository.deleteGame refreshes token and calls delete-game callable when authenticated', () async {
      final fakeFunctions = _FakeFirebaseFunctions();
      final fakeUser = _FakeUser();
      final fakeAuth = _FakeFirebaseAuth(fakeUser);
      final repo = LobbyRepository(
        firestore: _FakeFirestore(),
        functions: fakeFunctions,
        auth: fakeAuth,
      );

      await repo.deleteGame('game123');

      expect(fakeUser.tokenRefreshed, isTrue);
      final callable = fakeFunctions.callables['delete-game'];
      expect(callable, isNotNull);
      expect(callable!.calledWith, {'gameId': 'game123'});
    });

    test('GameRepository.deleteGame throws unauthenticated exception when not logged in', () async {
      final fakeFunctions = _FakeFirebaseFunctions();
      final fakeAuth = _FakeFirebaseAuth(null);
      final repo = GameRepository(
        firestore: _FakeFirestore(),
        functions: fakeFunctions,
        auth: fakeAuth,
      );

      expect(
        () => repo.deleteGame('game123'),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (e) => e.code,
            'code',
            'unauthenticated',
          ),
        ),
      );
      expect(fakeFunctions.callables.isEmpty, isTrue);
    });

    test('GameRepository.deleteGame refreshes token and calls delete-game callable when authenticated', () async {
      final fakeFunctions = _FakeFirebaseFunctions();
      final fakeUser = _FakeUser();
      final fakeAuth = _FakeFirebaseAuth(fakeUser);
      final repo = GameRepository(
        firestore: _FakeFirestore(),
        functions: fakeFunctions,
        auth: fakeAuth,
      );

      await repo.deleteGame('game123');

      expect(fakeUser.tokenRefreshed, isTrue);
      final callable = fakeFunctions.callables['delete-game'];
      expect(callable, isNotNull);
      expect(callable!.calledWith, {'gameId': 'game123'});
    });
  });
}
