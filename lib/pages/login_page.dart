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

      if (savedEmail != null &&
          savedPassword != null &&
          savedEmail.isNotEmpty &&
          savedPassword.isNotEmpty) {

        setState(() {
          _loading = true;
        });

        try {

          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }

        } catch (e) {

          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
        }

        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {

    if (_emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'saved_email',
        _emailCtrl.text.trim(),
      );

      await prefs.setString(
        'saved_password',
        _passCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
              (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {

      String error = "Login Failed";

      if (e.code == 'user-not-found') {
        error = "User not found";
      }

      if (e.code == 'wrong-password') {
        error = "Wrong password";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0F172A),

      body: _loading

          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
        ),
      )

          : SingleChildScrollView(

        child: ConstrainedBox(

          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Container(

                height: 260,

                decoration: const BoxDecoration(

                  gradient: LinearGradient(

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,

                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFF2563EB),
                    ],
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

                      Icon(
                        Icons.fitness_center,
                        size: 85,
                        color: Colors.white,
                      ),

                      SizedBox(height: 15),

                      Text(
                        "GYM POWER",

                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        "Fitness Management System",

                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
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

                      "Welcome Back",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(

                      "Login to your account",

                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 35),

                    TextField(

                      controller: _emailCtrl,

                      style: const TextStyle(
                        color: Colors.white,
                      ),

                      decoration: InputDecoration(

                        hintText: "Email",

                        hintStyle: const TextStyle(
                          color: Colors.white54,
                        ),

                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFF8B5CF6),
                        ),

                        filled: true,

                        fillColor: const Color(0xFF1E293B),

                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(

                      controller: _passCtrl,

                      obscureText: !_showPass,

                      style: const TextStyle(
                        color: Colors.white,
                      ),

                      decoration: InputDecoration(

                        hintText: "Password",

                        hintStyle: const TextStyle(
                          color: Colors.white54,
                        ),

                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF8B5CF6),
                        ),

                        suffixIcon: IconButton(

                          icon: Icon(

                            _showPass
                                ? Icons.visibility
                                : Icons.visibility_off,

                            color: Colors.white70,
                          ),

                          onPressed: () {

                            setState(() {
                              _showPass = !_showPass;
                            });
                          },
                        ),

                        filled: true,

                        fillColor: const Color(0xFF1E293B),

                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    SizedBox(

                      width: double.infinity,
                      height: 58,

                      child: ElevatedButton(

                        onPressed: _loading ? null : _login,

                        style: ElevatedButton.styleFrom(

                          backgroundColor: const Color(0xFF8B5CF6),

                          foregroundColor: Colors.white,

                          disabledBackgroundColor:
                          const Color(0xFF8B5CF6),

                          elevation: 8,

                          shadowColor: Colors.deepPurpleAccent,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),

                        child: _loading

                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )

                            : const Text(

                          "LOGIN",

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        const Text(

                          "Don't have an account?",

                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        TextButton(

                          onPressed: () {

                            Navigator.pushNamed(
                              context,
                              '/signup',
                            );
                          },

                          child: const Text(

                            "Sign Up",

                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
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