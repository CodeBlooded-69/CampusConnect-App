import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'chat_screen.dart'; // We will update this next

class GhostModeScreen extends StatefulWidget {
  const GhostModeScreen({super.key});

  @override
  State<GhostModeScreen> createState() => _GhostModeScreenState();
}

class _GhostModeScreenState extends State<GhostModeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // --- GHOST SWIPE LOGIC ---
  Future<void> _handleGhostSwipe(
    Map<String, dynamic> targetUser,
    String targetUserId,
  ) async {
    final myId = currentUser!.uid;
    // We save to a specific 'ghost_likes' collection to keep it separate from normal likes
    // Or you can use the normal 'likes' and just mark it as 'type: ghost'
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('likes')
        .doc(myId)
        .set({
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'ghost', // Mark as ghost match
        });

    // Check for match (simplified for demo)
    _createMatchInDatabase(myId, targetUserId);
  }

  Future<void> _createMatchInDatabase(String myId, String theirId) async {
    final matchQuery = await FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: myId)
        .get();
    bool exists = matchQuery.docs.any(
      (doc) => (doc['users'] as List).contains(theirId),
    );

    if (!exists) {
      await FirebaseFirestore.instance.collection('matches').add({
        'users': [myId, theirId],
        'isGhostMatch': true, // IMPORTANT flag
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': "👻 Ghost Match! Start chatting to reveal...",
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ghost Match! Check your chats.")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme for Ghost Mode
      appBar: AppBar(
        title: Text(
          "Ghost Mode 👻",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isProfileComplete', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );

          final users =
              snapshot.data?.docs
                  .where((doc) => doc.id != currentUser?.uid)
                  .toList() ??
              [];

          if (users.isEmpty)
            return const Center(
              child: Text(
                "No ghosts found...",
                style: TextStyle(color: Colors.white),
              ),
            );

          return Column(
            children: [
              Expanded(
                child: CardSwiper(
                  controller: _controller,
                  cardsCount: users.length,
                  numberOfCardsDisplayed: 2,
                  onSwipe: (prev, curr, dir) {
                    if (dir == CardSwiperDirection.right) {
                      _handleGhostSwipe(
                        users[prev].data() as Map<String, dynamic>,
                        users[prev].id,
                      );
                    }
                    return true;
                  },
                  cardBuilder: (context, index, h, v) {
                    final data = users[index].data() as Map<String, dynamic>;
                    String image =
                        (data['imageUrls'] != null &&
                            data['imageUrls'].isNotEmpty)
                        ? data['imageUrls'][0]
                        : 'https://via.placeholder.com/400';
                    String bio = data['bio'] ?? "No bio provided.";
                    List interests = data['interests'] ?? [];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.5),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. BLURRED IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 15,
                                sigmaY: 15,
                              ), // HEAVY BLUR
                              child: Image.network(image, fit: BoxFit.cover),
                            ),
                          ),

                          // 2. INFO OVERLAY (Clear)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Colors.transparent, Colors.black],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Only show Gender/Major, not Name initially? Or show Name.
                                Text(
                                  data['major'] ?? "Student",
                                  style: GoogleFonts.inter(
                                    color: Colors.purpleAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  bio,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 5,
                                  children: interests
                                      .map(
                                        (i) => Chip(
                                          label: Text(
                                            i,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Swipe Right based on personality!",
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
