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
import 'package:google_fonts/google_fonts.dart';

import 'data/repositories/player_repository.dart';
import 'data/models/player.dart';
import 'data/emulator_config.dart';
import 'data/auth_config.dart';
import 'data/services/notification_service.dart';

import 'ui/screens/auth_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/home_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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

  // Connect to the local emulator suite if configured (defaults to debug mode only)
  final bool useEmulator = shouldConnectToFirebaseEmulator();
  if (useEmulator) {
    try {
      final String host = resolveEmulatorHost();
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('Connected to Firebase emulators successfully ($host).');
    } catch (e) {
      debugPrint('Failed to connect to emulators: $e');
    }
  }

  FirebaseUIAuth.configureProviders(buildAppAuthProviders());

  await NotificationService.instance.initialize(navigatorKey: rootNavigatorKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Pedro',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF00694B),
          onPrimary: Color(0xFFC7FFE3),
          primaryContainer: Color(0xFF8CFECE),
          onPrimaryContainer: Color(0xFF006145),
          secondary: Color(0xFF765600),
          onSecondary: Color(0xFFFFF1DB),
          secondaryContainer: Color(0xFFFFCA53),
          onSecondaryContainer: Color(0xFF5C4300),
          tertiary: Color(0xFF006762),
          onTertiary: Color(0xFFBEFFF9),
          tertiaryContainer: Color(0xFF73F1E7),
          onTertiaryContainer: Color(0xFF005854),
          error: Color(0xFFB31B25),
          onError: Color(0xFFFFEFEE),
          errorContainer: Color(0xFFFB5151),
          onErrorContainer: Color(0xFF570008),
          surface: Color(0xFFF5F7F5),
          onSurface: Color(0xFF2C2F2E),
          onSurfaceVariant: Color(0xFF595C5B),
          outline: Color(0xFF747776),
          outlineVariant: Color(0xFFABAEAC),
          shadow: Color(0xFF000000),
          inverseSurface: Color(0xFF0B0F0E),
          onInverseSurface: Color(0xFF9B9D9C),
          inversePrimary: Color(0xFF8CFECE),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
        textTheme: GoogleFonts.beVietnamProTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.displayLarge,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02,
          ),
          displayMedium: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.displayMedium,
            fontWeight: FontWeight.w800,
          ),
          displaySmall: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.displaySmall,
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.headlineLarge,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.headlineMedium,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.headlineSmall,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.titleLarge,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.titleMedium,
            fontWeight: FontWeight.bold,
          ),
          titleSmall: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.titleSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x26ABAEAC), width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEFF1EF),
          disabledColor: const Color(0xFFEFF1EF),
          selectedColor: const Color(0xFFFFCA53),
          secondarySelectedColor: const Color(0xFFFFCA53),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C2F2E),
            fontSize: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
            side: BorderSide.none,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEFF1EF), // surface-container-low is better/breezier
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00694B), width: 2),
          ),
          labelStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF595C5B),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00694B),
            foregroundColor: const Color(0xFFC7FFE3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
          NotificationService.instance.unregisterUserToken();
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
      NotificationService.instance.registerUserToken(user.uid);
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
