// lib/main.dart - UPDATED VERSION WITH FIXED EMOJIS
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/members_page.dart';
import 'pages/attendance_page.dart';
import 'pages/signup_page.dart';
import 'pages/payments_page.dart';
import 'pages/reports_page.dart';
import 'pages/trainers_page.dart';
import 'pages/membership_plans_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // â­ WEB KE LIYE PERSISTENCE SET KARNA ZAROORI HAI
  if (kIsWeb) {
    // Web par LOCAL persistence set karo - ye browser close hone ke baad bhi rehti hai
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    debugPrint('âœ… WEB: Firebase persistence set to LOCAL (IndexedDB)');
  } else {
    // Mobile/Desktop par automatic persist hota hai
    debugPrint('âœ… MOBILE/DESKTOP: Using default persistence');
  }

  // Current user check karo
  final currentUser = FirebaseAuth.instance.currentUser;
  debugPrint('ðŸ” App Start - Current User: ${currentUser?.email ?? "None"}');

  runApp(const GymManagementApp());
}

class GymManagementApp extends StatelessWidget {
  const GymManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Power',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        // â­ Added label style for better text field appearance
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => HomePage(),
        '/members': (context) => const MembersPage(),
        '/attendance': (context) => const AttendancePage(),
        '/payments': (context) => PaymentsPage(),
        '/reports': (context) => ReportsPage(),
        '/trainers': (context) => TrainersPage(),
        '/plans': (context) => const MembershipPlansPage(),
      },
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
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1a1a1a),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;

        // Debug logs
        debugPrint('ðŸ‘¤ Auth State: ${user != null ? "Logged In (${user.email})" : "Not Logged In"}');

        if (user != null) {
          return HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}