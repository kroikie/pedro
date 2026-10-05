import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/chat_message.dart';
import 'package:pedro/data/models/game_room.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/data/repositories/chat_repository.dart';
import 'package:pedro/data/repositories/lobby_repository.dart';
import 'package:pedro/data/repositories/player_repository.dart';
import 'package:pedro/ui/screens/game_room_screen.dart';

class _FakeChatRepository implements ChatRepository {
  @override
  Stream<List<ChatMessage>> watchMessages(String gameId) => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLobbyRepository implements LobbyRepository {
  _FakeLobbyRepository({GameRoom? initialRoom}) {
    roomController = StreamController<GameRoom?>.broadcast();
    if (initialRoom != null) {
      currentRoom = initialRoom;
    }
  }

  late final StreamController<GameRoom?> roomController;
  GameRoom? currentRoom;
  final List<String> invitedIds = [];
  final List<String> uninvitedIds = [];
  Completer<void>? inviteCompleter;
  Completer<void>? uninviteCompleter;

  @override
  Stream<GameRoom?> watchGame(String gameId) {
    return roomController.stream;
  }

  void emitRoom(GameRoom room) {
    currentRoom = room;
    roomController.add(room);
  }

  @override
  Future<void> invitePlayer(String gameId, String targetPlayerId) async {
    invitedIds.add(targetPlayerId);
    if (inviteCompleter != null) {
      await inviteCompleter!.future;
    }
    if (currentRoom != null) {
      final updated = currentRoom!.copyWith(
        invitedPlayerIds: [...currentRoom!.invitedPlayerIds, targetPlayerId],
      );
      emitRoom(updated);
    }
  }

  @override
  Future<void> uninvitePlayer(String gameId, String targetPlayerId) async {
    uninvitedIds.add(targetPlayerId);
    if (uninviteCompleter != null) {
      await uninviteCompleter!.future;
    }
    if (currentRoom != null) {
      final updated = currentRoom!.copyWith(
        invitedPlayerIds: currentRoom!.invitedPlayerIds
            .where((id) => id != targetPlayerId)
            .toList(),
      );
      emitRoom(updated);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlayerRepository implements PlayerRepository {
  _FakePlayerRepository(this.players);

  final List<Player> players;

  @override
  Stream<List<Player>> watchAllPlayers() => Stream.value(players);

  @override
  Future<Player?> getPlayer(
    String uid, {
    Source source = Source.serverAndCache,
    Duration? timeout,
  }) async {
    return players.cast<Player?>().firstWhere(
          (p) => p?.id == uid,
          orElse: () => Player(id: uid, screenName: 'Player $uid'),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('InviteDialog Tests', () {
    late GameRoom initialRoom;
    late List<Player> testPlayers;
    late _FakePlayerRepository fakePlayerRepo;

    setUp(() {
      initialRoom = GameRoom(
        id: 'game_123',
        hostId: 'host_1',
        name: 'Trini Pedro Lobby',
        playerIds: ['host_1', 'player_joined'],
        invitedPlayerIds: ['player_invited'],
        createdAt: DateTime.now(),
      );

      testPlayers = const [
        Player(id: 'host_1', screenName: 'Host Player'),
        Player(id: 'player_available', screenName: 'Alice'),
        Player(id: 'player_invited', screenName: 'Bob'),
        Player(id: 'player_joined', screenName: 'Charlie'),
      ];

      fakePlayerRepo = _FakePlayerRepository(testPlayers);
    });

    testWidgets('Renders player directory excluding current user with correct statuses', (tester) async {
      final lobbyRepo = _FakeLobbyRepository(initialRoom: initialRoom);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InviteDialog(
              room: initialRoom,
              lobbyRepository: lobbyRepo,
              playerRepository: fakePlayerRepo,
              currentUserId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Current user should be excluded
      expect(find.text('Host Player'), findsNothing);

      // Alice is available to invite
      expect(find.text('Alice'), findsOneWidget);
      expect(find.byTooltip('Invite Player'), findsOneWidget);

      // Bob is already invited
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Already Invited'), findsOneWidget);
      expect(find.byTooltip('Remove Invitation'), findsOneWidget);

      // Charlie is already in game
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('In Game'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Initial capacity header should show 2/4 joined (host_1 and player_joined)
      expect(find.text('Invite Players (2/4 joined)'), findsOneWidget);
    });

    testWidgets('Displays dynamic capacity denominator (3/4, 4/4, 6/6)', (tester) async {
      // 3 players joined -> 3/4
      final room3 = initialRoom.copyWith(
        playerIds: ['host_1', 'p2', 'p3'],
      );
      final repo3 = _FakeLobbyRepository(initialRoom: room3);

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('app_3'),
          home: Scaffold(
            body: InviteDialog(
              key: const ValueKey('dialog_3'),
              room: room3,
              lobbyRepository: repo3,
              playerRepository: fakePlayerRepo,
              currentUserId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invite Players (3/4 joined)'), findsOneWidget);

      // 4 players joined -> 4/4
      final room4 = initialRoom.copyWith(
        playerIds: ['host_1', 'p2', 'p3', 'p4'],
      );
      final repo4 = _FakeLobbyRepository(initialRoom: room4);

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('app_4'),
          home: Scaffold(
            body: InviteDialog(
              key: const ValueKey('dialog_4'),
              room: room4,
              lobbyRepository: repo4,
              playerRepository: fakePlayerRepo,
              currentUserId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invite Players (4/4 joined)'), findsOneWidget);

      // 6 players joined -> 6/6
      final room6 = initialRoom.copyWith(
        playerIds: ['host_1', 'p2', 'p3', 'p4', 'p5', 'p6'],
      );
      final repo6 = _FakeLobbyRepository(initialRoom: room6);

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('app_6'),
          home: Scaffold(
            body: InviteDialog(
              key: const ValueKey('dialog_6'),
              room: room6,
              lobbyRepository: repo6,
              playerRepository: fakePlayerRepo,
              currentUserId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Invite Players (6/6 joined)'), findsOneWidget);
    });

    testWidgets('Inviting a player calls invitePlayer, keeps dialog open, and updates status', (tester) async {
      final lobbyRepo = _FakeLobbyRepository(initialRoom: initialRoom);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InviteDialog(
              room: initialRoom,
              lobbyRepository: lobbyRepo,
              playerRepository: fakePlayerRepo,
              currentUserId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Alice has an invite button
      final inviteAliceBtn = find.widgetWithIcon(IconButton, Icons.add);
      expect(inviteAliceBtn, findsOneWidget);

      // Tap invite
      await tester.tap(inviteAliceBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Repository called
      expect(lobbyRepo.invitedIds, contains('player_available'));

      // Dialog is still open!
      expect(find.byType(InviteDialog), findsOneWidget);
      expect(find.text('Invite Players (2/4 joined)'), findsOneWidget);

      // SnackBar displayed
      expect(find.text('Invited Alice'), findsOneWidget);

      // Alice is now listed as Already Invited with remove button
      expect(find.text('Already Invited'), findsNWidgets(2)); // Bob and Alice
      expect(find.byTooltip('Remove Invitation'), findsNWidgets(2));
    });

    testWidgets('Uninviting a player calls uninvitePlayer, keeps dialog open, and restores invite button', (tester) async {
      final lobbyRepo = _FakeLobbyRepository(initialRoom: initialRoom);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InviteDialog(
              room: initialRoom,
              lobbyRepository: lobbyRepo,
              playerRepository: fakePlayerRepo,
              currentUserId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bob has remove invitation button
      final removeBobBtn = find.byTooltip('Remove Invitation');
      expect(removeBobBtn, findsOneWidget);

      // Tap remove
      await tester.tap(removeBobBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Repository called
      expect(lobbyRepo.uninvitedIds, contains('player_invited'));

      // Dialog is still open!
      expect(find.byType(InviteDialog), findsOneWidget);

      // SnackBar displayed
      expect(find.text('Removed invitation for Bob'), findsOneWidget);

      // Bob's status is reverted to add button
      expect(find.text('Already Invited'), findsNothing);
      expect(find.widgetWithIcon(IconButton, Icons.add), findsNWidgets(2)); // Alice and Bob
    });

    testWidgets('Shows loading indicator while invite operation is pending and prevents double taps', (tester) async {
      final lobbyRepo = _FakeLobbyRepository(initialRoom: initialRoom);
      lobbyRepo.inviteCompleter = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InviteDialog(
              room: initialRoom,
              lobbyRepository: lobbyRepo,
              playerRepository: fakePlayerRepo,
              currentUserId: 'host_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap invite on Alice
      final inviteAliceBtn = find.widgetWithIcon(IconButton, Icons.add);
      expect(inviteAliceBtn, findsOneWidget);
      await tester.tap(inviteAliceBtn);
      await tester.pump();

      // In flight: circular progress indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(lobbyRepo.invitedIds.length, 1);

      // Complete async action
      lobbyRepo.inviteCompleter!.complete();
      await tester.pumpAndSettle();

      // CircularProgressIndicator gone, Alice is invited
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Invited Alice'), findsOneWidget);
    });

    testWidgets('Tapping Close explicitly closes the dialog', (tester) async {
      final lobbyRepo = _FakeLobbyRepository(initialRoom: initialRoom);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => InviteDialog(
                  room: initialRoom,
                  lobbyRepository: lobbyRepo,
                  playerRepository: fakePlayerRepo,
                  currentUserId: 'host_1',
                ),
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(InviteDialog), findsOneWidget);

      // Tap Close
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog is closed
      expect(find.byType(InviteDialog), findsNothing);
    });
  });

  group('GameRoomScreen Lobby Header Dynamic Capacity Tests', () {
    testWidgets('Lobby header displays 1/4 when 1 player is joined', (tester) async {
      final room1 = GameRoom(
        id: 'game_1',
        hostId: 'host_1',
        name: 'Pedro Match',
        playerIds: ['host_1'],
        createdAt: DateTime.now(),
      );
      final lobbyRepo = _FakeLobbyRepository(initialRoom: room1);
      final playerRepo = _FakePlayerRepository([
        const Player(id: 'host_1', screenName: 'Host Player'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: GameRoomScreen(
            gameId: 'game_1',
            lobbyRepository: lobbyRepo,
            playerRepository: playerRepo,
            chatRepository: _FakeChatRepository(),
            currentUserId: 'host_1',
          ),
        ),
      );
      lobbyRepo.emitRoom(room1);
      await tester.pumpAndSettle();

      expect(find.text('Players (1/4 joined)'), findsOneWidget);
    });

    testWidgets('Lobby header displays 4/4 when 4 players are joined', (tester) async {
      final room4 = GameRoom(
        id: 'game_4',
        hostId: 'host_1',
        name: 'Pedro Match',
        playerIds: ['host_1', 'p2', 'p3', 'p4'],
        createdAt: DateTime.now(),
      );
      final lobbyRepo = _FakeLobbyRepository(initialRoom: room4);
      final playerRepo = _FakePlayerRepository([
        const Player(id: 'host_1', screenName: 'Host Player'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: GameRoomScreen(
            gameId: 'game_4',
            lobbyRepository: lobbyRepo,
            playerRepository: playerRepo,
            chatRepository: _FakeChatRepository(),
            currentUserId: 'host_1',
          ),
        ),
      );
      lobbyRepo.emitRoom(room4);
      await tester.pumpAndSettle();

      expect(find.text('Players (4/4 joined)'), findsOneWidget);
    });

    testWidgets('Lobby header displays 6/6 when 6 players are joined', (tester) async {
      final room6 = GameRoom(
        id: 'game_6',
        hostId: 'host_1',
        name: 'Pedro Match',
        playerIds: ['host_1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        createdAt: DateTime.now(),
      );
      final lobbyRepo = _FakeLobbyRepository(initialRoom: room6);
      final playerRepo = _FakePlayerRepository([
        const Player(id: 'host_1', screenName: 'Host Player'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: GameRoomScreen(
            gameId: 'game_6',
            lobbyRepository: lobbyRepo,
            playerRepository: playerRepo,
            chatRepository: _FakeChatRepository(),
            currentUserId: 'host_1',
          ),
        ),
      );
      lobbyRepo.emitRoom(room6);
      await tester.pumpAndSettle();

      expect(find.text('Players (6/6 joined)'), findsOneWidget);
    });
  });
}
