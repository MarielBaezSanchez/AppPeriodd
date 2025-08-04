import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBL-loTivfMGlC5AoRYK4vf6-WlruDP8eE',
      appId: '1:308107534308:android:8d2bae4ef8b6a63569b1f1',
      messagingSenderId: '308107534308',
      projectId: 'calma360-28c00',
     // storageBucket: 'calma360-2e792.firebasestorage.app', // Opcional
    );
  }
}
