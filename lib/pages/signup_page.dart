// lib/pages/signup_page.dart
// Signup screen improvements
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {

    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (_passCtrl.text.length < 6) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (_passCtrl.text != _confirmCtrl.text) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {

      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(

        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      await credential.user?.updateDisplayName(
        _nameCtrl.text.trim(),
      );

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created Successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {

      String error = "Signup Failed";

      if (e.code == 'email-already-in-use') {
        error = "Email already in use";
      }

      if (e.code == 'weak-password') {
        error = "Weak password";
      }

      if (e.code == 'invalid-email') {
        error = "Invalid email";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
        ),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(

        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(

          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
      ),

      body: SingleChildScrollView(

        child: Column(

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
                      Icons.person_add_alt_1,
                      size: 85,
                      color: Colors.white,
                    ),

                    SizedBox(height: 15),

                    Text(

                      "CREATE ACCOUNT",

                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(

                      "Join Gym Power Today",

                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
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

                  TextField(

                    controller: _nameCtrl,

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    decoration: InputDecoration(

                      hintText: "Full Name",

                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),

                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFF8B5CF6),
                      ),

                      filled: true,

                      fillColor: const Color(0xFF1E293B),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

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

                        onPressed: () {

                          setState(() {
                            _showPass = !_showPass;
                          });
                        },

                        icon: Icon(

                          _showPass
                              ? Icons.visibility
                              : Icons.visibility_off,

                          color: Colors.white70,
                        ),
                      ),

                      filled: true,

                      fillColor: const Color(0xFF1E293B),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(

                    controller: _confirmCtrl,

                    obscureText: !_showConfirm,

                    style: const TextStyle(
                      color: Colors.white,
                    ),

                    decoration: InputDecoration(

                      hintText: "Confirm Password",

                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),

                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF8B5CF6),
                      ),

                      suffixIcon: IconButton(

                        onPressed: () {

                          setState(() {
                            _showConfirm = !_showConfirm;
                          });
                        },

                        icon: Icon(

                          _showConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,

                          color: Colors.white70,
                        ),
                      ),

                      filled: true,

                      fillColor: const Color(0xFF1E293B),

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

                      onPressed: _loading ? null : _signup,

                      style: ElevatedButton.styleFrom(

                        backgroundColor: const Color(0xFF8B5CF6),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      child: _loading

                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )

                          : const Text(

                        "SIGN UP",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

                        "Already have an account?",

                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      TextButton(

                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text(

                          "Login",

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
    );
  }
}