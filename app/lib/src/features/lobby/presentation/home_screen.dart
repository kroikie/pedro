import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/lobby_repository.dart';
import '../domain/game_room.dart';
import '../application/game_name_service.dart';
import 'game_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _lobbyRepository = LobbyRepository();
  final _gameNameService = GameNameService();
  bool _isCreating = false;

  Future<void> _createGame() async {
    setState(() => _isCreating = true);
    try {
      final name = await _gameNameService.generateRoomName();
      final gameId = await _lobbyRepository.createGame(name);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GameRoomScreen(gameId: gameId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinGame(String gameId) async {
    try {
      await _lobbyRepository.joinGame(gameId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GameRoomScreen(gameId: gameId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error joining game: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedro Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createGame,
              icon: _isCreating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: const Text('Create New Game'),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<GameRoom>>(
              stream: _lobbyRepository.watchGames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final games = snapshot.data ?? [];
                if (games.isEmpty) {
                  return const Center(child: Text('No active games. Create one!'));
                }
                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return ListTile(
                      title: Text(game.name),
                      subtitle: Text('Players: ${game.playerIds.length}/4'),
                      trailing: ElevatedButton(
                        onPressed: () => _joinGame(game.id),
                        child: const Text('Join'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
