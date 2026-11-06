import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../screens/authentication_screen.dart';
import '../screens/profile_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to check sign-in status. '
                'Please restart the app.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return ProfileScreen(user: snapshot.data!);
        }

        return const AuthenticationScreen();
      },
    );
  }
}
