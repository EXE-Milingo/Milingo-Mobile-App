import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Firebase initialization provider
/// Ensures Firebase is initialized before app starts
///
/// Usage in main.dart:
/// ```dart
/// await ref.read(firebaseInitializerProvider.future);
/// ```
@riverpod
Future<FirebaseApp> firebaseInitializer(FirebaseInitializerRef ref) async {
  return await Firebase.initializeApp(
      // TODO: Add Firebase configuration options here
      // Get these from Firebase Console -> Project Settings
      // options: DefaultFirebaseOptions.currentPlatform,
      );
}

/// Firebase Auth instance provider
/// Provides access to Firebase Authentication
// @riverpod
// FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
//   return FirebaseAuth.instance;
// }

/// Firestore instance provider
/// Provides access to Cloud Firestore database
// @riverpod
// FirebaseFirestore firestore(FirestoreRef ref) {
//   return FirebaseFirestore.instance;
// }

// Note: Uncomment the above providers when Firebase is fully configured
// For now, they're commented to avoid compilation errors without Firebase setup
