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
    apiKey: 'AIzaSyBMplBWcdJUcfovZW1zqqusQiZ4g70zr7A',
    appId: '1:260654198138:web:50089660e495fd32527ac3',
    messagingSenderId: '260654198138',
    projectId: 'pedro-f65a6',
    authDomain: 'pedro-f65a6.firebaseapp.com',
    storageBucket: 'pedro-f65a6.firebasestorage.app',
    measurementId: 'G-5ZSCM5GY32',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDBKOJLzRYpO1hJgCy8sSPdHNaIyeTRoCI',
    appId: '1:260654198138:android:d7a8d380ab8b794d527ac3',
    messagingSenderId: '260654198138',
    projectId: 'pedro-f65a6',
    storageBucket: 'pedro-f65a6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDp6mhShMWc-lvwa-sw4Y_VBlitP18kvAo',
    appId: '1:260654198138:ios:406f5d2a81fb69a9527ac3',
    messagingSenderId: '260654198138',
    projectId: 'pedro-f65a6',
    storageBucket: 'pedro-f65a6.firebasestorage.app',
    androidClientId: '260654198138-tcjr0mhikksjd517apgpsljdk8s87j94.apps.googleusercontent.com',
    iosClientId: '260654198138-odhvbs1ftvbk4nphl9dfm4dda181rvar.apps.googleusercontent.com',
    iosBundleId: 'com.ool.pedro.pedro',
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