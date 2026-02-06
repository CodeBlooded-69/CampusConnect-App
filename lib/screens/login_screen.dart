import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_setup_screen.dart';
// Note: SignupScreen import is removed because Google handles account creation automatically.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // --- GOOGLE LOGIN (ONLY OPTION) ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. Trigger Google Sign In Flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      // 2. Obtain Auth Details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // 4. Ensure Firestore Document Exists
        await _checkAndCreateUserProfile(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER: CHECK / CREATE USER DOC ---
  Future<void> _checkAndCreateUserProfile(User user) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      // NEW USER: Create their document
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? '',
        'imageUrls': user.photoURL != null
            ? [user.photoURL]
            : [], // Use Google photo if available
        'isProfileComplete': false, // Force them to do setup
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to Setup
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      }
    } else {
      // EXISTING USER: Check if they finished setup
      final data = userDoc.data();
      bool isComplete = data?['isProfileComplete'] ?? false;

      if (mounted) {
        if (!isComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          );
        } else {
          // If you are using the AuthWrapper in main.dart, you don't actually need to push here.
          // The StreamBuilder will detect the login and switch to Home automatically.
          // However, we can pop just in case.
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFD297B), Color(0xFFFF655B)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // 2. Title
              Text(
                "CampusConnect",
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Swipe. Match. Date.",
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
              ),

              const SizedBox(height: 60),

              // 3. Google Button (The Only Option)
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                          height: 24,
                        ),
                        label: Text(
                          "Continue with Google",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 30),

              // 4. Terms text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "By continuing, you agree to our Terms of Service & Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
