import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/lobby_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/reaction_repository.dart';
import '../../data/models/game_room.dart';
import '../../data/models/player.dart';
import 'game_room_screen.dart';
import 'game_board_screen.dart';
import '../widgets/avatar_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeFeedView extends StatefulWidget {
  const HomeFeedView({
    super.key,
    required this.onCreateGameTap,
    required this.onViewAllGamesTap,
    this.lobbyRepository,
    this.playerRepository,
    this.gameRepository,
    this.chatRepository,
    this.reactionRepository,
    this.currentUserId,
  });

  final VoidCallback onCreateGameTap;
  final VoidCallback onViewAllGamesTap;
  final LobbyRepository? lobbyRepository;
  final PlayerRepository? playerRepository;
  final GameRepository? gameRepository;
  final ChatRepository? chatRepository;
  final ReactionRepository? reactionRepository;
  final String? currentUserId;

  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView> {
  late final _lobbyRepository = widget.lobbyRepository ?? LobbyRepository();
  late final _playerRepository = widget.playerRepository ?? PlayerRepository();
  late final _currentUserId = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
  final Map<String, Player?> _hostCache = {};
  bool _isNavigating = false;

  Future<Player?> _getHostPlayer(String hostId) async {
    if (_hostCache.containsKey(hostId)) {
      return _hostCache[hostId];
    }
    final player = await _playerRepository.getPlayer(hostId);
    if (player != null) {
      _hostCache[hostId] = player;
    }
    return player;
  }

  Future<void> _navigateToGame(GameRoom game) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      if (game.status == GameStatus.playing) {
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
              currentUserId: widget.currentUserId,
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
              currentUserId: widget.currentUserId,
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

  Future<void> _acceptInvitation(GameRoom invite) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      await _lobbyRepository.joinGame(invite.id);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameRoomScreen(
              gameId: invite.id,
              lobbyRepository: _lobbyRepository,
              playerRepository: _playerRepository,
              gameRepository: widget.gameRepository,
              chatRepository: widget.chatRepository,
              reactionRepository: widget.reactionRepository,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> _confirmDeleteGame(BuildContext context, GameRoom game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text(
          'Are you sure you want to delete "${game.name}"? This action cannot be undone and will remove the game for all players.',
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
        await _lobbyRepository.deleteGame(game.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Game "${game.name}" deleted.')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Hero Card
              _buildWelcomeHero(),
              const SizedBox(height: 28),
              
              // Invitations Section (Short Preview)
              _buildInvitationsPreview(),
              const SizedBox(height: 28),

              // Recent Games Section
              _buildRecentGamesSection(),
              const SizedBox(height: 28),

              // Bento Stats Grid
              _buildBentoStatsGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onCreateGameTap,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(
          'New Game',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildWelcomeHero() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F00694B),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuA6YPVcQbxfrlryv7Kl__PtgXVLqJf9P62DmVo8ufAHSZhaUrGzKI4zqfeJbKK7Zu-b13hlFeuDRGaA_Ca5QdNZIOlOE76ynrvaBXeBaXnve2NBNe2vUROwZRH7wQHzObct_ve5Em3NolHeTJehTfjm0EyOPi1woit2SewCAhLstvJLk4VSD_oljyj8KSQ8tGhkYzwaI8s55OFYKW9A6VAAjSYS8MGNH-ufVq-OAE_KO4artEfTez4oAYt1Lh16HC4hnQ6q0hQ8x7M',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color(0x3300694B),
            BlendMode.srcOver,
          ),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Good afternoon, Player.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready for the next hand?',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsPreview() {
    return StreamBuilder<List<GameRoom>>(
      stream: _lobbyRepository.watchInvitations(),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? [];
        if (invites.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Game Invitations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${invites.length} NEW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invites.length > 2 ? 2 : invites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final invite = invites[index];
                return FutureBuilder<Player?>(
                  future: _getHostPlayer(invite.hostId),
                  builder: (context, hostSnap) {
                    final host = hostSnap.data;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A765600),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            avatarUrl: host?.avatarUrl,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invite.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Invited by ${host?.screenName ?? "Host"} • Target: ${invite.targetScore}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isNavigating
                                ? null
                                : () => _acceptInvitation(invite),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Accept',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentGamesSection() {
    return StreamBuilder<List<GameRoom>>(
      stream: _lobbyRepository.watchMyGames(),
      builder: (context, snapshot) {
        final games = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Games',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GestureDetector(
                  onTap: widget.onViewAllGamesTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All Games',
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.primary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (games.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No active or recent games.',
                    style: GoogleFonts.beVietnamPro(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length > 3 ? 3 : games.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final game = games[index];
                  final isActive = game.status == GameStatus.playing || game.status == GameStatus.starting;
                  final isHost = game.hostId == _currentUserId;
                  
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : const Color(0xFFEFF1EF), // surface-container-low for completed
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
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE NOW' : (game.status == GameStatus.waiting ? 'WAITING' : 'COMPLETED'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Target: ${game.targetScore}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (isHost) ...[
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Game options',
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _confirmDeleteGame(context, game);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Delete Game',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          game.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Participant Avatars list
                            Row(
                              children: [
                                for (int i = 0; i < (game.playerIds.length > 3 ? 3 : game.playerIds.length); i++)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: FutureBuilder<Player?>(
                                      future: _getHostPlayer(game.playerIds[i]),
                                      builder: (context, pSnap) {
                                        return AvatarWidget(
                                          avatarUrl: pSnap.data?.avatarUrl,
                                          radius: 12,
                                        );
                                      },
                                    ),
                                  ),
                                if (game.playerIds.length > 3)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+${game.playerIds.length - 3}',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: _isNavigating
                                  ? null
                                  : () => _navigateToGame(game),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                isActive ? 'Jump In' : 'View',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildBentoStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.stars,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WIN RATE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '68%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.tertiary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.military_tech,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POINTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1,240',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.secondary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
