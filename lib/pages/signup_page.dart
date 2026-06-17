// lib/pages/signup_page.dart
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
    // Validation
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required"),
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

    setState(() => _loading = true);

    try {
      // Create user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // Update display name
      await credential.user?.updateDisplayName(_nameCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Go back to login
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String error = "Signup failed";

      if (e.code == 'weak-password') {
        error = "Password is too weak";
      } else if (e.code == 'email-already-in-use') {
        error = "Email already registered";
      } else if (e.code == 'invalid-email') {
        error = "Invalid email address";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Something went wrong"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Header
            const Icon(Icons.fitness_center, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Join Gym Power today!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Full Name Field
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person, color: Colors.orange),
                filled: true,
                fillColor: const Color(0xFF2a2a2a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Email Field
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email, color: Colors.orange),
                filled: true,
                fillColor: const Color(0xFF2a2a2a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            TextField(
              controller: _passCtrl,
              obscureText: !_showPass,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Password",
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConfirm,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
                filled: true,
                fillColor: const Color(0xFF2a2a2a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}