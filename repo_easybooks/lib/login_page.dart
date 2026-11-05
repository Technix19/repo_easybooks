import 'package:repo_easybooks/theme/easybooks_theme.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:repo_easybooks/auth/auth_service.dart';
import 'package:repo_easybooks/forgot_pass.dart';
import 'package:repo_easybooks/signup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _hidePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      // The public homepage stays at /; signed-in users open /dashboard.
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } on AuthException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Unable to sign in right now. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red.shade700, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EasyBooksTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final loginPanel = Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'EasyBooks',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 27),
                        ),
                        const SizedBox(height: 60),
                        const Text(
                          'Log in to your account',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Use your email and password. No magic link needed.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 36),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _logIn(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              tooltip: _hidePassword ? 'Show password' : 'Hide password',
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Enter your password'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPage(),
                                      ),
                                    ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EasyBooksTheme.accent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _isSubmitting ? null : _logIn,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Log in'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const SignUpPage(),
                                        ),
                                      ),
                              child: const Text('Sign up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            if (!wide) return loginPanel;

            return Row(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome to EasyBooks!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
                          ),
                          const SizedBox(height: 24),
                          Lottie.asset('assets/lotties/analytics.json', width: 440),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 500,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey)),
                  ),
                  child: loginPanel,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
