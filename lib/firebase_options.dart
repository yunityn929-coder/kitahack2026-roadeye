import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
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
    apiKey: 'AIzaSyAYxARwBwyt-u2fE_X9Hb4pp_eASukxaR4',
    appId: '1:710647556468:web:1549cc78af8603e2096421',
    messagingSenderId: '710647556468',
    projectId: 'roadeye-hackathon',
    authDomain: 'roadeye-hackathon.firebaseapp.com',
    storageBucket: 'roadeye-hackathon.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDi4wUw1qUFTDZHbAcydDYx8sCoKVbQkqk',
    appId: '1:710647556468:android:4473faee8a8eb02d096421',
    messagingSenderId: '710647556468',
    projectId: 'roadeye-hackathon',
    storageBucket: 'roadeye-hackathon.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmMeDviNfK_3niRP2ZF_L47zWpIMEOuz8',
    appId: '1:710647556468:ios:eb2e29d2ecbf1aa2096421',
    messagingSenderId: '710647556468',
    projectId: 'roadeye-hackathon',
    storageBucket: 'roadeye-hackathon.firebasestorage.app',
    iosBundleId: 'com.example.roadeyeDashboard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBmMeDviNfK_3niRP2ZF_L47zWpIMEOuz8',
    appId: '1:710647556468:ios:eb2e29d2ecbf1aa2096421',
    messagingSenderId: '710647556468',
    projectId: 'roadeye-hackathon',
    storageBucket: 'roadeye-hackathon.firebasestorage.app',
    iosBundleId: 'com.example.roadeyeDashboard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAYxARwBwyt-u2fE_X9Hb4pp_eASukxaR4',
    appId: '1:710647556468:web:c077564cdc00d740096421',
    messagingSenderId: '710647556468',
    projectId: 'roadeye-hackathon',
    authDomain: 'roadeye-hackathon.firebaseapp.com',
    storageBucket: 'roadeye-hackathon.firebasestorage.app',
  );
}
