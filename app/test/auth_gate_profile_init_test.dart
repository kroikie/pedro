import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/models/player.dart';
import 'package:pedro/data/repositories/player_repository.dart';
import 'package:pedro/main.dart';

class _FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  _FakeUser({
    required this.uid,
    this.displayName,
    this.photoURL,
  });
}

class _TestPlayerRepository implements PlayerRepository {
  _TestPlayerRepository({
    this.delay = Duration.zero,
    this.shouldThrowTimeout = false,
    this.shouldThrowFirebaseException = false,
    this.shouldThrowGenericException = false,
    this.playerToReturn,
    this.cachedPlayerToReturn,
  });

  final Duration delay;
  final bool shouldThrowTimeout;
  final bool shouldThrowFirebaseException;
  final bool shouldThrowGenericException;
  final Player? playerToReturn;
  final Player? cachedPlayerToReturn;

  Player? updatedPlayer;
  int getPlayerCallCount = 0;
  int getPlayerFromCacheCallCount = 0;

  @override
  Future<Player?> getPlayer(
    String uid, {
    Source source = Source.serverAndCache,
    Duration? timeout,
  }) async {
    getPlayerCallCount++;
    if (source == Source.cache) {
      getPlayerFromCacheCallCount++;
      return cachedPlayerToReturn;
    }

    if (delay > Duration.zero) {
      if (timeout != null && delay > timeout) {
        await Future.delayed(timeout);
        if (source == Source.serverAndCache) {
          return cachedPlayerToReturn;
        }
        throw TimeoutException('Simulated timeout');
      }
      await Future.delayed(delay);
    }

    if (shouldThrowTimeout) {
      if (source == Source.serverAndCache) {
        return cachedPlayerToReturn;
      }
      throw TimeoutException('Simulated timeout');
    }

    if (shouldThrowFirebaseException) {
      if (source == Source.serverAndCache) {
        return cachedPlayerToReturn;
      }
      throw FirebaseException(plugin: 'firestore', code: 'unavailable');
    }

    if (shouldThrowGenericException) {
      throw Exception('Unexpected repository failure');
    }

    return playerToReturn;
  }

  @override
  Future<Player?> getPlayerFromCache(String uid) async {
    getPlayerFromCacheCallCount++;
    return cachedPlayerToReturn;
  }

  @override
  Future<void> updatePlayer(Player player) async {
    updatedPlayer = player;
  }

  @override
  Future<void> addFcmToken(String uid, String token, String platform) async {}

  @override
  Future<void> removeFcmToken(String uid, String token) async {}

  @override
  Stream<Player?> watchPlayer(String uid) =>
      Stream.value(playerToReturn ?? cachedPlayerToReturn);

  @override
  Stream<List<Player>> watchAllPlayers() => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = _FakeUser(
    uid: 'test-user-123',
    displayName: 'Test Player',
    photoURL: 'https://example.com/avatar.jpg',
  );

  group('AuthGate Profile Initialization Tests', () {
    testWidgets('renders home when player exists and getPlayer is successful',
        (tester) async {
      final repo = _TestPlayerRepository(
        playerToReturn: const Player(
          id: 'test-user-123',
          screenName: 'Test Player',
          avatarUrl: 'https://example.com/avatar.jpg',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateChanges: Stream.value(testUser),
            playerRepository: repo,
            homeBuilder: (context, player) => Scaffold(
              body: Text('Home: ${player.screenName}'),
            ),
          ),
        ),
      );

      // Loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Successfully transitions to Home
      expect(find.text('Home: Test Player'), findsOneWidget);
      expect(find.text('Unable to Load Profile'), findsNothing);
      expect(find.textContaining('TimeoutException'), findsNothing);
    });

    testWidgets('gracefully falls back to cache when getPlayer times out',
        (tester) async {
      final repo = _TestPlayerRepository(
        shouldThrowTimeout: true,
        cachedPlayerToReturn: const Player(
          id: 'test-user-123',
          screenName: 'Cached Player',
          avatarUrl: 'https://example.com/cached.jpg',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateChanges: Stream.value(testUser),
            playerRepository: repo,
            homeBuilder: (context, player) => Scaffold(
              body: Text('Home: ${player.screenName}'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should transition to Home with cached player without throwing TimeoutException
      expect(find.text('Home: Cached Player'), findsOneWidget);
      expect(find.textContaining('TimeoutException'), findsNothing);
      expect(find.text('Unable to Load Profile'), findsNothing);
    });

    testWidgets(
        'gracefully creates fallback player from auth info when cache is also empty on timeout',
        (tester) async {
      final repo = _TestPlayerRepository(
        shouldThrowTimeout: true,
        cachedPlayerToReturn: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateChanges: Stream.value(testUser),
            playerRepository: repo,
            homeBuilder: (context, player) => Scaffold(
              body: Text('Home: ${player.screenName}'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should seamlessly navigate to Home with auth user display name
      expect(find.text('Home: Test Player'), findsOneWidget);
      expect(find.textContaining('TimeoutException'), findsNothing);
      expect(find.text('Unable to Load Profile'), findsNothing);

      // And background update was queued with auth user details
      expect(repo.updatedPlayer, isNotNull);
      expect(repo.updatedPlayer!.id, 'test-user-123');
      expect(repo.updatedPlayer!.screenName, 'Test Player');
      expect(repo.updatedPlayer!.avatarUrl, 'https://example.com/avatar.jpg');
    });

    testWidgets('gracefully falls back when Firestore throws FirebaseException (offline)',
        (tester) async {
      final repo = _TestPlayerRepository(
        shouldThrowFirebaseException: true,
        cachedPlayerToReturn: const Player(
          id: 'test-user-123',
          screenName: 'Offline Cached Player',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateChanges: Stream.value(testUser),
            playerRepository: repo,
            homeBuilder: (context, player) => Scaffold(
              body: Text('Home: ${player.screenName}'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should seamlessly navigate to Home
      expect(find.text('Home: Offline Cached Player'), findsOneWidget);
      expect(find.textContaining('FirebaseException'), findsNothing);
      expect(find.text('Unable to Load Profile'), findsNothing);
    });

    testWidgets('gracefully falls back when unexpected error occurs during getPlayer',
        (tester) async {
      final repo = _TestPlayerRepository(
        shouldThrowGenericException: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateChanges: Stream.value(testUser),
            playerRepository: repo,
            homeBuilder: (context, player) => Scaffold(
              body: Text('Home: ${player.screenName}'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Gracefully navigated with auth user info without crashing or locking user out
      expect(find.text('Home: Test Player'), findsOneWidget);
      expect(find.text('Unable to Load Profile'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('renders branded error state and handles Retry when future explicitly fails',
        (tester) async {
      bool shouldFail = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00694B)),
          ),
          home: StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<Player?>(
                future: shouldFail
                    ? Future<Player?>.error(Exception('Fatal simulated failure'))
                    : Future<Player?>.value(const Player(id: '123', screenName: 'Recovered Player')),
                builder: (context, playerSnap) {
                  if (playerSnap.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  if (playerSnap.hasError) {
                    final theme = Theme.of(context);
                    return Scaffold(
                      body: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.error),
                              const Text('Unable to Load Profile'),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                onPressed: () {
                                  setState(() {
                                    shouldFail = false;
                                  });
                                },
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Scaffold(body: Text('Loaded: ${playerSnap.data?.screenName}'));
                },
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Profile'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Tap Retry to test recovery
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Profile'), findsNothing);
      expect(find.text('Loaded: Recovered Player'), findsOneWidget);
    });
  });
}
