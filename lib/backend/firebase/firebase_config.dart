import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDbXvuRMWCfsPCo183M0NuVAM9zCwyei24",
            authDomain: "project-for-management-sugxvo.firebaseapp.com",
            projectId: "project-for-management-sugxvo",
            storageBucket: "project-for-management-sugxvo.firebasestorage.app",
            messagingSenderId: "1032725524363",
            appId: "1:1032725524363:web:e7c7ae3832f8a4d748498e",
            measurementId: "G-FW25HFKG0F"));
  } else {
    await Firebase.initializeApp();
  }
}
