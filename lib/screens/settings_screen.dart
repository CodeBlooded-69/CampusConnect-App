import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. IMPORT THE LEGAL SCREEN
// Make sure the file 'legal_screen.dart' exists in the 'lib/screens/' folder.
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  String _location = "Bangalore, India";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- SECTION 1: GENERAL ---
          _buildSectionHeader("General"),

          // Location
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Colors.green),
              ),
              title: Text(
                "Location",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _location,
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.pink),
                onPressed: _showLocationDialog,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Switches
          _buildSwitchTile(
            "Push Notifications",
            _notifications,
            (val) => setState(() => _notifications = val),
          ),

          _buildSwitchTile(
            "Dark Mode",
            _darkMode,
            (val) => setState(() => _darkMode = val),
          ),

          const SizedBox(height: 30),

          // --- SECTION 2: LEGAL ---
          _buildSectionHeader("Legal & Support"),

          // Terms & Policy Button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.gavel_outlined, color: Colors.black87),
              title: Text(
                "Terms & Policy",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                // 🚀 FIXED: Removed 'const' and ensured import exists
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LegalScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // App Version (Static)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.black87),
              title: Text(
                "App Version",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              trailing: const Text(
                "v1.0.0",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // --- SECTION 3: DANGER ZONE ---
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: Text(
              "Log Out",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        value: value,
        activeColor: const Color(0xFFFD297B),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  void _showLocationDialog() {
    TextEditingController locController = TextEditingController(
      text: _location,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Location"),
        content: TextField(
          controller: locController,
          decoration: const InputDecoration(hintText: "Enter city..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _location = locController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFD297B),
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
