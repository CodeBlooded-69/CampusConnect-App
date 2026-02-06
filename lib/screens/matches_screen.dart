import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart'; // Ensure this file exists

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Matches",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Listen for matches where YOU are one of the users
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No matches yet. Keep swiping!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final matchDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matchDocs.length,
            itemBuilder: (context, index) {
              final matchData = matchDocs[index].data() as Map<String, dynamic>;
              final users = List<String>.from(matchData['users']);

              // Logic: Find the ID that is NOT mine
              final otherUserId = users.firstWhere((id) => id != currentUserId);

              // 2. Fetch the OTHER user's profile details
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  // Handle Image (Database uses 'imageUrls' list)
                  String imageUrl = 'https://via.placeholder.com/150';
                  if (userData['imageUrls'] != null &&
                      (userData['imageUrls'] as List).isNotEmpty) {
                    imageUrl = userData['imageUrls'][0];
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    title: Text(
                      userData['name'] ?? "Unknown",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text("New Match! Say hello 👋"),
                    trailing: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.pink,
                    ),
                    onTap: () {
                      // Navigate to Chat Screen with CORRECT parameters
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            matchData: userData, // Pass the full profile map
                            matchId:
                                otherUserId, // Pass the User UID (not the match doc ID)
                          ),
                        ),
                      );
                    },
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
