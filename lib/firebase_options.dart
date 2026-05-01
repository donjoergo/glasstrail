import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError('Firebase is only configured for Android.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCf9hdvTVGPrI4WqWkWF33V4AhCthxQN_0',
    appId: '1:1004578022338:android:9c77de78cf5b53d91eac5b',
    messagingSenderId: '1004578022338',
    projectId: 'glasstrail-42',
    storageBucket: 'glasstrail-42.firebasestorage.app',
  );
}
