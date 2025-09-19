import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store verification codes temporarily (fake implementation)
  static final Map<String, String> _verificationCodes = {};

  // Check if email exists in Firebase Auth
  static Future<bool> checkEmailExists(String email) async {
    // Basic email format validation first
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return false;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      // If no error thrown, email is probably registered (or Firebase accepted it)
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // definitely email isn't registered
        return false;
      } else {
        // some other error, maybe network, invalid-email, etc.
        rethrow;
      }
    } catch (e) {
      // other unexpected error
      print('Error in checkEmailExists: $e');
      return false;
    }
  }

  // Generate and store verification code
  static String generateVerificationCode(String email) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = (random % 9000 + 1000).toString(); // Generate 4-digit code
    _verificationCodes[email] = code;

    // Remove code after 10 minutes
    Future.delayed(const Duration(minutes: 10), () {
      _verificationCodes.remove(email);
    });

    return code;
  }

  // Verify the entered code
  static bool verifyCode(String email, String code) {
    final storedCode = _verificationCodes[email];
    return storedCode != null && storedCode == code;
  }

  // Update password in Firebase Auth
  static Future<void> updatePassword(String email, String newPassword) async {
    try {
      // For demo purposes, we'll simulate the password update
      // In a real app, you would need to use Firebase Admin SDK or have the current password
      
      print('Password updated for: $email');
      print('New password: $newPassword');
      
      // Simulate a delay to show the process
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, you would:
      // 1. Use Firebase Admin SDK to update the password directly
      // 2. Or require the user to sign in with their current password first
      // 3. Or use Firebase's built-in password reset flow
      
    } catch (e) {
      print('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  // Clear verification code after successful password update
  static void clearVerificationCode(String email) {
    _verificationCodes.remove(email);
  }
}
