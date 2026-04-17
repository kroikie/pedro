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

  @override
  Widget build(BuildContext context) {
    final lobbyRepository = LobbyRepository();
    final playerRepository = PlayerRepository();
    final gameRepository = GameRepository();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<GameRoom?>(
      stream: lobbyRepository.watchGame(gameId),
      builder: (context, snapshot) {
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
          appBar: AppBar(title: Text(room.name)),
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
                        ElevatedButton(
                          onPressed: room.playerIds.length >= 4 ? () => gameRepository.startGame(gameId) : null,
                          child: const Text('Start Game'),
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
