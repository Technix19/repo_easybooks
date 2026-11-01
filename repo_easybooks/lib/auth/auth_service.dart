import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Regular logins do not send an email or consume the email quota.
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      // Signup confirmation emails are still enabled if configured in Supabase.
      emailRedirectTo: '${Uri.base.origin}/#/login',
    );
  }

  // Password resets use a single email on demand, not on every login.
  // Use a query marker (not a second # fragment) to survive auth callbacks.
  Future<void> requestPasswordReset(String email) {
    return _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: '${Uri.base.origin}/?recovery=1',
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _supabase.auth.signOut();

  String? getCurrentUserEmail() => _supabase.auth.currentUser?.email;
}
