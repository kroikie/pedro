import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../widgets/avatar_widget.dart';

enum LeaderboardTimeframe {
  thisWeek('This Week'),
  lastWeek('Last Week'),
  allTime('All-Time');

  const LeaderboardTimeframe(this.label);
  final String label;
}

enum LeaderboardBoardMode {
  triumphs('🏆 Triumphs'),
  hallOfShame('💀 Hall of Shame'),
  rivalries('⚔️ Rivalries');

  const LeaderboardBoardMode(this.label);
  final String label;
}

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({
    super.key,
    this.leaderboardRepository,
    this.currentUserId,
    this.currentUserName,
    this.referenceTime,
  });

  final LeaderboardRepository? leaderboardRepository;
  final String? currentUserId;
  final String? currentUserName;
  final DateTime? referenceTime;

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  late final LeaderboardRepository _repository =
      widget.leaderboardRepository ?? LeaderboardRepository();

  LeaderboardTimeframe _selectedTimeframe = LeaderboardTimeframe.thisWeek;
  LeaderboardBoardMode _selectedMode = LeaderboardBoardMode.triumphs;
  LeaderboardCategory _selectedTriumphCategory = LeaderboardCategory.hangJacks;
  LeaderboardCategory _selectedShameCategory = LeaderboardCategory.jacksHung;

  String? get _effectiveUserId {
    if (widget.currentUserId != null) return widget.currentUserId;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String get _effectivePeriodId {
    final now = widget.referenceTime ?? DateTime.now();
    switch (_selectedTimeframe) {
      case LeaderboardTimeframe.thisWeek:
        return getCurrentWeekPeriodId(now);
      case LeaderboardTimeframe.lastWeek:
        return getLastWeekPeriodId(now);
      case LeaderboardTimeframe.allTime:
        return 'all_time';
    }
  }

  LeaderboardCategory get _activeCategory =>
      _selectedMode == LeaderboardBoardMode.hallOfShame
          ? _selectedShameCategory
          : _selectedTriumphCategory;

  @override
  Widget build(BuildContext context) {
    final periodId = _effectivePeriodId;

    return StreamBuilder<List<LeaderboardEntry>>(
      stream: _repository.watchPeriodEntries(periodId),
      builder: (context, entriesSnapshot) {
        return StreamBuilder<List<RivalryEntry>>(
          stream: _repository.watchPeriodRivalries(periodId),
          builder: (context, rivalriesSnapshot) {
            final isLoading = entriesSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !entriesSnapshot.hasData;
            final entries = entriesSnapshot.data ?? const <LeaderboardEntry>[];
            final rivalries = rivalriesSnapshot.data ?? const <RivalryEntry>[];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderBanner(context),
                        const SizedBox(height: 16),
                        _buildTimeframeBar(context),
                        const SizedBox(height: 14),
                        _buildModeSwitcher(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_selectedMode == LeaderboardBoardMode.rivalries)
                  ..._buildRivalriesSlivers(context, entries, rivalries)
                else
                  ..._buildAccoladeBoardSlivers(
                    context,
                    entries,
                    rivalries,
                    isShame:
                        _selectedMode == LeaderboardBoardMode.hallOfShame,
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    final isShame = _selectedMode == LeaderboardBoardMode.hallOfShame;
    final isRivalry = _selectedMode == LeaderboardBoardMode.rivalries;

    final gradientColors = isShame
        ? const [Color(0xFF4A151B), Color(0xFF7D2430)]
        : isRivalry
            ? const [Color(0xFF281B47), Color(0xFF4B2E83)]
            : const [Color(0xFF004D34), Color(0xFF006C49)];

    final subtitle = isShame
        ? 'Roast the table! Tracking hung Jacks, donated 9s & 5s, and painful buss contracts.'
        : isRivalry
            ? 'Head-to-head card heists and personal table feuds. Tap any player for the Tale of the Tape!'
            : 'Weekly and all-time Pedro legends across High, Low, Jack, 5, 9, Game & Contracts.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              isShame
                  ? '💀'
                  : isRivalry
                      ? '⚔️'
                      : '🏆',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isShame
                      ? 'Pedro Hall of Shame'
                      : isRivalry
                          ? 'Nemesis & Prey Rivalries'
                          : 'Pedro Hall of Fame',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: LeaderboardTimeframe.values.map((tf) {
          final isSelected = _selectedTimeframe == tf;
          return Expanded(
            child: GestureDetector(
              key: ValueKey('timeframe_${tf.name}'),
              onTap: () => setState(() => _selectedTimeframe = tf),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFCA53)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  tf.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? const Color(0xFF5A4000)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeSwitcher(BuildContext context) {
    return Row(
      children: LeaderboardBoardMode.values.map((mode) {
        final isSelected = _selectedMode == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              key: ValueKey('board_mode_${mode.name}'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  mode.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<LeaderboardEntry> _sortedForCategory(
    List<LeaderboardEntry> entries,
    LeaderboardCategory category,
  ) {
    final filtered = entries
        .where((e) => e.valueForCategory(category) > 0)
        .toList();
    filtered.sort((a, b) {
      final cmp =
          b.valueForCategory(category).compareTo(a.valueForCategory(category));
      if (cmp != 0) return cmp;
      if (category.isUnfortunate) {
        final rCmp = b.roundsPlayed.compareTo(a.roundsPlayed);
        if (rCmp != 0) return rCmp;
      } else {
        final pCmp = b.totalPointsEarned.compareTo(a.totalPointsEarned);
        if (pCmp != 0) return pCmp;
      }
      return a.screenName.toLowerCase().compareTo(b.screenName.toLowerCase());
    });
    return filtered;
  }

  List<Widget> _buildAccoladeBoardSlivers(
    BuildContext context,
    List<LeaderboardEntry> entries,
    List<RivalryEntry> rivalries, {
    required bool isShame,
  }) {
    final categories = isShame
        ? LeaderboardCategory.hallOfShame
        : LeaderboardCategory.triumphs;
    final activeCat = _activeCategory;
    final ranked = _sortedForCategory(entries, activeCat);

    return [
      // 1. Spotlight Carousel of all accolades in this mode
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                isShame ? 'UNFORTUNATE DISTINCTIONS' : 'SPOTLIGHT ACCOLADES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 132,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final topList = _sortedForCategory(entries, cat);
                  final leader = topList.isNotEmpty ? topList.first : null;
                  final isSelected = cat == activeCat;

                  return _buildSpotlightCard(
                    context,
                    category: cat,
                    leader: leader,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isShame) {
                          _selectedShameCategory = cat;
                        } else {
                          _selectedTriumphCategory = cat;
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 2. Active Category Header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isShame
                    ? const Color(0xFFB3261E).withValues(alpha: 0.25)
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  activeCat.badgeEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeCat.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeCat.description,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 16)),

      if (ranked.isEmpty)
        SliverToBoxAdapter(
          child: _buildEmptyState(
            context,
            title: isShame
                ? 'No ${activeCat.title} victims yet!'
                : 'No ${activeCat.title} leaders yet!',
            subtitle:
                'Complete rounds in a Pedro match to populate ${_selectedTimeframe.label.toLowerCase()} rankings.',
          ),
        )
      else ...[
        // 3. Top-3 Podium
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTopThreePodium(
              context,
              ranked: ranked.take(3).toList(),
              category: activeCat,
              allEntries: entries,
              rivalries: rivalries,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // 4. Full Ranked List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: ranked.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = ranked[index];
              final rank = index + 1;
              return _buildPlayerRankRow(
                context,
                rank: rank,
                entry: entry,
                category: activeCat,
                allEntries: entries,
                rivalries: rivalries,
              );
            },
          ),
        ),
      ],
    ];
  }

  Widget _buildSpotlightCard(
    BuildContext context, {
    required LeaderboardCategory category,
    required LeaderboardEntry? leader,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isShame = category.isUnfortunate;
    final accentColor =
        isShame ? const Color(0xFFB3261E) : const Color(0xFF006C49);

    return GestureDetector(
      key: ValueKey('spotlight_${category.name}'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 175,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(category.badgeEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            if (leader != null)
              Row(
                children: [
                  AvatarWidget(avatarUrl: leader.avatarUrl, radius: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leader.screenName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${leader.valueForCategory(category)} ${category.unitLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Text(
                'Unclaimed',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopThreePodium(
    BuildContext context, {
    required List<LeaderboardEntry> ranked,
    required LeaderboardCategory category,
    required List<LeaderboardEntry> allEntries,
    required List<RivalryEntry> rivalries,
  }) {
    final first = ranked.isNotEmpty ? ranked[0] : null;
    final second = ranked.length > 1 ? ranked[1] : null;
    final third = ranked.length > 2 ? ranked[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second != null
                ? _buildPodiumColumn(
                    context,
                    rank: 2,
                    entry: second,
                    category: category,
                    allEntries: allEntries,
                    rivalries: rivalries,
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: first != null
                ? _buildPodiumColumn(
                    context,
                    rank: 1,
                    entry: first,
                    category: category,
                    allEntries: allEntries,
                    rivalries: rivalries,
                    isCenter: true,
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: third != null
                ? _buildPodiumColumn(
                    context,
                    rank: 3,
                    entry: third,
                    category: category,
                    allEntries: allEntries,
                    rivalries: rivalries,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    BuildContext context, {
    required int rank,
    required LeaderboardEntry entry,
    required LeaderboardCategory category,
    required List<LeaderboardEntry> allEntries,
    required List<RivalryEntry> rivalries,
    bool isCenter = false,
  }) {
    final badgeColor = rank == 1
        ? const Color(0xFFFFCA53)
        : rank == 2
            ? const Color(0xFFD5D9DC)
            : const Color(0xFFE0A96D);

    final val = entry.valueForCategory(category);

    return GestureDetector(
      key: ValueKey('podium_${entry.uid}'),
      onTap: () => _showHeadToHeadSheet(
        context,
        opponentUid: entry.uid,
        opponentName: entry.screenName,
        opponentAvatarUrl: entry.avatarUrl,
        allEntries: allEntries,
        rivalries: rivalries,
      ),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: isCenter ? 3 : 2),
                ),
                child: AvatarWidget(
                  avatarUrl: entry.avatarUrl,
                  radius: isCenter ? 30 : 23,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2C2F2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.screenName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isCenter ? 14 : 12,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: category.isUnfortunate
                  ? const Color(0xFFFFDAD6)
                  : const Color(0xFFD8F3DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$val ${category.unitLabel}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: category.isUnfortunate
                    ? const Color(0xFF93000A)
                    : const Color(0xFF004D34),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRankRow(
    BuildContext context, {
    required int rank,
    required LeaderboardEntry entry,
    required LeaderboardCategory category,
    required List<LeaderboardEntry> allEntries,
    required List<RivalryEntry> rivalries,
  }) {
    final isMe = entry.uid == _effectiveUserId;
    final val = entry.valueForCategory(category);
    final isShame = category.isUnfortunate;

    return InkWell(
      key: ValueKey('rank_row_${entry.uid}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showHeadToHeadSheet(
        context,
        opponentUid: entry.uid,
        opponentName: entry.screenName,
        opponentAvatarUrl: entry.avatarUrl,
        allEntries: allEntries,
        rivalries: rivalries,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFFFF8E7)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? const Color(0xFFFFCA53)
                : Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.25),
            width: isMe ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AvatarWidget(avatarUrl: entry.avatarUrl, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.screenName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCA53),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'YOU',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF5A4000),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.secondarySubtitleForCategory(category),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$val',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isShame
                        ? const Color(0xFFB3261E)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  category.unitLabel,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRivalriesSlivers(
    BuildContext context,
    List<LeaderboardEntry> entries,
    List<RivalryEntry> rivalries,
  ) {
    final myUid = _effectiveUserId;

    // Sort all rivalries by heistPoints desc, then matchesWonAgainst desc, then heistCount desc
    final sortedFeuds = rivalries
        .where((r) => r.heistCount > 0 || r.matchesWonAgainst > 0)
        .toList()
      ..sort((a, b) {
        final hCmp = b.heistPoints.compareTo(a.heistPoints);
        if (hCmp != 0) return hCmp;
        final mCmp = b.matchesWonAgainst.compareTo(a.matchesWonAgainst);
        if (mCmp != 0) return mCmp;
        return b.heistCount.compareTo(a.heistCount);
      });

    RivalryEntry? myNemesis;
    RivalryEntry? myFavoritePrey;

    if (myUid != null && myUid.isNotEmpty) {
      final againstMe = sortedFeuds
          .where((r) => r.victimUid == myUid)
          .toList();
      if (againstMe.isNotEmpty) {
        myNemesis = againstMe.first;
      }

      final myVictims = sortedFeuds
          .where((r) => r.actorUid == myUid)
          .toList();
      if (myVictims.isNotEmpty) {
        myFavoritePrey = myVictims.first;
      }
    }

    return [
      // 1. Personal Nemesis & Favorite Prey Cards
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR PERSONAL RIVALRIES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildPersonalRivalryCard(
                      context,
                      key: const ValueKey('personal_nemesis_card'),
                      badge: '😈 YOUR NEMESIS',
                      accentColor: const Color(0xFFB3261E),
                      counterpartUid: myNemesis?.actorUid,
                      counterpartName: myNemesis?.actorName,
                      counterpartAvatar: myNemesis?.actorAvatarUrl,
                      rivalry: myNemesis,
                      emptyHint: 'Nobody has robbed your trump points yet!',
                      allEntries: entries,
                      rivalries: rivalries,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPersonalRivalryCard(
                      context,
                      key: const ValueKey('personal_prey_card'),
                      badge: '🎯 FAVORITE PREY',
                      accentColor: const Color(0xFF006C49),
                      counterpartUid: myFavoritePrey?.victimUid,
                      counterpartName: myFavoritePrey?.victimName,
                      counterpartAvatar: myFavoritePrey?.victimAvatarUrl,
                      rivalry: myFavoritePrey,
                      emptyHint: "Hang an opponent's Jack or steal their 9!",
                      allEntries: entries,
                      rivalries: rivalries,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '🔥 HOTTEST TABLE FEUDS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      if (sortedFeuds.isEmpty)
        SliverToBoxAdapter(
          child: _buildEmptyState(
            context,
            title: 'No Table Feuds Recorded Yet',
            subtitle:
                'When a player hangs another player\'s Jack or steals their 9 or 5 of trumps, their rivalry appears here!',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: sortedFeuds.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final feud = sortedFeuds[index];
              return _buildFeudRow(
                context,
                rank: index + 1,
                feud: feud,
                allEntries: entries,
                rivalries: rivalries,
              );
            },
          ),
        ),
    ];
  }

  Widget _buildPersonalRivalryCard(
    BuildContext context, {
    required Key key,
    required String badge,
    required Color accentColor,
    required String? counterpartUid,
    required String? counterpartName,
    required String? counterpartAvatar,
    required RivalryEntry? rivalry,
    required String emptyHint,
    required List<LeaderboardEntry> allEntries,
    required List<RivalryEntry> rivalries,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(18),
      onTap: counterpartUid != null && counterpartName != null
          ? () => _showHeadToHeadSheet(
                context,
                opponentUid: counterpartUid,
                opponentName: counterpartName,
                opponentAvatarUrl: counterpartAvatar,
                allEntries: allEntries,
                rivalries: rivalries,
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            if (rivalry != null && counterpartName != null) ...[
              Row(
                children: [
                  AvatarWidget(avatarUrl: counterpartAvatar, radius: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      counterpartName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rivalry.breakdownSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${rivalry.heistPoints} heist pts stolen',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  emptyHint,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeudRow(
    BuildContext context, {
    required int rank,
    required RivalryEntry feud,
    required List<LeaderboardEntry> allEntries,
    required List<RivalryEntry> rivalries,
  }) {
    final myUid = _effectiveUserId;

    return InkWell(
      key: ValueKey('feud_row_${feud.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // If logged-in user is part of this feud, compare You vs the other player;
        // otherwise compare actor vs victim.
        if (myUid == feud.actorUid) {
          _showHeadToHeadSheet(
            context,
            opponentUid: feud.victimUid,
            opponentName: feud.victimName,
            opponentAvatarUrl: feud.victimAvatarUrl,
            allEntries: allEntries,
            rivalries: rivalries,
          );
        } else if (myUid == feud.victimUid) {
          _showHeadToHeadSheet(
            context,
            opponentUid: feud.actorUid,
            opponentName: feud.actorName,
            opponentAvatarUrl: feud.actorAvatarUrl,
            allEntries: allEntries,
            rivalries: rivalries,
          );
        } else {
          _showHeadToHeadSheet(
            context,
            primaryUidOverride: feud.actorUid,
            primaryNameOverride: feud.actorName,
            primaryAvatarOverride: feud.actorAvatarUrl,
            opponentUid: feud.victimUid,
            opponentName: feud.victimName,
            opponentAvatarUrl: feud.victimAvatarUrl,
            allEntries: allEntries,
            rivalries: rivalries,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AvatarWidget(avatarUrl: feud.actorAvatarUrl, radius: 18),
            const SizedBox(width: 6),
            const Icon(Icons.bolt, size: 16, color: Color(0xFFFF9800)),
            const SizedBox(width: 6),
            AvatarWidget(avatarUrl: feud.victimAvatarUrl, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${feud.actorName} → ${feud.victimName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feud.breakdownSummary,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${feud.heistPoints}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4B2E83),
                    ),
                  ),
                  Text(
                    'heist pts',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 9,
                      color: const Color(0xFF4B2E83),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHeadToHeadSheet(
    BuildContext context, {
    String? primaryUidOverride,
    String? primaryNameOverride,
    String? primaryAvatarOverride,
    required String opponentUid,
    required String opponentName,
    required String? opponentAvatarUrl,
    required List<LeaderboardEntry> allEntries,
    required List<RivalryEntry> rivalries,
  }) {
    final primaryUid = primaryUidOverride ?? _effectiveUserId ?? '';

    // If user taps their own row and no override was passed, show their personal Nemesis/Prey & stats summary
    final isSelfInspection =
        primaryUid.isEmpty || primaryUid == opponentUid;

    LeaderboardEntry? primaryEntry;
    for (final e in allEntries) {
      if (e.uid == primaryUid) {
        primaryEntry = e;
        break;
      }
    }

    LeaderboardEntry? opponentEntry;
    for (final e in allEntries) {
      if (e.uid == opponentUid) {
        opponentEntry = e;
        break;
      }
    }

    final primaryName = primaryNameOverride ??
        primaryEntry?.screenName ??
        widget.currentUserName ??
        'You';
    final primaryAvatar = primaryAvatarOverride ?? primaryEntry?.avatarUrl;

    RivalryEntry? primaryVsOpponent;
    RivalryEntry? opponentVsPrimary;
    for (final r in rivalries) {
      if (r.actorUid == primaryUid && r.victimUid == opponentUid) {
        primaryVsOpponent = r;
      } else if (r.actorUid == opponentUid && r.victimUid == primaryUid) {
        opponentVsPrimary = r;
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSelfInspection
                    ? '${opponentName.toUpperCase()} — PLAYER DOSSIER'
                    : '⚔️ TALE OF THE TAPE (${_selectedTimeframe.label.toUpperCase()})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              if (isSelfInspection)
                _buildSelfDossierContent(
                  sheetContext,
                  entry: opponentEntry ??
                      LeaderboardEntry(
                        uid: opponentUid,
                        screenName: opponentName,
                        avatarUrl: opponentAvatarUrl,
                      ),
                )
              else
                _buildHeadToHeadComparisonContent(
                  sheetContext,
                  primaryName: primaryName,
                  primaryAvatar: primaryAvatar,
                  opponentName: opponentName,
                  opponentAvatar: opponentAvatarUrl,
                  primaryVsOpponent: primaryVsOpponent,
                  opponentVsPrimary: opponentVsPrimary,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelfDossierContent(
    BuildContext context, {
    required LeaderboardEntry entry,
  }) {
    return Column(
      children: [
        AvatarWidget(avatarUrl: entry.avatarUrl, radius: 32),
        const SizedBox(height: 10),
        Text(
          entry.screenName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.gamesWon} Wins • ${entry.roundsPlayed} Rounds • ${entry.totalPointsEarned} Pts',
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _buildStatPairRow(
                '🪝 Jacks Hung vs. Lost',
                '${entry.hangJacks} Hung',
                '${entry.jacksHung} Lost',
              ),
              const Divider(height: 18),
              _buildStatPairRow(
                '🎯 9 of Trumps Won vs. Lost',
                '${entry.ninesWon} Won',
                '${entry.ninesLost} Lost',
              ),
              const Divider(height: 18),
              _buildStatPairRow(
                '🖐️ 5 of Trumps Won vs. Lost',
                '${entry.fivesWon} Won',
                '${entry.fivesLost} Lost',
              ),
              const Divider(height: 18),
              _buildStatPairRow(
                '📜 Contracts Made vs. Buss',
                '${entry.bidsMade} Made',
                '${entry.bidsSet} Buss',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadToHeadComparisonContent(
    BuildContext context, {
    required String primaryName,
    required String? primaryAvatar,
    required String opponentName,
    required String? opponentAvatar,
    required RivalryEntry? primaryVsOpponent,
    required RivalryEntry? opponentVsPrimary,
  }) {
    final myJacksHung = primaryVsOpponent?.jacksHung ?? 0;
    final theirJacksHung = opponentVsPrimary?.jacksHung ?? 0;

    final myNinesStolen = primaryVsOpponent?.ninesStolen ?? 0;
    final theirNinesStolen = opponentVsPrimary?.ninesStolen ?? 0;

    final myFivesStolen = primaryVsOpponent?.fivesStolen ?? 0;
    final theirFivesStolen = opponentVsPrimary?.fivesStolen ?? 0;

    final myMatchesWon = primaryVsOpponent?.matchesWonAgainst ?? 0;
    final theirMatchesWon = opponentVsPrimary?.matchesWonAgainst ?? 0;

    final myHeistPts = primaryVsOpponent?.heistPoints ?? 0;
    final theirHeistPts = opponentVsPrimary?.heistPoints ?? 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                children: [
                  AvatarWidget(avatarUrl: primaryAvatar, radius: 28),
                  const SizedBox(height: 8),
                  Text(
                    primaryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCA53),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'VS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5A4000),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  AvatarWidget(avatarUrl: opponentAvatar, radius: 28),
                  const SizedBox(height: 8),
                  Text(
                    opponentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildTapeRow(
                label: '🏆 Match Wins Together',
                leftValue: myMatchesWon,
                rightValue: theirMatchesWon,
              ),
              const Divider(height: 20),
              _buildTapeRow(
                label: '🪝 Jacks Hung (+3 pts)',
                leftValue: myJacksHung,
                rightValue: theirJacksHung,
              ),
              const Divider(height: 20),
              _buildTapeRow(
                label: '🎯 9 of Trumps Stolen (+9 pts)',
                leftValue: myNinesStolen,
                rightValue: theirNinesStolen,
              ),
              const Divider(height: 20),
              _buildTapeRow(
                label: '🖐️ 5 of Trumps Stolen (+5 pts)',
                leftValue: myFivesStolen,
                rightValue: theirFivesStolen,
              ),
              const Divider(height: 20),
              _buildTapeRow(
                label: '⚡ Total Heist Points Stolen',
                leftValue: myHeistPts,
                rightValue: theirHeistPts,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatPairRow(String label, String positive, String negative) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          positive,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF006C49),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          negative,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFB3261E),
          ),
        ),
      ],
    );
  }

  Widget _buildTapeRow({
    required String label,
    required int leftValue,
    required int rightValue,
  }) {
    final leftWins = leftValue > rightValue;
    final rightWins = rightValue > leftValue;

    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            '$leftValue',
            textAlign: TextAlign.left,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: leftWins
                  ? const Color(0xFF006C49)
                  : const Color(0xFF5A5D5C),
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C2F2E),
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$rightValue',
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: rightWins
                  ? const Color(0xFFB3261E)
                  : const Color(0xFF5A5D5C),
            ),
          ),
        ),
      ],
    );
  }
}
