import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

/// The Google Web Client ID associated with the Firebase Pedro project.
///
/// Required by Google Sign-In for web authentication and backend token verification.
const String kGoogleWebClientId =
    '260654198138-u5jt4poqnr78d0sierk6e0r1pcikm8gf.apps.googleusercontent.com';

/// Configures and returns the authentication providers used across the app.
///
/// On iOS, [iOSPreferPlist] is set to `true` to ensure the native GoogleSignIn SDK
/// reads the iOS OAuth client ID and reversed URL scheme from GoogleService-Info.plist
/// and Info.plist rather than attempting to initialize with the web client ID.
List<AuthProvider> buildAppAuthProviders({
  String googleClientId = kGoogleWebClientId,
  bool iOSPreferPlist = true,
}) {
  return [
    EmailAuthProvider(),
    GoogleProvider(
      clientId: googleClientId,
      iOSPreferPlist: iOSPreferPlist,
    ),
  ];
}
