// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyAXvNIBfMUzE4spTCUq-jF-uIdaXKK10xA',
    appId: '1:425464564023:web:b0df2f71bd0c9633d932b2',
    messagingSenderId: '425464564023',
    projectId: 'rentalps-65328',
    authDomain: 'rentalps-65328.firebaseapp.com',
    storageBucket: 'rentalps-65328.firebasestorage.app',
    measurementId: 'G-TLFWC4Q8N0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbvFg8W7Eg6j2NyS-oF6aVUHp3xSVmd8U',
    appId: '1:425464564023:android:f691b67014ece93ed932b2',
    messagingSenderId: '425464564023',
    projectId: 'rentalps-65328',
    storageBucket: 'rentalps-65328.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBX5gJPmu24oPDy204mh2ioegNgGTth6-M',
    appId: '1:425464564023:ios:88058a4ef709a914d932b2',
    messagingSenderId: '425464564023',
    projectId: 'rentalps-65328',
    storageBucket: 'rentalps-65328.firebasestorage.app',
    iosBundleId: 'com.example.rentalSepeda',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBX5gJPmu24oPDy204mh2ioegNgGTth6-M',
    appId: '1:425464564023:ios:88058a4ef709a914d932b2',
    messagingSenderId: '425464564023',
    projectId: 'rentalps-65328',
    storageBucket: 'rentalps-65328.firebasestorage.app',
    iosBundleId: 'com.example.rentalSepeda',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAXvNIBfMUzE4spTCUq-jF-uIdaXKK10xA',
    appId: '1:425464564023:web:9d70f5c45a57c62ad932b2',
    messagingSenderId: '425464564023',
    projectId: 'rentalps-65328',
    authDomain: 'rentalps-65328.firebaseapp.com',
    storageBucket: 'rentalps-65328.firebasestorage.app',
    measurementId: 'G-3TQYQD8LGT',
  );
}
