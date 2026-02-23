import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey            = GlobalKey<FormState>();
  final _currentPassCtrl    = TextEditingController();
  final _newPassCtrl        = TextEditingController();
  final _confirmPassCtrl    = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _saving         = false;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _saving = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = (e.code == 'wrong-password' || e.code == 'invalid-credential')
            ? 'Current password is incorrect.'
            : e.message ?? 'Failed to change password.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 72, color: Colors.blue),
              const SizedBox(height: 8),
              const Text(
                'Update your password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _currentPassCtrl,
                obscureText: _obscureCurrent,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your current password' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: _obscureNew,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your new password';
                  if (v != _newPassCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
