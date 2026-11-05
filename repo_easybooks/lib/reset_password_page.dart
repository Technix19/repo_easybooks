import 'package:repo_easybooks/theme/easybooks_theme.dart';
import 'package:flutter/material.dart';
import 'package:repo_easybooks/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _hidePassword = true;
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (Supabase.instance.client.auth.currentSession == null) {
        throw const AuthException('Reset link is invalid or expired. Request another link.');
      }

      await _authService.updatePassword(_passwordController.text);
      // Require a normal password login after resetting the password.
      await _authService.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. You can now sign in.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade700, content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to change password. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    return Scaffold(
      backgroundColor: EasyBooksTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: EasyBooksTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('EasyBooks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      const Text('Choose a new password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (!hasSession)
                        const Text(
                          'This reset link is invalid, expired, or has already been used. Return to login and request another reset email.',
                          style: TextStyle(color: Colors.white70),
                        )
                      else ...[
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'New password',
                            suffixIcon: IconButton(
                              tooltip: _hidePassword ? 'Show password' : 'Hide password',
                              icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            ),
                          ),
                          validator: (value) => (value == null || value.length < 8)
                              ? 'Use at least 8 characters'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _hidePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(labelText: 'Confirm password'),
                          validator: (value) => value != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EasyBooksTheme.accent,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(200, 48),
                          ),
                          onPressed: _saving ? null : _savePassword,
                          child: _saving
                              ? const SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save new password'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login', (route) => false),
                        child: const Text('Back to login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
