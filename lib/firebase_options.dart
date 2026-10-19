import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('This app currently supports web only.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB1c5rac3XnjYlAyqrMRQ5hIQChG8C8eQc',
    appId: '1:106969591080:web:48e1a78aeece86ac99f41d',          // e.g. 1:123456789:web:abc123
    messagingSenderId: '106969591080', // e.g. 123456789
    projectId: 'masjid-app-f5caa',        // e.g. mosque-system-12345
    authDomain: 'https://masjid-app-f5caa.firebaseapp.com',
    storageBucket: 'masjid-app-f5caa.firebasestorage.app',
  );
}