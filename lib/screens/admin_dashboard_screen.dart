import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- LOGIC: DELETE USER ---
  Future<void> _deleteUser(String userId) async {
    // 1. Delete their user profile
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    // 2. (Optional) You could also flag them as 'banned' if you don't want them re-joining
  }

  // --- LOGIC: DELETE POST ---
  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance
        .collection('confessions')
        .doc(postId)
        .delete();
  }

  // --- LOGIC: EDIT POST ---
  void _editPost(DocumentSnapshot doc) {
    TextEditingController _editController = TextEditingController(
      text: doc['message'],
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Post"),
        content: TextField(
          controller: _editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('confessions')
                  .doc(doc.id)
                  .update({'message': _editController.text.trim()});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard 🛡️"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Users"),
            Tab(icon: Icon(Icons.message), text: "Posts/Buzz"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: USER MANAGEMENT ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final docId = users[index].id;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          (data['imageUrls'] != null &&
                                  data['imageUrls'].isNotEmpty)
                              ? data['imageUrls'][0]
                              : 'https://via.placeholder.com/150',
                        ),
                      ),
                      title: Text(data['name'] ?? "Unknown"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📧 ${data['email'] ?? 'No Email'}",
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          Text(
                            "ID: $docId",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text("Delete User?"),
                            content: const Text(
                              "This will remove their profile data permanently.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteUser(docId);
                                  Navigator.pop(c);
                                },
                                child: const Text(
                                  "DELETE",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // --- TAB 2: POST MONITORING ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('confessions')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final posts = snapshot.data!.docs;

              return ListView.builder(
                itemCount: posts.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final data = post.data() as Map<String, dynamic>;

                  return Card(
                    color: Colors.grey[100],
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        data['message'] ?? "",
                        style: GoogleFonts.inter(),
                      ),
                      subtitle: Text(
                        data['hashtags'] ?? "",
                        style: const TextStyle(color: Colors.pink),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editPost(post),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePost(post.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
