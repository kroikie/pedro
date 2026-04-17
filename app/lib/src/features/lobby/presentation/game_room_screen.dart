import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/lobby_repository.dart';
import '../domain/game_room.dart';
import '../../player/data/player_repository.dart';
import '../../player/domain/player.dart';
import '../../../common_widgets/avatar_widget.dart';
import '../../game/data/game_repository.dart';
import '../../game/presentation/game_board_screen.dart';
import '../../chat/presentation/chat_overlay.dart';

class GameRoomScreen extends StatelessWidget {
  const GameRoomScreen({super.key, required this.gameId});

  final String gameId;

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => InviteDialog(gameId: gameId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lobbyRepository = LobbyRepository();
    final playerRepository = PlayerRepository();
    final gameRepository = GameRepository();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<GameRoom?>(
      stream: lobbyRepository.watchGame(gameId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final room = snapshot.data;
        if (room == null) {
          return const Scaffold(body: Center(child: Text('Game not found')));
        }

        if (room.status == GameStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => GameBoardScreen(gameId: gameId)),
            );
          });
        }

        final isHost = room.hostId == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              if (isHost)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showInviteDialog(context),
                  tooltip: 'Invite Player',
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Status: ${room.status.name}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      Text('Players (${room.playerIds.length}/4)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: room.playerIds.length,
                          itemBuilder: (context, index) {
                            final uid = room.playerIds[index];
                            return FutureBuilder<Player?>(
                              future: playerRepository.getPlayer(uid),
                              builder: (context, snapshot) {
                                final player = snapshot.data;
                                return ListTile(
                                  leading: AvatarWidget(avatarUrl: player?.avatarUrl, radius: 20),
                                  title: Text(player?.displayName ?? 'Loading...'),
                                  trailing: uid == room.hostId ? const Icon(Icons.star, color: Colors.amber) : null,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      if (isHost)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ElevatedButton(
                            onPressed: room.playerIds.length >= 4 ? () => gameRepository.startGame(gameId) : null,
                            child: const Text('Start Game'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ChatOverlay(gameId: gameId),
            ],
          ),
        );
      },
    );
  }
}

class InviteDialog extends StatelessWidget {
  const InviteDialog({super.key, required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context) {
    final playerRepo = PlayerRepository();
    final lobbyRepo = LobbyRepository();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return AlertDialog(
      title: const Text('Invite Player'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<List<Player>>(
          stream: playerRepo.watchAllPlayers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final players = snapshot.data!.where((p) => p.id != currentUid).toList();
            if (players.isEmpty) return const Center(child: Text('No other players found.'));

            return ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  leading: AvatarWidget(avatarUrl: player.avatarUrl, radius: 15),
                  title: Text(player.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      await lobbyRepo.invitePlayer(gameId, player.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invited ${player.displayName}')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
