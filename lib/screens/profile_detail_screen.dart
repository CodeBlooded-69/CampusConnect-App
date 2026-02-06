import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? userId; // Required to identify which user to delete

  const ProfileDetailScreen({super.key, required this.userData, this.userId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int? _matchPercentage;

  // 🔴 IMPORTANT: Replace this with your ACTUAL admin email address
  final String adminEmail = "forckmet7@gmail.com";

  // Secure Check: Is the current user the admin?
  bool get isAdmin {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Case-insensitive check to be safe
    return currentUser != null &&
        currentUser.email?.toLowerCase() == adminEmail.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _calculateMatchPercentage();
  }

  // --- LOGIC: DELETE USER (ADMIN ONLY) ---
  Future<void> _deleteUser() async {
    final targetUserId = widget.userId ?? widget.userData['uid'];

    if (targetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Cannot identify user.")),
      );
      return;
    }

    // Confirmation Dialog
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete User?"),
            content: const Text(
              "This will permanently remove their profile from the app. This cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      // 1. Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .delete();

      if (mounted) {
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User deleted successfully.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting user: $e")));
    }
  }

  // --- LOGIC: CALCULATE COMPATIBILITY ---
  Future<void> _calculateMatchPercentage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (!myDoc.exists) return;

    final myData = myDoc.data() as Map<String, dynamic>;
    final myAnswers = myData['quizAnswers'] as Map<String, dynamic>?;
    final theirAnswers =
        widget.userData['quizAnswers'] as Map<String, dynamic>?;

    if (myAnswers != null && theirAnswers != null) {
      int matches = 0;
      int total = 5;
      for (String key in myAnswers.keys) {
        if (theirAnswers.containsKey(key) &&
            myAnswers[key] == theirAnswers[key]) {
          matches++;
        }
      }
      if (mounted) {
        setState(() {
          _matchPercentage = ((matches / total) * 100).toInt();
        });
      }
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report User"),
        content: const Text("Is this profile fake or inappropriate?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reported. We will investigate.")),
              );
            },
            child: const Text("Report", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data
    List<dynamic> rawImages = widget.userData['imageUrls'] ?? [];
    List<String> images = rawImages.map((e) => e.toString()).toList();
    if (images.isEmpty)
      images.add('https://via.placeholder.com/400x600.png?text=No+Photos');

    List<dynamic> rawPrompts = widget.userData['prompts'] ?? [];
    List<Map<String, dynamic>> prompts = rawPrompts
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    String name = widget.userData['name'] ?? "Unknown";
    String bio = widget.userData['bio'] ?? "";
    String major = widget.userData['major'] ?? "Student";
    String campus = widget.userData['campus'] ?? "Campus";
    List<dynamic> interests = widget.userData['interests'] ?? [];

    final String heroTag = widget.userId ?? widget.userData['uid'] ?? name;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // --- 1. HERO IMAGE HEADER (SliverAppBar) ---
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // REPORT BUTTON (For Everyone)
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.white),
                onPressed: _showReportDialog,
              ),

              // 🔴 DELETE BUTTON (ONLY FOR ADMIN)
              // 🚀 FIX: Checks 'isAdmin' boolean logic
              if (isAdmin)
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  onPressed: _deleteUser,
                  tooltip: "Admin Delete",
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: images[0],
                        fit: BoxFit.cover,
                        memCacheHeight: 1200,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black87],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- 2. SCROLLABLE CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_matchPercentage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Colors.purple,
                                size: 18,
                              ),
                              Text(
                                "$_matchPercentage% Match",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Sub-header
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.school, size: 18, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        "$major @ $campus",
                        style: GoogleFonts.inter(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // BIO
                  if (bio.isNotEmpty) ...[
                    Text(
                      "About Me",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],

                  // INTERESTS
                  if (interests.isNotEmpty) ...[
                    Text(
                      "Interests",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests
                          .map(
                            (i) => Chip(
                              label: Text(i.toString()),
                              backgroundColor: Colors.pink.shade50,
                              labelStyle: const TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 25),
                  ],

                  // Photos & Prompts
                  if (images.length > 1) _buildPhotoCard(images[1]),
                  if (prompts.isNotEmpty) _buildPromptCard(prompts[0]),
                  if (images.length > 2) _buildPhotoCard(images[2]),
                  if (prompts.length > 1) _buildPromptCard(prompts[1]),
                  if (images.length > 3)
                    ...images.sublist(3).map((img) => _buildPhotoCard(img)),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- 3. ACTION BUTTONS (LIKE/DISLIKE) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton.large(
              heroTag: "btn_dislike",
              backgroundColor: Colors.white,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.red, size: 40),
            ),
            FloatingActionButton.large(
              heroTag: "btn_like",
              backgroundColor: const Color(0xFFFD297B),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.favorite, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String url) {
    return Container(
      width: double.infinity,
      height: 400,
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheHeight: 1000,
          placeholder: (context, url) => Container(color: Colors.grey.shade200),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPromptCard(Map<String, dynamic> prompt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.pink.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt['question'] ?? "",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.pink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            prompt['answer'] ?? "",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
