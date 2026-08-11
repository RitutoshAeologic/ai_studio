// File generated based on google-services.json and GoogleService-Info.plist for AI Studio
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return ios;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCjUwuHc-265GBzWY96CsUYgIK7WqwOHJE',
    appId: '1:799730875496:android:e8b7285fc4a577daa30fdd',
    messagingSenderId: '799730875496',
    projectId: 'ai-studio-637ab',
    storageBucket: 'ai-studio-637ab.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCjUwuHc-265GBzWY96CsUYgIK7WqwOHJE',
    appId: '1:799730875496:android:e8b7285fc4a577daa30fdd',
    messagingSenderId: '799730875496',
    projectId: 'ai-studio-637ab',
    storageBucket: 'ai-studio-637ab.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCxh9BWRRkqbNcrAwQrGfaoUMH7xp0PYsc',
    appId: '1:799730875496:ios:768dfdccc88c882ca30fdd',
    messagingSenderId: '799730875496',
    projectId: 'ai-studio-637ab',
    storageBucket: 'ai-studio-637ab.firebasestorage.app',
    iosBundleId: 'com.aeologic.adhoc.aistudio',
  );
}
