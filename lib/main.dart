import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/multi_step_profile_screen.dart'; // Ensure this matches your file name
import 'screens/verification_screen.dart'; // <--- NEW IMPORT

// --- 1. GLOBAL THEME CONTROLLER ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _initialization = _initFirebase();

  static Future<FirebaseApp> _initFirebase() async {
    if (kIsWeb) {
      return await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB1dLSbgBs0Ee1T7ARIPMSH-tnfhpJmPh8",
          authDomain: "campus-dating-app-8e62d.firebaseapp.com",
          projectId: "campus-dating-app-8e62d",
          storageBucket: "campus-dating-app-8e62d.firebasestorage.app",
          messagingSenderId: "841295068737",
          appId: "1:841295068737:web:1c33692ff2d884a46390c0",
          measurementId: "G-Q28TLS135F",
        ),
      );
    } else {
      return await Firebase.initializeApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. LISTEN TO THEME CHANGES ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CampusConnect', // Updated Name
          // --- LIGHT THEME ---
          theme: ThemeData(
            primarySwatch: Colors.pink,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            primarySwatch: Colors.pink,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            textTheme: GoogleFonts.interTextTheme(
              Theme.of(context).textTheme.apply(bodyColor: Colors.white),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1F1F1F),
              selectedItemColor: Colors.pink,
              unselectedItemColor: Colors.grey,
            ),
          ),

          themeMode: currentMode,

          home: FutureBuilder(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text("Error: ${snapshot.error}")),
                );
              }
              if (snapshot.connectionState == ConnectionState.done) {
                return const AuthWrapper();
              }
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // ⚠️ REPLACE THIS WITH YOUR REAL ADMIN EMAIL
  final String adminEmail = "forckmet7@gmail.com";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Waiting for Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.pink)),
          );
        }

        // 2. Not Logged In
        if (!snapshot.hasData) return const LoginScreen();

        User user = snapshot.data!;

        // --- 🛡️ ADMIN CHECK 🛡️ ---
        if (user.email == adminEmail) {
          // If the logged-in user is YOU, go to Admin Dashboard
          return const AdminDashboardScreen();
        }

        // 3. Normal User Verification Check
        if (!user.emailVerified) {
          return const VerificationScreen();
        }

        // 4. Check Profile Status
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              if (data['isProfileComplete'] == true) {
                return const HomeScreen();
              }
            }
            return const MultiStepProfileScreen();
          },
        );
      },
    );
  }
}
