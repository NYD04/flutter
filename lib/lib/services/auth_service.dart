import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Test credentials
  static const String testEmail = 'user@gmail.com';
  static const String testPassword = 'password';
  
  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;
  
  // Sign in with test credentials
  static Future<UserCredential?> signInWithTestCredentials() async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }
  
  // Create test user if it doesn't exist
  static Future<void> createTestUserIfNeeded() async {
    try {
      // Try to sign in first
      await _auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Create the test user
        try {
          await _auth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
          print('Test user created successfully');
        } catch (createError) {
          print('Error creating test user: $createError');
        }
      } else {
        print('Sign in error: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
