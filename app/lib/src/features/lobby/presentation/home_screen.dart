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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pedro Lobby'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Games', icon: Icon(Icons.videogame_asset)),
              Tab(text: 'Inbox', icon: Icon(Icons.mail)),
            ],
          ),
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
        body: TabBarView(
          children: [
            _buildMyGames(),
            _buildInbox(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isCreating ? null : _createGame,
          icon: _isCreating 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add),
          label: const Text('New Game'),
        ),
      ),
    );
  }

  Widget _buildMyGames() {
    return StreamBuilder<List<GameRoom>>(
      stream: _lobbyRepository.watchMyGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final games = snapshot.data ?? [];
        if (games.isEmpty) {
          return const Center(child: Text('No active games.'));
        }
        return ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return ListTile(
              title: Text(game.name),
              subtitle: Text('Status: ${game.status.name} • Players: ${game.playerIds.length}'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GameRoomScreen(gameId: game.id)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInbox() {
    return StreamBuilder<List<GameRoom>>(
      stream: _lobbyRepository.watchInvitations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final games = snapshot.data ?? [];
        if (games.isEmpty) {
          return const Center(child: Text('Your inbox is empty.'));
        }
        return ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return ListTile(
              title: Text(game.name),
              subtitle: const Text('You have been invited to join!'),
              trailing: ElevatedButton(
                onPressed: () => _joinGame(game.id),
                child: const Text('Accept'),
              ),
            );
          },
        );
      },
    );
  }
}
