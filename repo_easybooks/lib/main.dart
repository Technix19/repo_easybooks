//import 'package:easybooks/auth/auth_gate.dart';
//import 'package:easybooks/login_page.dart';
////import 'package:easybooks/widget_tree.dart';
import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

import 'package:supabase_flutter/supabase_flutter.dart'; // web-only

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://keprvxiclcxdvasdxpey.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlcHJ2eGljbGN4ZHZhc2R4cGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxNTAwNzMsImV4cCI6MjA3NTcyNjA3M30.LCJhKBsmjsdahFJ4vrbpqgQVPhy31EINNX03rQ9o90Q',
  );

  if (kIsWeb) {
    final uri = Uri.base;
    final hasTokensInHash =
        uri.fragment.contains('access_token') ||
        uri.fragment.contains('refresh_token');
    final hasTokensInQuery =
        uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('token_hash');

    if (hasTokensInHash || hasTokensInQuery) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);

        // keep your landing hash (to hit AuthGate at '/')
        final clean = uri.replace(queryParameters: {}, fragment: '/');
        html.window.history.replaceState(null, '', clean.toString());
      } catch (_) {}
    }
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6FFF43),
          brightness: Brightness.dark,
        ),
      ),

      routes: {
        //'/': (_) => const AuthGate(),
        //'/login': (_) => const LoginPage(),
        //'/home': (_) => const WidgetTree(),
      },
    );
  }
}
