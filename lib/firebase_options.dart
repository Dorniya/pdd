import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDPsNhg20JA6f4oI95i8L-VQYmR0aCehfI",
    authDomain: "yoga-app-2026-f1f7b.firebaseapp.com",
    projectId: "yoga-app-2026-f1f7b",
    storageBucket: "yoga-app-2026-f1f7b.firebasestorage.app",
    messagingSenderId: "939293467867",
    appId: "1:939293467867:web:ae099f2a5b2ff01a7a58fe",
    measurementId: "G-1NV6PPJXN9",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBiUnlexVQdNhunE0E83immBPuWr_LsM10",
    appId: "1:939293467867:android:0e197f607dd23d947a58fe",
    messagingSenderId: "939293467867",
    projectId: "yoga-app-2026-f1f7b",
    storageBucket: "yoga-app-2026-f1f7b.firebasestorage.app",
  );
}
