import 'package:flutter/material.dart';
import 'package:repo_easybooks/login_page.dart';
import 'package:repo_easybooks/widget_tree.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        return session != null ? const WidgetTree() : const LoginPage();
      },
    );
  }
}
