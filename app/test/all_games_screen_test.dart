import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/game_room.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/data/repositories/lobby_repository.dart';
import 'package:pedro/data/repositories/player_repository.dart';
import 'package:pedro/ui/screens/all_games_screen.dart';

class MockLobbyRepository implements LobbyRepository {
  List<GameRoom> liveGames = [];
  List<GameRoom> myGames = [];

  @override
  Stream<List<GameRoom>> watchLiveGames() => Stream.value(liveGames);

  @override
  Stream<List<GameRoom>> watchMyGames() => Stream.value(myGames);

  @override
  Stream<GameRoom?> watchGame(String gameId) => Stream.value(null);

  @override
  Stream<List<GameRoom>> watchInvitations() => Stream.value([]);

  @override
  Future<String> createGame(String roomName, {int targetScore = 35}) async => 'new_game';

  @override
  Future<void> joinGame(String gameId) async {}

  @override
  Future<void> invitePlayer(String gameId, String targetPlayerId) async {}

  @override
  Future<void> uninvitePlayer(String gameId, String targetPlayerId) async {}

  @override
  Future<void> deleteGame(String gameId) async {}

  @override
  Future<void> joinGameAsViewer(String gameId) async {}

  @override
  Future<void> heartbeatViewer(String gameId) async {}

  @override
  Future<void> leaveGameViewer(String gameId) async {}
}

class MockPlayerRepository implements PlayerRepository {
  @override
  Future<Player?> getPlayer(
    String uid, {
    Source source = Source.serverAndCache,
    Duration? timeout,
  }) async {
    return Player(id: uid, screenName: 'Player $uid');
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
  Stream<Player?> watchPlayer(String uid) => Stream.value(Player(id: uid, screenName: 'Player $uid'));

  @override
  Stream<List<Player>> watchAllPlayers() => Stream.value([]);
}

void main() {
  testWidgets('AllGamesScreen displays Live Matches and handles Jump In vs Watch Live', (tester) async {
    final lobbyRepo = MockLobbyRepository();
    final playerRepo = MockPlayerRepository();

    final now = DateTime.now().toUtc();
    lobbyRepo.liveGames = [
      GameRoom(
        id: 'game_player',
        name: 'Player Match',
        hostId: 'host_1',
        playerIds: const ['current_user', 'p2', 'p3', 'p4'],
        status: GameStatus.playing,
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 2)),
        targetScore: 35,
        isOpen: true,
        viewerIds: const ['v1', 'v2'],
      ),
      GameRoom(
        id: 'game_spectate',
        name: 'Spectator Match',
        hostId: 'host_2',
        playerIds: const ['p2', 'p3', 'p4', 'p5'],
        status: GameStatus.playing,
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now.subtract(const Duration(minutes: 1)),
        targetScore: 35,
        isOpen: true,
        viewerIds: const ['v1'],
      ),
    ];

    lobbyRepo.myGames = [
      GameRoom(
        id: 'game_my_lobby',
        name: 'My Waiting Lobby',
        hostId: 'current_user',
        playerIds: const ['current_user'],
        status: GameStatus.waiting,
        createdAt: now.subtract(const Duration(minutes: 15)),
        targetScore: 35,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AllGamesScreen(
          lobbyRepository: lobbyRepo,
          playerRepository: playerRepo,
          currentUserId: 'current_user',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and tabs
    expect(find.text('All Games'), findsOneWidget);
    expect(find.text('Live Matches'), findsOneWidget);
    expect(find.text('My Games'), findsOneWidget);

    // Verify games listed
    expect(find.text('Player Match'), findsOneWidget);
    expect(find.text('Spectator Match'), findsOneWidget);

    // Seated player game should display "Jump In"
    expect(find.text('Jump In'), findsOneWidget);

    // Spectator game should display "Watch Live"
    expect(find.text('Watch Live'), findsOneWidget);

    // Live spectators counts (2 viewers on first, 1 viewer on second)
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Switch to "My Games" tab
    await tester.tap(find.text('My Games'));
    await tester.pumpAndSettle();

    // In My Games tab
    expect(find.text('My Waiting Lobby'), findsOneWidget);
    expect(find.text('Lobby'), findsOneWidget);
  });

  testWidgets('AllGamesScreen displays empty state when no live matches', (tester) async {
    final lobbyRepo = MockLobbyRepository();
    final playerRepo = MockPlayerRepository();

    lobbyRepo.liveGames = [];
    lobbyRepo.myGames = [];

    await tester.pumpWidget(
      MaterialApp(
        home: AllGamesScreen(
          lobbyRepository: lobbyRepo,
          playerRepository: playerRepo,
          currentUserId: 'current_user',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No live matches right now.'), findsOneWidget);
  });
}
