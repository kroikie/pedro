import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/game_room.dart';
import '../../data/models/player.dart';
import '../../data/repositories/lobby_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/reaction_repository.dart';
import '../widgets/avatar_widget.dart';
import 'game_board_screen.dart';
import 'game_room_screen.dart';

class AllGamesScreen extends StatefulWidget {
  const AllGamesScreen({
    super.key,
    this.lobbyRepository,
    this.playerRepository,
    this.gameRepository,
    this.chatRepository,
    this.reactionRepository,
    this.currentUserId,
    this.initialTabIndex = 0,
  });

  final LobbyRepository? lobbyRepository;
  final PlayerRepository? playerRepository;
  final GameRepository? gameRepository;
  final ChatRepository? chatRepository;
  final ReactionRepository? reactionRepository;
  final String? currentUserId;
  final int initialTabIndex;

  @override
  State<AllGamesScreen> createState() => _AllGamesScreenState();
}

class _AllGamesScreenState extends State<AllGamesScreen> with SingleTickerProviderStateMixin {
  late final _lobbyRepository = widget.lobbyRepository ?? LobbyRepository();
  late final _playerRepository = widget.playerRepository ?? PlayerRepository();
  late final _currentUserId = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
  late final TabController _tabController;

  final Map<String, Player?> _playerCache = {};
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Player?> _getPlayer(String uid) async {
    if (_playerCache.containsKey(uid)) {
      return _playerCache[uid];
    }
    final player = await _playerRepository.getPlayer(uid);
    if (player != null) {
      _playerCache[uid] = player;
    }
    return player;
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}';
  }

  Future<void> _navigateToGame(GameRoom game, {bool isSpectator = false}) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      if (game.status == GameStatus.playing || game.status == GameStatus.finished) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameBoardScreen(
              gameId: game.id,
              gameName: game.name,
              gameRepository: widget.gameRepository,
              playerRepository: _playerRepository,
              chatRepository: widget.chatRepository,
              reactionRepository: widget.reactionRepository,
              currentUserId: _currentUserId,
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameRoomScreen(
              gameId: game.id,
              lobbyRepository: _lobbyRepository,
              playerRepository: _playerRepository,
              gameRepository: widget.gameRepository,
              chatRepository: widget.chatRepository,
              reactionRepository: widget.reactionRepository,
              currentUserId: _currentUserId,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Text(
          'All Games',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: const Color(0xFFF5F7F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Live Matches'),
            Tab(text: 'My Games'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveMatchesTab(),
          _buildMyGamesTab(),
        ],
      ),
    );
  }

  Widget _buildLiveMatchesTab() {
    return StreamBuilder<List<GameRoom>>(
      stream: _lobbyRepository.watchLiveGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final liveGames = snapshot.data ?? [];
        if (liveGames.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No live matches right now.',
                  style: GoogleFonts.beVietnamPro(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check back when a game begins!',
                  style: GoogleFonts.beVietnamPro(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: liveGames.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final game = liveGames[index];
            final isPlayer = game.playerIds.contains(_currentUserId);
            return _buildGameCard(game, isLiveTab: true, isPlayer: isPlayer);
          },
        );
      },
    );
  }

  Widget _buildMyGamesTab() {
    return StreamBuilder<List<GameRoom>>(
      stream: _lobbyRepository.watchMyGames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final myGames = snapshot.data ?? [];
        if (myGames.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.style_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'You have no active or past games.',
                  style: GoogleFonts.beVietnamPro(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: myGames.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final game = myGames[index];
            return _buildGameCard(game, isLiveTab: false, isPlayer: true);
          },
        );
      },
    );
  }

  Widget _buildGameCard(GameRoom game, {required bool isLiveTab, required bool isPlayer}) {
    final theme = Theme.of(context);
    final isActive = game.status == GameStatus.playing || game.status == GameStatus.starting;
    final viewerCount = game.viewerCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFFEFF1EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Color(0x0A00694B),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isActive ? 'LIVE NOW' : (game.status == GameStatus.waiting ? 'WAITING' : 'COMPLETED'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isActive
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isActive && viewerCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 11,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$viewerCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _formatRelativeTime(game.lastActivityAt),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            game.name,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target Score: ${game.targetScore} • ${game.playerIds.length} Players',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  for (int i = 0; i < (game.playerIds.length > 4 ? 4 : game.playerIds.length); i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: FutureBuilder<Player?>(
                        future: _getPlayer(game.playerIds[i]),
                        builder: (context, pSnap) {
                          return AvatarWidget(
                            avatarUrl: pSnap.data?.avatarUrl,
                            radius: 12,
                          );
                        },
                      ),
                    ),
                  if (game.playerIds.length > 4)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '+${game.playerIds.length - 4}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isNavigating
                    ? null
                    : () => _navigateToGame(game, isSpectator: !isPlayer),
                icon: Icon(
                  isPlayer
                      ? Icons.play_arrow
                      : (isActive ? Icons.visibility : Icons.remove_red_eye_outlined),
                  size: 16,
                ),
                label: Text(
                  isPlayer
                      ? (game.status == GameStatus.waiting
                          ? 'Lobby'
                          : (isActive ? 'Jump In' : 'View'))
                      : 'Watch Live',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isPlayer
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  foregroundColor: !isPlayer
                      ? theme.colorScheme.onSecondary
                      : theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
