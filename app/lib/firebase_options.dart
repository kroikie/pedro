import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'dummy-api-key-web',
    appId: '1:1234567890:web:1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: 'pedro-f65a6',
    authDomain: 'pedro-f65a6.firebaseapp.com',
    storageBucket: 'pedro-f65a6.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'dummy-api-key-android',
    appId: '1:1234567890:android:1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: 'pedro-f65a6',
    storageBucket: 'pedro-f65a6.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key-ios',
    appId: '1:1234567890:ios:1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: 'pedro-f65a6',
    storageBucket: 'pedro-f65a6.appspot.com',
    iosBundleId: 'com.ool.pedro',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key-macos',
    appId: '1:1234567890:ios:1234567890abcdef',
    messagingSenderId: '1234567890',
    projectId: 'pedro-f65a6',
    storageBucket: 'pedro-f65a6.appspot.com',
    iosBundleId: 'com.ool.pedro',
  );
}
