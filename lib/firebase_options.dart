import 'package:firebase_core/firebase_core.dart';

// Public Firebase client configuration only; no administrator credentials.
class DefaultFirebaseOptions {
  static const android = FirebaseOptions(
    apiKey: "AIzaSyASJgUryCan4uUMxpbKA65bGs1IHLfG4o8",
    appId: "1:187446302546:android:ae14709cab90f9f26acc8b",
    messagingSenderId: "187446302546",
    projectId: "recipebox-qe190133",
    storageBucket: "recipebox-qe190133.firebasestorage.app",
  );
  static FirebaseOptions get currentPlatform => android;
}
