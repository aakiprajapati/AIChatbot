import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDUg-61PWMgZ1pDO4ivJfoaSunVQssZNU',
    appId: '1:191370094637:android:1a1434e23e38bd1d8630a4',
    messagingSenderId: '191370094637',
    projectId: 'ai-chatbot-4fddc',
    storageBucket: 'ai-chatbot-4fddc.firebasestorage.app',
  );
}