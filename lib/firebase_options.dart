import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// إعدادات الربط مع مشروع Firebase: majestic-nova-jk4jk
/// ملاحظة: لتشغيل التطبيق على Android أو iOS باستخدام مشروعك الخاص،
/// نفذ الأمر: dart pub global activate flutterfire_cli && flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCXR7EH6x0sFqn6Tdp77Oi30ieVMC6Wh3A',
    appId: '1:73663633953:web:099b8d61b0f3d7450ce160',
    messagingSenderId: '73663633953',
    projectId: 'majestic-nova-jk4jk',
    authDomain: 'majestic-nova-jk4jk.firebaseapp.com',
    storageBucket: 'majestic-nova-jk4jk.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXR7EH6x0sFqn6Tdp77Oi30ieVMC6Wh3A',
    appId: '1:73663633953:web:099b8d61b0f3d7450ce160',
    messagingSenderId: '73663633953',
    projectId: 'majestic-nova-jk4jk',
    storageBucket: 'majestic-nova-jk4jk.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXR7EH6x0sFqn6Tdp77Oi30ieVMC6Wh3A',
    appId: '1:73663633953:web:099b8d61b0f3d7450ce160',
    messagingSenderId: '73663633953',
    projectId: 'majestic-nova-jk4jk',
    storageBucket: 'majestic-nova-jk4jk.firebasestorage.app',
    iosBundleId: 'com.example.phonesync',
  );
}
