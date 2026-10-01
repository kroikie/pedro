import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final List<int> _transparentPng = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

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
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLobbyRepository implements LobbyRepository {
  final _gameController = StreamController<GameRoom?>.broadcast();
  final _myGamesController = StreamController<List<GameRoom>>.broadcast();
  final _invitationsController = StreamController<List<GameRoom>>.broadcast();

  void emitGame(GameRoom? room) => _gameController.add(room);
  void emitMyGames(List<GameRoom> games) => _myGamesController.add(games);
  void emitInvitations(List<GameRoom> invites) =>
      _invitationsController.add(invites);

  @override
  Stream<GameRoom?> watchGame(String gameId) => _gameController.stream;

  @override
  Stream<List<GameRoom>> watchMyGames() => _myGamesController.stream;

  @override
  Stream<List<GameRoom>> watchInvitations() => _invitationsController.stream;

  @override
  Future<String> createGame(String roomName, {int targetScore = 35}) async =>
      'new_game_id';

  @override
  Future<void> joinGame(String gameId) async {}

  @override
  Future<void> invitePlayer(String gameId, String targetPlayerId) async {}

  @override
  Future<void> uninvitePlayer(String gameId, String targetPlayerId) async {}
}

class FakePlayerRepository implements PlayerRepository {
  final Map<String, Completer<Player?>> completers = {};

  @override
  Future<Player?> getPlayer(String uid) {
    if (completers.containsKey(uid)) {
      return completers[uid]!.future;
    }
    return Future.value(Player(id: uid, screenName: 'Player $uid'));
  }

  @override
  Stream<List<Player>> watchAllPlayers() => Stream.value([]);

  @override
  Future<void> updatePlayer(Player player) async {}

  @override
  Future<void> addFcmToken(String uid, String token, String platform) async {}

  @override
  Future<void> removeFcmToken(String uid, String token) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGameRepository implements GameRepository {
  @override
  Stream<GameSession?> watchGameSession(String gameId) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChatRepository implements ChatRepository {
  @override
  Stream<List<ChatMessage>> watchMessages(String gameId) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReactionRepository implements ReactionRepository {
  @override
  Stream<List<GameReaction>> watchRecentReactions(String gameId) =>
      const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      replacedRoutes.add(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  group('Game Navigation & Double-Load Prevention', () {
    late FakeLobbyRepository fakeLobbyRepo;
    late FakePlayerRepository fakePlayerRepo;
    late FakeGameRepository fakeGameRepo;
    late FakeChatRepository fakeChatRepo;
    late FakeReactionRepository fakeReactionRepo;
    late TestNavigatorObserver navObserver;

    setUp(() {
      fakeLobbyRepo = FakeLobbyRepository();
      fakePlayerRepo = FakePlayerRepository();
      fakeGameRepo = FakeGameRepository();
      fakeChatRepo = FakeChatRepository();
      fakeReactionRepo = FakeReactionRepository();
      navObserver = TestNavigatorObserver();
    });

    testWidgets(
        'GameRoomScreen triggers pushReplacement to GameBoardScreen exactly once when playing',
        (tester) async {
      final room = GameRoom(
        id: 'game_123',
        hostId: 'host_uid',
        name: 'lucky_player',
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        status: GameStatus.playing,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navObserver],
          home: GameRoomScreen(
            gameId: 'game_123',
            lobbyRepository: fakeLobbyRepo,
            playerRepository: fakePlayerRepo,
            gameRepository: fakeGameRepo,
            chatRepository: fakeChatRepo,
            reactionRepository: fakeReactionRepo,
            currentUserId: 'p1',
          ),
        ),
      );

      // Initial pump: stream waiting
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Emit game with playing status
      fakeLobbyRepo.emitGame(room);
      await tester.pump();

      // Flush post-frame callbacks
      await tester.pump(const Duration(milliseconds: 100));

      // Re-emit multiple times to simulate Firestore snapshot updates
      fakeLobbyRepo.emitGame(room);
      await tester.pump(const Duration(milliseconds: 50));
      fakeLobbyRepo.emitGame(room);
      await tester.pump(const Duration(milliseconds: 50));

      // Exactly ONE replacement should have occurred
      final gameBoardReplacements = navObserver.replacedRoutes.where(
        (route) =>
            route is MaterialPageRoute &&
            route.builder(tester.element(find.byType(GameBoardScreen).first))
                is GameBoardScreen,
      );
      expect(gameBoardReplacements.length, 1);
    });

    testWidgets(
        'HomeFeedView navigates directly to GameBoardScreen when game is playing',
        (tester) async {
      final playingGame = GameRoom(
        id: 'playing_game_1',
        name: 'Epic Match',
        hostId: 'h1',
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        status: GameStatus.playing,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navObserver],
          home: Scaffold(
            body: HomeFeedView(
              onCreateGameTap: () {},
              onViewAllGamesTap: () {},
              lobbyRepository: fakeLobbyRepo,
              playerRepository: fakePlayerRepo,
              gameRepository: fakeGameRepo,
              chatRepository: fakeChatRepo,
              reactionRepository: fakeReactionRepo,
              currentUserId: 'p1',
            ),
          ),
        ),
      );

      fakeLobbyRepo.emitMyGames([playingGame]);
      fakeLobbyRepo.emitInvitations([]);
      await tester.pump();

      expect(find.text('Jump In'), findsOneWidget);

      await tester.tap(find.text('Jump In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should push directly to GameBoardScreen, bypassing GameRoomScreen
      expect(find.byType(GameBoardScreen), findsOneWidget);
      expect(find.byType(GameRoomScreen), findsNothing);
    });

    testWidgets(
        'HomeFeedView navigates to GameRoomScreen when game is waiting',
        (tester) async {
      final waitingGame = GameRoom(
        id: 'waiting_game_1',
        name: 'Waiting Lobby',
        hostId: 'h1',
        playerIds: ['p1'],
        status: GameStatus.waiting,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navObserver],
          home: Scaffold(
            body: HomeFeedView(
              onCreateGameTap: () {},
              onViewAllGamesTap: () {},
              lobbyRepository: fakeLobbyRepo,
              playerRepository: fakePlayerRepo,
              gameRepository: fakeGameRepo,
              chatRepository: fakeChatRepo,
              reactionRepository: fakeReactionRepo,
              currentUserId: 'p1',
            ),
          ),
        ),
      );

      fakeLobbyRepo.emitMyGames([waitingGame]);
      fakeLobbyRepo.emitInvitations([]);
      await tester.pump();

      expect(find.text('View'), findsOneWidget);

      await tester.tap(find.text('View'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should push GameRoomScreen
      expect(find.byType(GameRoomScreen), findsOneWidget);
      expect(find.byType(GameBoardScreen), findsNothing);
    });
  });
}
