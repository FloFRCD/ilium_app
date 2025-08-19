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
    apiKey: 'AIzaSyCM9IkyfkqX9aeMuXlW-U6i1f6k0vfarnM',
    appId: '1:181647207807:web:74b736cc8a0e4be92cbe4a',
    messagingSenderId: '181647207807',
    projectId: 'ilium-4d0ab',
    authDomain: 'ilium-4d0ab.firebaseapp.com',
    storageBucket: 'ilium-4d0ab.firebasestorage.app',
    measurementId: 'G-M9GV0PF9RD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAd8FeXAAHTfvFTVkHsFuhVX1zkv-5gyPw',
    appId: '1:181647207807:android:1954fd94851045a12cbe4a',
    messagingSenderId: '181647207807',
    projectId: 'ilium-4d0ab',
    storageBucket: 'ilium-4d0ab.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAcSJ-OSJyHasv-1k1BX7FsEILkNDfCqag',
    appId: '1:181647207807:ios:e17865507a9a49212cbe4a',
    messagingSenderId: '181647207807',
    projectId: 'ilium-4d0ab',
    storageBucket: 'ilium-4d0ab.firebasestorage.app',
    iosBundleId: 'com.ilium.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAcSJ-OSJyHasv-1k1BX7FsEILkNDfCqag',
    appId: '1:181647207807:macos:e17865507a9a49212cbe4a',
    messagingSenderId: '181647207807',
    projectId: 'ilium-4d0ab',
    storageBucket: 'ilium-4d0ab.firebasestorage.app',
    iosClientId: '181647207807-abcdefghijk.apps.googleusercontent.com',
    iosBundleId: 'com.ilium.app',
  );
}