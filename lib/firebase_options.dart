import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyDCTVA9TnrshESvJMZbZz8wqaSTvVQ5uTw',
      appId: '1:346445981396:android:f4cc0e088d12875cf9bd41',
      messagingSenderId: '346445981396',
      projectId: 'calma360-2e792',
      storageBucket: 'calma360-2e792.firebasestorage.app', // Opcional
    );
  }
}
