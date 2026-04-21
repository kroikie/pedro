import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/lobby_repository.dart';
import '../../data/models/game_room.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/models/player.dart';
import '../widgets/avatar_widget.dart';
import '../../data/repositories/game_repository.dart';
import 'game_board_screen.dart';
import '../widgets/chat_overlay.dart';

class GameRoomScreen extends StatefulWidget {
  const GameRoomScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  final _lobbyRepository = LobbyRepository();
  final _playerRepository = PlayerRepository();
  final _gameRepository = GameRepository();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final Map<String, Player?> _playerCache = {};

  void _showInviteDialog(BuildContext context, GameRoom room) {
    showDialog(
      context: context,
      builder: (context) => InviteDialog(room: room),
    );
  }

  Future<Player?> _getPlayer(String uid) async {
    if (_playerCache.containsKey(uid)) {
      return _playerCache[uid];
    }
    final player = await _playerRepository.getPlayer(uid);
    if (mounted) {
      setState(() => _playerCache[uid] = player);
    }
    return player;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameRoom?>(
      stream: _lobbyRepository.watchGame(widget.gameId),
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
              MaterialPageRoute(builder: (context) => GameBoardScreen(gameId: widget.gameId)),
            );
          });
        }

        final isHost = room.hostId == _currentUserId;
        final allParticipants = [...room.playerIds, ...room.invitedPlayerIds];

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              if (isHost)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showInviteDialog(context, room),
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
                      Text('Players (${room.playerIds.length}/4 joined)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: allParticipants.length,
                          itemBuilder: (context, index) {
                            final uid = allParticipants[index];
                            final isInvitedOnly = index >= room.playerIds.length;
                            
                            return FutureBuilder<Player?>(
                              future: _getPlayer(uid),
                              builder: (context, snapshot) {
                                final player = snapshot.data;
                                return Opacity(
                                  opacity: isInvitedOnly ? 0.6 : 1.0,
                                  child: ListTile(
                                    leading: AvatarWidget(avatarUrl: player?.avatarUrl, radius: 20),
                                    title: Text(player?.screenName ?? 'Loading...'),
                                    subtitle: isInvitedOnly ? const Text('Invitation Pending...', style: TextStyle(fontStyle: FontStyle.italic)) : null,
                                    trailing: uid == room.hostId 
                                      ? const Icon(Icons.star, color: Colors.amber) 
                                      : (isInvitedOnly 
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isHost)
                                                  IconButton(
                                                    icon: const Icon(Icons.person_remove, color: Colors.red, size: 20),
                                                    onPressed: () => _lobbyRepository.uninvitePlayer(widget.gameId, uid),
                                                    tooltip: 'Remove Invitation',
                                                  ),
                                                const Icon(Icons.hourglass_empty, size: 16),
                                              ],
                                            )
                                          : null),
                                  ),
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
                            onPressed: room.playerIds.length >= 4 ? () => _gameRepository.startGame(widget.gameId) : null,
                            child: const Text('Start Game'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ChatOverlay(gameId: widget.gameId),
            ],
          ),
        );
      },
    );
  }
}

class InviteDialog extends StatelessWidget {
  const InviteDialog({super.key, required this.room});
  final GameRoom room;

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
                final isJoined = room.playerIds.contains(player.id);
                final isInvited = room.invitedPlayerIds.contains(player.id);
                final canInvite = !isJoined && !isInvited;

                return ListTile(
                  leading: AvatarWidget(avatarUrl: player.avatarUrl, radius: 15),
                  title: Text(player.screenName),
                  subtitle: isJoined ? const Text('In Game') : (isInvited ? const Text('Already Invited') : null),
                  trailing: canInvite 
                    ? IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          await lobbyRepo.invitePlayer(room.id, player.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invited ${player.screenName}')),
                            );
                          }
                        },
                      )
                    : (isInvited 
                        ? IconButton(
                            icon: const Icon(Icons.person_remove, color: Colors.red),
                            onPressed: () async {
                              await lobbyRepo.uninvitePlayer(room.id, player.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Removed invitation for ${player.screenName}')),
                                );
                              }
                            },
                          )
                        : const Icon(Icons.check, color: Colors.green)),
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
