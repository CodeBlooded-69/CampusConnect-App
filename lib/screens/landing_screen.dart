import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// IMPORTANT: Import your actual Login and Register screens here
import 'login_screen.dart';
import 'register_screen.dart'; // Ensure this file exists!

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // App Colors
  final Color _accentColor = const Color(0xFFFD297B);
  final Color _backgroundColor = const Color(0xFF111418);
  final Color _textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // --- 1. BACKGROUND IMAGE OR GRADIENT ---
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFD297B), // Pink top
                    Color(0xFFFF5864), // Red/Orange middle
                    Color(0xFF111418), // Dark bottom
                  ],
                  stops: [0.0, 0.4, 0.8], // Control where colors blend
                ),
              ),
            ),
          ),

          // --- 2. DARK OVERLAY (for text readability) ---
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // --- 3. CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Push content to bottom
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // APP LOGO OR ICON
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(Icons.favorite, color: _accentColor, size: 45),
                  ),

                  const SizedBox(height: 30),

                  // WELCOME TEXT
                  Text(
                    "Find your\nCampus Match",
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Connect with students nearby, make friends, or find that special someone within your campus.",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // --- CREATE ACCOUNT BUTTON (Direct Navigation) ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // FIX: Navigates directly to RegisterScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _accentColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Create an account",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- LOGIN BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TERMS TEXT
                  Center(
                    child: Text(
                      "By continuing you agree to our Terms & Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
