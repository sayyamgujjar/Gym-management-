// lib/pages/login_page.dart - Web Auto-Login Solution
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  
  Future<void> _autoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');

      debugPrint('🔍 Checking saved credentials...');
      debugPrint('Saved Email: $savedEmail');

      // Agar email aur password saved hain, to automatic login karo
      if (savedEmail != null &&
          savedPassword != null &&
          savedEmail.isNotEmpty &&
          savedPassword.isNotEmpty) {

        debugPrint('✅ Found saved credentials, auto-login...');
        setState(() => _loading = true);

        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );

          debugPrint('✅ AUTO-LOGIN SUCCESS');

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (e) {
          debugPrint('❌ Auto-login failed: $e');
          // Credentials galat hain, clear kar do
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
        }

        if (mounted) {
          setState(() => _loading = false);
        }
      } else {
        debugPrint('ℹ️ No saved credentials found');
      }
    } catch (e) {
      debugPrint('❌ Error in auto-login: $e');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Login karo
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      debugPrint('✅ LOGIN SUCCESS');

      // ⭐ Credentials save karo (auto-login ke liye)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', _emailCtrl.text.trim());
      await prefs.setString('saved_password', _passCtrl.text.trim());

        debugPrint('💾 Credentials saved for auto-login');

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ LOGIN ERROR: ${e.code}');

      String error = "Login failed";
      if (e.code == 'user-not-found') error = "No user found with this email";
      if (e.code == 'wrong-password') error = "Wrong password";
      if (e.code == 'invalid-email') error = "Invalid email address";
      if (e.code == 'invalid-credential') error = "Invalid email or password";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('❌ UNEXPECTED ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong")),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1a1a1a),
      body: _loading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Logging in...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Container(
                height: 250,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 80, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'GYM POWER',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Management System',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Login to your account',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.email, color: Colors.orange),
                        filled: true,
                        fillColor: Color(0xFF2a2a2a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passCtrl,
                      obscureText: !_showPass,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPass ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2a2a2a),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}