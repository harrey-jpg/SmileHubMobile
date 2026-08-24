// File generated from the smilehub-ecommerce Firebase project.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDzd-_1VWdkDBTuMTq520Yt_pXaLC-Pimk',
    appId: '1:177683041939:web:09b57fbc044e5f604ec766',
    messagingSenderId: '177683041939',
    projectId: 'smilehub-ecommerce',
    authDomain: 'smilehub-ecommerce.firebaseapp.com',
    storageBucket: 'smilehub-ecommerce.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKynaD7iCCImV9chgJWELCd9cHBSaDk_o',
    appId: '1:177683041939:android:3c4696c4c357065f4ec766',
    messagingSenderId: '177683041939',
    projectId: 'smilehub-ecommerce',
    storageBucket: 'smilehub-ecommerce.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDzd-_1VWdkDBTuMTq520Yt_pXaLC-Pimk',
    appId: '1:177683041939:web:09b57fbc044e5f604ec766',
    messagingSenderId: '177683041939',
    projectId: 'smilehub-ecommerce',
    authDomain: 'smilehub-ecommerce.firebaseapp.com',
    storageBucket: 'smilehub-ecommerce.firebasestorage.app',
  );
}
