import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stable stream that monitors authentication changes.
  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  // Get the currently signed-in user.
  User? get currentUser => _auth.currentUser;

  // Register a new user.
  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign in an existing user.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign out the current user.
  Future<void> signOut() {
    return _auth.signOut();
  }

  // Update the current user's password.
  Future<void> changePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to change your password.');
    }

    if (newPassword.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        rethrow;
      }

      final email = user.email;

      if (email == null || email.isEmpty) {
        throw StateError('No email is available for reauthentication.');
      }

      if (currentPassword == null || currentPassword.isEmpty) {
        throw StateError(
          'Enter your current password to confirm your identity.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }
  }
}
