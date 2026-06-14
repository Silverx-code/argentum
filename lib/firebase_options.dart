// lib/firebase_options.dart
// Generated manually from Firebase console config
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

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
    apiKey: 'AIzaSyDtydQO6BN3f1Vb_T60ZZDOo79k2mlIs5A',
    authDomain: 'argentum-1b6c4.firebaseapp.com',
    projectId: 'argentum-1b6c4',
    storageBucket: 'argentum-1b6c4.firebasestorage.app',
    messagingSenderId: '681378532164',
    appId: '1:681378532164:web:b5b912419f3cee48f5a511',
    measurementId: 'G-JZFCMZJ43R',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtydQO6BN3f1Vb_T60ZZDOo79k2mlIs5A',
    authDomain: 'argentum-1b6c4.firebaseapp.com',
    projectId: 'argentum-1b6c4',
    storageBucket: 'argentum-1b6c4.firebasestorage.app',
    messagingSenderId: '681378532164',
    appId: '1:681378532164:web:b5b912419f3cee48f5a511',
    measurementId: 'G-JZFCMZJ43R',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtydQO6BN3f1Vb_T60ZZDOo79k2mlIs5A',
    authDomain: 'argentum-1b6c4.firebaseapp.com',
    projectId: 'argentum-1b6c4',
    storageBucket: 'argentum-1b6c4.firebasestorage.app',
    messagingSenderId: '681378532164',
    appId: '1:681378532164:web:b5b912419f3cee48f5a511',
    measurementId: 'G-JZFCMZJ43R',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDtydQO6BN3f1Vb_T60ZZDOo79k2mlIs5A',
    authDomain: 'argentum-1b6c4.firebaseapp.com',
    projectId: 'argentum-1b6c4',
    storageBucket: 'argentum-1b6c4.firebasestorage.app',
    messagingSenderId: '681378532164',
    appId: '1:681378532164:web:b5b912419f3cee48f5a511',
    measurementId: 'G-JZFCMZJ43R',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDtydQO6BN3f1Vb_T60ZZDOo79k2mlIs5A',
    authDomain: 'argentum-1b6c4.firebaseapp.com',
    projectId: 'argentum-1b6c4',
    storageBucket: 'argentum-1b6c4.firebasestorage.app',
    messagingSenderId: '681378532164',
    appId: '1:681378532164:web:b5b912419f3cee48f5a511',
    measurementId: 'G-JZFCMZJ43R',
  );
}