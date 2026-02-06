import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_setup_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  final Color _accentColor = const Color(0xFFFD297B);
  final Color _textColor = const Color(0xFF111418);
  final Color _subTextColor = Colors.grey[600]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: _buildCircleBtn(
            Icons.arrow_back_ios_new,
            () => Navigator.pop(context),
          ),
        ),
        leadingWidth: 70,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildCircleBtn(
              Icons.settings,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? 'Your Name';
          final age = data?['age'] ?? '';
          final bio = data?['bio'] ?? 'Add a bio...';
          final campus = data?['campus'] ?? 'Select Campus';

          // NEW: LOAD LIST OF IMAGES
          List<String> imageUrls = [];
          if (data?['userImages'] != null) {
            imageUrls = List<String>.from(data!['userImages']);
          } else if (data?['imageUrl'] != null) {
            imageUrls.add(data!['imageUrl']);
          } else {
            imageUrls.add('https://via.placeholder.com/600x800');
          }

          return Stack(
            children: [
              // --- 1. CAROUSEL IMAGE BACKGROUND ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.65,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: imageUrls.length,
                  onPageChanged: (index) =>
                      setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: imageUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey[300]),
                    );
                  },
                ),
              ),

              // --- 2. IMAGE INDICATORS (STORY BARS) ---
              if (imageUrls.length > 1)
                Positioned(
                  top: 100, // Below the AppBar buttons
                  left: 20,
                  right: 20,
                  child: Row(
                    children: List.generate(imageUrls.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              // --- 3. GRADIENT SHADOW ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 150,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // --- 4. BOTTOM SHEET CONTENT ---
              Positioned.fill(
                top: MediaQuery.of(context).size.height * 0.58,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "$name, $age",
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school, color: _accentColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                campus,
                                style: GoogleFonts.inter(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Edit / Share Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileSetupScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text("Edit Profile"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _textColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {},
                                color: _textColor,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                        // Stats Row (Fake Data for Visuals)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                "Matches",
                                "12",
                                Icons.favorite,
                                Colors.redAccent,
                              ),
                              _buildVerticalDivider(),
                              _buildStatItem(
                                "Likes",
                                "142",
                                Icons.star,
                                Colors.amber,
                              ),
                              _buildVerticalDivider(),
                              _buildStatItem(
                                "Visits",
                                "380",
                                Icons.visibility,
                                Colors.blueAccent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        Text(
                          "About Me",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          bio,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: _subTextColor,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: _subTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() =>
      Container(height: 30, width: 1, color: Colors.grey[300]);
}
