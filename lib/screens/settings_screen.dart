import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  String _location = "Bangalore, India"; // Default/Mock Location

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- LOCATION SETTING (Restored) ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on, color: Colors.green),
            ),
            title: Text(
              "Location",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _location,
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.pink),
              onPressed: () {
                _showLocationDialog();
              },
            ),
          ),
          const Divider(height: 30),

          // --- OTHER SETTINGS ---
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Push Notifications"),
            value: _notifications,
            activeColor: Colors.pink,
            onChanged: (bool value) {
              setState(() => _notifications = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Dark Mode"),
            value: _darkMode,
            activeColor: Colors.pink,
            onChanged: (bool value) {
              setState(() => _darkMode = value);
            },
          ),
          const Divider(height: 30),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Terms of Service"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // Popup to edit location
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
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
