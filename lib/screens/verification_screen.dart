import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // Import your login screen to allow logout

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  Timer? _timer;
  bool _isEmailSent = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // 1. Check every 3 seconds if they verified the email in the background
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _auth.currentUser?.reload(); // Refresh user data
      if (_auth.currentUser?.emailVerified == true) {
        timer.cancel();
        // Reload the app logic to send them to Home
        Navigator.of(
          context,
        ).pushReplacementNamed('/'); // Or however you route to home
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      setState(() {
        _isEmailSent = true;
        _message = "Verification link sent! Check your inbox.";
      });
    } catch (e) {
      setState(() => _message = "Error: $e");
    }
  }

  Future<void> _updateEmail() async {
    if (_emailController.text.trim().isEmpty) return;
    try {
      // 2. Update the email on the account
      await _auth.currentUser?.verifyBeforeUpdateEmail(
        _emailController.text.trim(),
      );
      setState(
        () => _message = "Verification sent to new email! Please check it.",
      );
    } catch (e) {
      setState(
        () => _message = "Error: $e (You may need to logout and login again)",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Verify Email"),
        actions: [
          TextButton(
            onPressed: () async {
              await _auth.signOut();
              // Navigate back to Login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              "Verification Required",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "To keep your account secure, please verify your email: ${user?.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            if (_message != null)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.amber.shade100,
                child: Text(
                  _message!,
                  style: const TextStyle(color: Colors.brown),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // OPTION 1: Resend Link
            ElevatedButton.icon(
              onPressed: _isEmailSent ? null : _sendVerification,
              icon: const Icon(Icons.send),
              label: const Text("Send Verification Link"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            const Divider(height: 50),

            // OPTION 2: Change Email
            const Text(
              "Wrong email? Change it here:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "New Email Address",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _updateEmail,
              child: const Text("Update Email & Verify"),
            ),
          ],
        ),
      ),
    );
  }
}
