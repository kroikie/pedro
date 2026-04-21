import 'package:flutter/material.dart' hide Card;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' hide ProfileScreen;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'data/repositories/player_repository.dart';
import 'data/models/player.dart';

import 'ui/screens/auth_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Crashlytics and Analytics
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Connect to the local emulator suite
  const bool useEmulator = true;
  if (useEmulator) {
    try {
      const String host = kIsWeb ? 'localhost' : '10.0.2.2';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('Connected to Firebase emulators successfully.');
    } catch (e) {
      debugPrint('Failed to connect to emulators: $e');
    }
  }

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(clientId: 'dummy-client-id-for-emulator'),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/profile': (context) => const ProfileScreen(),
      },
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<Player?>? _playerFuture;
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        if (user == null) {
          _lastUid = null;
          _playerFuture = null;
          return const AuthScreen();
        }
        
        if (user.uid != _lastUid) {
          _lastUid = user.uid;
          _playerFuture = _initializePlayer(user);
        }
        
        return FutureBuilder<Player?>(
          future: _playerFuture,
          builder: (context, playerSnap) {
            if (playerSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (playerSnap.hasError) {
               return Scaffold(body: Center(child: Text('Error initializing profile: ${playerSnap.error}')));
            }
            return const HomeScreen();
          },
        );
      },
    );
  }

  Future<Player?> _initializePlayer(User user) async {
    final repo = PlayerRepository();
    try {
      final player = await repo.getPlayer(user.uid).timeout(const Duration(seconds: 5));
      if (player == null) {
        final newPlayer = Player(
          id: user.uid,
          screenName: user.displayName ?? 'Anonymous',
          avatarUrl: user.photoURL,
        );
        await repo.updatePlayer(newPlayer);
        return newPlayer;
      }
      return player;
    } catch (e) {
      debugPrint('Error in _initializePlayer: $e');
      rethrow;
    }
  }
}
