import 'dart:ui'; // For ImageFilter (Ghost Mode)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final String matchId;

  const ChatScreen({super.key, required this.matchData, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late String chatId;

  @override
  void initState() {
    super.initState();
    List<String> ids = [currentUserId, widget.matchId];
    ids.sort();
    chatId = ids.join("_");
  }

  // --- 1. SEND TEXT MESSAGE ---
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String msg = _messageController.text.trim();
    _messageController.clear();

    await _postMessageToFirestore(msg, 'text');
  }

  // --- 2. SEND DATE INVITE ---
  void _sendDateInvite(String title, String icon) async {
    // We send a special type: 'invite'
    await _postMessageToFirestore(
      title,
      'invite',
      extraData: {'icon': icon, 'status': 'pending'},
    );
    if (mounted) Navigator.pop(context); // Close the menu
  }

  Future<void> _postMessageToFirestore(
    String content,
    String type, {
    Map<String, dynamic>? extraData,
  }) async {
    Map<String, dynamic> data = {
      'senderId': currentUserId,
      'text': content,
      'type': type, // 'text' or 'invite'
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (extraData != null) {
      data.addAll(extraData);
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(data);

    // Update last message for the list view
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'users': [currentUserId, widget.matchId],
      'lastMessage': type == 'invite' ? "📅 Date Invite sent!" : content,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- 3. SHOW DATE OPTIONS MENU ---
  void _showDateInvites() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ask for a Date! 💘",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Pick an idea to break the ice.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              _buildDateOption("Coffee at Canteen", "☕"),
              _buildDateOption("Study Session (Library)", "📚"),
              _buildDateOption("Walk in the Park", "🌳"),
              _buildDateOption("Grab a Quick Lunch", "🍔"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateOption(String title, String icon) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () => _sendDateInvite(title, icon),
    );
  }

  // --- 4. ACCEPT DATE LOGIC ---
  void _acceptDate(String messageId) {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': 'accepted'});

    // Optional: You could trigger a confetti animation here!
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("It's a Date! 🎉")));
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.matchData['name'] ?? "User";
    String photoUrl =
        (widget.matchData['imageUrls'] != null &&
            widget.matchData['imageUrls'].isNotEmpty)
        ? widget.matchData['imageUrls'][0]
        : "https://via.placeholder.com/150";

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- GHOST MODE REVEAL HEADER ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .snapshots(),
            builder: (context, snapshot) {
              int msgCount = 0;
              if (snapshot.hasData) msgCount = snapshot.data!.docs.length;
              double blurAmount = (20 - msgCount).clamp(0, 20).toDouble();
              double progress = (msgCount / 20).clamp(0.0, 1.0);

              return Container(
                padding: const EdgeInsets.all(10),
                color: Colors.purple.shade50,
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: blurAmount,
                            sigmaY: blurAmount,
                          ),
                          child: Image.network(photoUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (blurAmount > 0)
                            Text(
                              "Reveal Progress: $msgCount/20",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            )
                          else
                            const Text(
                              "PROFILE UNLOCKED! 🎉",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // --- MESSAGES LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    var doc = messages[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    String type = data['type'] ?? 'text';

                    if (type == 'invite') {
                      return _buildInviteCard(doc.id, data, isMe);
                    }

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.pink : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          data['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- INPUT AREA ---
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                // DATE INVITE BUTTON
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.pink),
                  onPressed: _showDateInvites,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SPECIAL WIDGET: THE INVITE CARD ---
  Widget _buildInviteCard(String docId, Map<String, dynamic> data, bool isMe) {
    String status = data['status'] ?? 'pending';
    bool isAccepted = status == 'accepted';

    return Align(
      alignment: Alignment.center, // Invites are centered
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isAccepted ? Colors.green.shade50 : Colors.pink.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isAccepted ? Colors.green : Colors.pink),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(data['icon'] ?? "📅", style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 10),
            Text(
              isMe
                  ? "You asked for a date:"
                  : "${widget.matchData['name']} asks:",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              data['text'],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            if (isAccepted)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Accepted! ✅",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (!isMe)
              // Only show ACCEPT button to the OTHER person
              ElevatedButton(
                onPressed: () => _acceptDate(docId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Let's go! 💖",
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              const Text(
                "Waiting for reply...",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
