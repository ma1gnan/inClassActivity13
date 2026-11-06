import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF172A45),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to Your Profile!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Signed in as:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email ?? 'Email unavailable',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _changePassword,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Change Password'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(_isLoading ? 'Signing Out...' : 'Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.changePassword(
        _newPasswordController.text,
        currentPassword: _currentPasswordController.text,
      );

      if (!mounted) return;

      /**Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
        ),
      );*/

      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      messenger.showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'Current password is incorrect.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Please choose a stronger password.';
        } else if (e.code == 'requires-recent-login') {
          _errorMessage = 'Please confirm your current password and try again.';
        } else {
          _errorMessage = 'Password update failed: ${e.code}';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e is StateError || e is ArgumentError
            ? e.toString()
            : 'Unable to update password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePassword,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
