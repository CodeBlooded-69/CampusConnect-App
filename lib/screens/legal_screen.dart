import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Legal & Policy",
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFFFD297B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFD297B),
            tabs: [
              Tab(text: "Terms of Service"),
              Tab(text: "Privacy Policy"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_TermsOfServicePage(), _PrivacyPolicyPage()],
        ),
      ),
    );
  }
}

// --- PAGE 1: TERMS OF SERVICE ---
class _TermsOfServicePage extends StatelessWidget {
  const _TermsOfServicePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("1. Acceptance of Terms"),
          _buildText(
            "By downloading or using CampusConnect, these terms will automatically apply to you. You should make sure therefore that you read them carefully before using the app.",
          ),

          _buildHeader("2. Eligibility"),
          _buildText(
            "You must be at least 18 years of age and a currently enrolled student at a university to use this Service. By creating an account, you warrant that you can form a binding contract with CampusConnect.",
          ),

          _buildHeader("3. User Conduct"),
          _buildText("You agree strictly NOT to:"),
          _buildBullet("Harass, bully, or intimidate other users."),
          _buildBullet("Post explicit, violent, or illegal content."),
          _buildBullet("Impersonate any person or entity."),
          _buildText(
            "Violation of these rules will result in an immediate and permanent ban.",
          ),

          _buildHeader("4. Account Termination"),
          _buildText(
            "We reserve the right to terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.",
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- PAGE 2: PRIVACY POLICY ---
class _PrivacyPolicyPage extends StatelessWidget {
  const _PrivacyPolicyPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("1. Data Collection"),
          _buildText("We collect minimal data to function:"),
          _buildBullet(
            "Personal Info: Name, Email, Major, Campus (for matching).",
          ),
          _buildBullet("Usage Data: Swipes, Matches, and Chat history."),

          _buildHeader("2. How We Use Data"),
          _buildText("We use your data strictly to:"),
          _buildBullet("Connect you with students on your campus."),
          _buildBullet("Improve our matching algorithm."),
          _buildBullet("Ensure platform safety and moderation."),

          _buildHeader("3. Data Security"),
          _buildText(
            "Your data is stored securely on Google Firebase Cloud Servers. We implement industry-standard security measures to prevent unauthorized access.",
          ),

          _buildHeader("4. Third-Party Services"),
          _buildText(
            "We may employ third-party companies (like Google Analytics or ImgBB) to facilitate our Service. These third parties have access to your Personal Information only to perform these tasks on our behalf.",
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS FOR STYLING ---
Widget _buildHeader(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );
}

Widget _buildText(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: Colors.grey[800],
      ),
    ),
  );
}

Widget _buildBullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5, left: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "• ",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.4,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    ),
  );
}
