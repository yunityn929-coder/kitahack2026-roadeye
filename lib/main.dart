import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:roadeye_dashboard/dashboard_page.dart';
import 'package:roadeye_dashboard/login_page.dart';
import 'package:roadeye_dashboard/signup_page.dart';
// import 'dart:js' as js;
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ui.platformViewRegistry.registerViewFactory(
    'map-canvas',
    (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = 'map-container';
      div.style.width = '100%';
      div.style.height = '100%';
      div.style.backgroundColor = '#1a1a1a';
      return div;
    },
  );

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAYxARwBwyt-u2fE_X9Hb4pp_eASukxaR4",
      authDomain: "roadeye-hackathon.firebaseapp.com",
      projectId: "roadeye-hackathon",
      storageBucket: "roadeye-hackathon.firebasestorage.app",
      messagingSenderId: "710647556468",
      appId: "1:710647556468:web:1549cc78af8603e2096421",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(primaryColor: Colors.redAccent),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
