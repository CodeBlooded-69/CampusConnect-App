import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_detail_screen.dart'; // To view their profile

class LikedMeScreen extends StatelessWidget {
  const LikedMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Who Liked Me",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. LISTEN TO MY 'LIKES' SUBCOLLECTION
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('likes')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No likes yet.",
                    style: GoogleFonts.inter(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Keep your profile updated!",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          var likeDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              childAspectRatio: 0.75, // Tall cards
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: likeDocs.length,
            itemBuilder: (context, index) {
              // The Document ID is the User ID of the person who liked me
              String likerId = likeDocs[index].id;

              // 2. FETCH THE USER DETAILS FOR EACH ID
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(likerId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData)
                    return Container(color: Colors.grey.shade200);

                  var data = userSnapshot.data!.data() as Map<String, dynamic>;
                  String image =
                      (data['imageUrls'] != null &&
                          data['imageUrls'].isNotEmpty)
                      ? data['imageUrls'][0]
                      : 'https://via.placeholder.com/200';

                  return GestureDetector(
                    onTap: () {
                      // Open their profile so you can Like/Match them back
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileDetailScreen(userData: data),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [Colors.transparent, Colors.black87],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Name & Gold Badge
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "LIKES YOU",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  data['name'] ?? "User",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
