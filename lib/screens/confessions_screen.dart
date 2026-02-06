import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfessionsScreen extends StatefulWidget {
  const ConfessionsScreen({super.key});

  @override
  State<ConfessionsScreen> createState() => _ConfessionsScreenState();
}

class _ConfessionsScreenState extends State<ConfessionsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  String? _myCampus;
  bool _filterByCampus = false; // Toggle state

  @override
  void initState() {
    super.initState();
    _loadUserCampus();
  }

  // Fetch the current user's campus so we know what to filter by
  Future<void> _loadUserCampus() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _myCampus = doc.data()?['campus'];
      });
    }
  }

  // --- POST A CONFESSION ---
  void _showPostDialog() {
    TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Post Anonymous Confession",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                "What's on your mind? (e.g., 'Who is the cute guy in the library?')",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () async {
              if (textController.text.trim().isEmpty) return;
              Navigator.pop(context);

              // 1. Get User Details
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .get();
              final userData = userDoc.data() as Map<String, dynamic>;

              String gender = userData['gender'] ?? 'Student';
              String major = userData['major'] ?? 'Unknown';
              String campus =
                  userData['campus'] ??
                  'Unknown Campus'; // Important for filtering

              // 2. Post to Firestore
              await FirebaseFirestore.instance.collection('confessions').add({
                'text': textController.text.trim(),
                'authorId': currentUser!.uid,
                'authorLabel': "$gender • $major", // Anonymous Label
                'campus': campus, // Store campus so we can filter later
                'timestamp': FieldValue.serverTimestamp(),
                'likes': [],
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Confession Posted!")),
              );
            },
            child: const Text("Post", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleLike(String docId, List likes) {
    final uid = currentUser!.uid;
    if (likes.contains(uid)) {
      FirebaseFirestore.instance.collection('confessions').doc(docId).update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      FirebaseFirestore.instance.collection('confessions').doc(docId).update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the query based on the filter
    Query query = FirebaseFirestore.instance
        .collection('confessions')
        .orderBy('timestamp', descending: true);

    if (_filterByCampus && _myCampus != null) {
      query = query.where('campus', isEqualTo: _myCampus);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: Text(
          "Campus Buzz 📢",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // --- FILTER TOGGLE ---
          if (_myCampus != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilterChip(
                label: Text(_filterByCampus ? "My Campus" : "All Campuses"),
                selected: _filterByCampus,
                onSelected: (bool value) {
                  setState(() {
                    _filterByCampus = value;
                  });
                },
                selectedColor: Colors.pink.shade100,
                checkmarkColor: Colors.pink,
                labelStyle: TextStyle(
                  color: _filterByCampus ? Colors.pink : Colors.black,
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostDialog,
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text("Confess", style: TextStyle(color: Colors.white)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // This handles the "Index Required" error automatically
            return Center(
              child: Text("Create Index via Console link: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    _filterByCampus
                        ? "No posts from $_myCampus yet."
                        : "No confessions yet.",
                    style: GoogleFonts.inter(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Be the first to post!",
                    style: GoogleFonts.inter(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final likes = List<String>.from(data['likes'] ?? []);
              final isLiked = likes.contains(currentUser!.uid);
              final postCampus = data['campus'] ?? 'Unknown Campus';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Campus Name
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.pink.shade50,
                            child: const Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.pink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['authorLabel'] ?? "Anonymous",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                postCampus,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      Text(
                        data['text'],
                        style: GoogleFonts.inter(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 15),
                      const Divider(),

                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _toggleLike(doc.id, likes),
                          ),
                          Text(
                            "${likes.length}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Reply",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
