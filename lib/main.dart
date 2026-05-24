import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Gym Management',

      theme: ThemeData(

        brightness: Brightness.dark,

        primarySwatch: Colors.orange,

        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),

      // ROUTES
      routes: {

        '/login': (context) => const LoginPage(),

        '/signup': (context) => const SignUpPage(),

        '/home': (context) => const HomePage(),
      },

      // FIRST SCREEN
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(

      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        // LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {

          return const Scaffold(

            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // USER LOGIN
        if (snapshot.hasData) {

          return const HomePage();
        }

        // USER NOT LOGIN
        return const LoginPage();
      },
    );
  }
}