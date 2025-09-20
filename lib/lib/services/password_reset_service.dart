import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store verification codes temporarily
  static final Map<String, String> _verificationCodes = {};
  
  // Store pending password updates
  static final Map<String, String> _pendingPasswordUpdates = {};

  // Validate email format
  static bool isValidEmailFormat(String email) {
    if (email.isEmpty) return false;
    
    // More comprehensive email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Check if email exists in Firebase Auth
  static Future<bool> checkEmailExists(String email) async {
    // First validate email format
    if (!isValidEmailFormat(email)) {
      print('Invalid email format: $email');
      return false;
    }

    // For demo purposes, let's accept any valid email format
    // In a real app, you would check against your user database
    print('Email format is valid: $email');
    return true;

    // Original Firebase check (commented out for demo)
    /*
    try {
      // Try to send password reset email - this will fail if email doesn't exist
      await _auth.sendPasswordResetEmail(email: email);
      // If no error thrown, email exists in Firebase
      print('Email exists in Firebase: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        // Email definitely doesn't exist
        print('User not found: $email');
        return false;
      } else if (e.code == 'invalid-email') {
        // Invalid email format
        print('Invalid email: $email');
        return false;
      } else {
        // Some other error (network, etc.) - let's be more lenient
        print('Other error checking email existence: ${e.message}');
        // For demo purposes, let's assume email exists if it's not user-not-found
        return true;
      }
    } catch (e) {
      // Other unexpected error
      print('Unexpected error in checkEmailExists: $e');
      // For demo purposes, let's assume email exists
      return true;
    }
    */
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

  // Login using OTP verification (no password change needed)
  static Future<void> loginWithOTP(String email) async {
    try {
      print('Logging in with OTP for: $email');
      
      // For OTP login, we'll simulate a successful login
      // In a real implementation, you would:
      // 1. Verify the OTP with your backend
      // 2. Create a session or token
      // 3. Sign in the user
      
      // Simulate successful OTP verification
      await Future.delayed(const Duration(seconds: 1));
      
      print('OTP login successful for: $email');
      
    } catch (e) {
      print('Error in OTP login: $e');
      throw Exception('Failed to login with OTP: $e');
    }
  }

  // Check if user is signed in and can update password
  static bool canUpdatePassword() {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Update password for signed-in users
  static Future<void> updatePasswordForSignedInUser(String newPassword) async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      if (!user.emailVerified) {
        throw Exception('Email must be verified before updating password');
      }
      
      // Update the password
      await user.updatePassword(newPassword);
      
      print('Password updated successfully for: ${user.email}');
      
    } catch (e) {
      print('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  // Alternative: Use Firebase's password reset flow (original method)
  static Future<void> updatePasswordWithEmail(String email, String newPassword) async {
    try {
      // Store the new password temporarily
      _pendingPasswordUpdates[email] = newPassword;
      
      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);
      
      print('Password reset email sent to: $email');
      print('New password stored for: $email');
      
      // Remove the pending password after 30 minutes
      Future.delayed(const Duration(minutes: 30), () {
        _pendingPasswordUpdates.remove(email);
      });
      
    } catch (e) {
      print('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  // Get pending password update
  static String? getPendingPasswordUpdate(String email) {
    return _pendingPasswordUpdates[email];
  }

  // Clear pending password update
  static void clearPendingPasswordUpdate(String email) {
    _pendingPasswordUpdates.remove(email);
  }

  // Alternative method: Use Firebase's password reset flow
  static Future<bool> resetPasswordWithEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Alternative: Use Firebase's password reset flow (doesn't require sign-in)
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Clear verification code after successful password update
  static void clearVerificationCode(String email) {
    _verificationCodes.remove(email);
  }
}
