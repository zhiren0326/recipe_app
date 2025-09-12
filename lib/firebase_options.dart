import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
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
    apiKey: 'AIzaSyCnfJVjXBRz3d7B-XFbB3dcAYrkiJSeblo',
    appId: '1:808235810059:web:1b9cc94ca7af8b53d6760e',
    messagingSenderId: '808235810059',
    projectId: 'recepi-app-d3346',
    authDomain: 'recepi-app-d3346.firebaseapp.com',
    storageBucket: 'recepi-app-d3346.firebasestorage.app',
    measurementId: 'G-B5GYHKX9M2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBSnuG57tQ8xBUnqc41lSgxR62oEfwFfMo',
    appId: '1:808235810059:android:28c9dbe16348f447d6760e',
    messagingSenderId: '808235810059',
    projectId: 'recepi-app-d3346',
    storageBucket: 'recepi-app-d3346.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD0VSbaoR4hEX71dc4408htzokwjflZNQ4',
    appId: '1:808235810059:ios:97373eca7a70f1dcd6760e',
    messagingSenderId: '808235810059',
    projectId: 'recepi-app-d3346',
    storageBucket: 'recepi-app-d3346.firebasestorage.app',
    iosBundleId: 'com.example.recipeApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD0VSbaoR4hEX71dc4408htzokwjflZNQ4',
    appId: '1:808235810059:ios:97373eca7a70f1dcd6760e',
    messagingSenderId: '808235810059',
    projectId: 'recepi-app-d3346',
    storageBucket: 'recepi-app-d3346.firebasestorage.app',
    iosBundleId: 'com.example.recipeApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCnfJVjXBRz3d7B-XFbB3dcAYrkiJSeblo',
    appId: '1:808235810059:web:0d365cbdb1cb20e8d6760e',
    messagingSenderId: '808235810059',
    projectId: 'recepi-app-d3346',
    authDomain: 'recepi-app-d3346.firebaseapp.com',
    storageBucket: 'recepi-app-d3346.firebasestorage.app',
    measurementId: 'G-FDMFGWVYRV',
  );
}


