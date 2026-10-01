import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../repositories/player_repository.dart';
import '../../ui/screens/game_room_screen.dart';
import '../../ui/screens/game_board_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handled automatically by OS notification tray
  debugPrint('Handling FCM background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._internal({PlayerRepository? playerRepo})
      : _playerRepo = playerRepo;
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService({PlayerRepository? playerRepo}) {
    if (playerRepo != null) {
      instance._playerRepo = playerRepo;
    }
    return instance;
  }

  PlayerRepository? _playerRepo;
  PlayerRepository get _effectivePlayerRepo =>
      _playerRepo ??= PlayerRepository();
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentUserId;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _activeGameId;

  String? get activeGameId => _activeGameId;

  void setActiveGame(String? gameId) {
    _activeGameId = gameId;
  }

  Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle message clicks when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);

      // Check if launched from a terminated state notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageClick(initialMessage);
      }

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM foreground message: ${message.notification?.title}');
        final gameId = message.data['gameId'] as String?;
        // If the user is currently on the active game board for this game,
        // we suppress duplicate OS/toast notifications as in-game state handles it.
        if (gameId != null && gameId == _activeGameId) {
          return;
        }

        // Show a brief in-app snackbar if on another screen
        final context = _navigatorKey?.currentContext;
        final title = message.notification?.title;
        final body = message.notification?.body;
        if (context != null && context.mounted && (title != null || body != null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title: $body'),
              behavior: SnackBarBehavior.floating,
              action: gameId != null
                  ? SnackBarAction(
                      label: 'View',
                      onPressed: () => _handleMessageClick(message),
                    )
                  : null,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> registerUserToken(String uid) async {
    _currentUserId = uid;

    try {
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (_currentUserId != null) {
          final oldToken = _currentToken;
          _currentToken = newToken;
          final platform = kIsWeb
              ? 'web'
              : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
          if (oldToken != null && oldToken != newToken) {
            await _effectivePlayerRepo.removeFcmToken(_currentUserId!, oldToken);
          }
          await _effectivePlayerRepo.addFcmToken(_currentUserId!, newToken, platform);
          debugPrint('Updated refreshed FCM token for $_currentUserId: $newToken ($platform)');
        }
      });

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // On iOS, APNs token registration happens asynchronously.
        // Wait briefly for the APNs token if not yet populated.
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        for (var i = 0; i < 6 && apnsToken == null; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _currentToken = token;
        final platform = kIsWeb
            ? 'web'
            : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
        await _effectivePlayerRepo.addFcmToken(uid, token, platform);
        debugPrint('Registered FCM token for $uid: $token ($platform)');
      }
    } catch (e) {
      debugPrint('Error registering initial FCM token: $e');
    }
  }

  Future<void> unregisterUserToken() async {
    try {
      if (_currentUserId != null && _currentToken != null) {
        await _effectivePlayerRepo.removeFcmToken(_currentUserId!, _currentToken!);
      }
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    } finally {
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      _currentUserId = null;
      _currentToken = null;
    }
  }

  void _handleMessageClick(RemoteMessage message) {
    final gameId = message.data['gameId'] as String?;
    final type = message.data['type'] as String?;

    if (gameId == null || gameId.isEmpty) return;

    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    if (type == 'invite') {
      nav.push(MaterialPageRoute(builder: (_) => GameRoomScreen(gameId: gameId)));
    } else {
      nav.push(MaterialPageRoute(builder: (_) => GameBoardScreen(gameId: gameId)));
    }
  }
}
