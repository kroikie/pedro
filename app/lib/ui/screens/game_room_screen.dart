import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/lobby_repository.dart';
import '../../data/models/game_room.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/models/player.dart';
import '../widgets/avatar_widget.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/reaction_repository.dart';
import 'game_board_screen.dart';
import '../widgets/chat_overlay.dart';
import '../widgets/app_version_footer.dart';

class GameRoomScreen extends StatefulWidget {
  const GameRoomScreen({
    super.key,
    required this.gameId,
    this.lobbyRepository,
    this.playerRepository,
    this.gameRepository,
    this.chatRepository,
    this.reactionRepository,
    this.currentUserId,
  });

  final String gameId;
  final LobbyRepository? lobbyRepository;
  final PlayerRepository? playerRepository;
  final GameRepository? gameRepository;
  final ChatRepository? chatRepository;
  final ReactionRepository? reactionRepository;
  final String? currentUserId;

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  late final _lobbyRepository = widget.lobbyRepository ?? LobbyRepository();
  late final _playerRepository = widget.playerRepository ?? PlayerRepository();
  late final _gameRepository = widget.gameRepository ?? GameRepository();
  late final _currentUserId =
      widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
  final Map<String, Player> _playerCache = {};
  final Map<String, Future<Player?>> _playerFutureCache = {};
  late Stream<GameRoom?> _gameRoomStream;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _gameRoomStream = _lobbyRepository.watchGame(widget.gameId);
  }

  @override
  void didUpdateWidget(covariant GameRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId ||
        oldWidget.lobbyRepository != widget.lobbyRepository) {
      _gameRoomStream = _lobbyRepository.watchGame(widget.gameId);
    }
  }

  void _showInviteDialog(BuildContext context, GameRoom room) {
    showDialog(
      context: context,
      builder: (context) => InviteDialog(
        room: room,
        playerRepository: _playerRepository,
        lobbyRepository: _lobbyRepository,
        currentUserId: _currentUserId,
      ),
    );
  }

  Future<void> _confirmDeleteGame(BuildContext context, GameRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text(
          'Are you sure you want to delete "${room.name}"? This action cannot be undone and will remove the game for all players.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _lobbyRepository.deleteGame(room.id);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Game "${room.name}" deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete game: $e')),
          );
        }
      }
    }
  }

  Future<Player?> _getPlayer(String uid) {
    return _playerFutureCache.putIfAbsent(uid, () async {
      final player = await _playerRepository.getPlayer(uid);
      if (player != null && mounted) {
        _playerCache[uid] = player;
      }
      return player;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameRoom?>(
      stream: _gameRoomStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final room = snapshot.data;
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Game Room')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Game not found or has been deleted.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Lobby'),
                  ),
                ],
              ),
            ),
          );
        }

        if (room.status == GameStatus.playing && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameBoardScreen(
                  gameId: widget.gameId,
                  gameName: room.name,
                  gameRepository: _gameRepository,
                  playerRepository: _playerRepository,
                  chatRepository: widget.chatRepository,
                  reactionRepository: widget.reactionRepository,
                  currentUserId: _currentUserId,
                ),
              ),
            );
          });
        }

        final isHost = room.hostId == _currentUserId;
        final allParticipants = [...room.playerIds, ...room.invitedPlayerIds];

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              if (isHost) ...[
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showInviteDialog(context, room),
                  tooltip: 'Invite Player',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDeleteGame(context, room),
                  tooltip: 'Delete Game',
                ),
              ],
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Game & App Info',
                onPressed: () => showPedroAboutDialog(
                  context,
                  gameId: widget.gameId,
                ),
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
                              initialData: _playerCache[uid],
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
              ChatOverlay(
                gameId: widget.gameId,
                chatRepository: widget.chatRepository,
                playerRepository: _playerRepository,
                currentUserId: _currentUserId,
              ),
            ],
          ),
        );
      },
    );
  }
}

class InviteDialog extends StatelessWidget {
  const InviteDialog({
    super.key,
    required this.room,
    this.playerRepository,
    this.lobbyRepository,
    this.currentUserId,
  });

  final GameRoom room;
  final PlayerRepository? playerRepository;
  final LobbyRepository? lobbyRepository;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final playerRepo = playerRepository ?? PlayerRepository();
    final lobbyRepo = lobbyRepository ?? LobbyRepository();
    final currentUid =
        currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

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
