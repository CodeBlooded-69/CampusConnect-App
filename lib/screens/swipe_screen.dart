import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/preferences_service.dart'; // Import service
import '../widgets/user_card.dart';
import 'profile_screen.dart';
import 'matches_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<String> cardUserIds = [];

  // FILTERS
  bool filterGlobal = true;
  double filterAgeMin = 18;
  double filterAgeMax = 99;
  String? myCampus;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  // Load saved settings AND current user's campus info
  Future<void> _loadFilters() async {
    final prefs = await PreferencesService().loadSettings();
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (mounted) {
      setState(() {
        filterGlobal = prefs['is_global'];
        filterAgeMin = prefs['age_min'];
        filterAgeMax = prefs['age_max'];
        myCampus = userDoc.data()?['campus'];
      });
    }
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction == CardSwiperDirection.right) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && previousIndex < cardUserIds.length) {
        final likedUserId = cardUserIds[previousIndex];
        _handleLike(currentUserId, likedUserId);
      }
    }
    return true;
  }

  Future<void> _handleLike(String myId, String theirId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(myId)
        .collection('swipes')
        .doc(theirId)
        .set({'type': 'like', 'timestamp': FieldValue.serverTimestamp()});

    final theirSwipe = await firestore
        .collection('users')
        .doc(theirId)
        .collection('swipes')
        .doc(myId)
        .get();

    if (theirSwipe.exists && theirSwipe.data()?['type'] == 'like') {
      if (mounted) _showMatchPopup();
      final matchId = myId.compareTo(theirId) < 0
          ? "${myId}_$theirId"
          : "${theirId}_$myId";
      await firestore.collection('matches').doc(matchId).set({
        'users': [myId, theirId],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showMatchPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.pink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "IT'S A MATCH! 😍",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        content: const Text(
          "You both liked each other!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Keep Swiping",
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.pink,
            ),
            child: const Text("Chat Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 30,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    const Text(
                      "🔥 CampusDate",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE94057),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.message_rounded,
                        color: Colors.grey,
                        size: 30,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MatchesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cards
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('uid', isNotEqualTo: currentUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No users found."));
                    }

                    // --- FILTERING LOGIC ---
                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final int userAge = data['age'] != null
                          ? int.tryParse(data['age'].toString()) ?? 0
                          : 0;
                      final String userCampus = data['campus'] ?? '';

                      // Filter by Age
                      if (userAge < filterAgeMin || userAge > filterAgeMax) {
                        return false;
                      }

                      // Filter by Campus (If Global is OFF)
                      if (!filterGlobal &&
                          myCampus != null &&
                          userCampus != myCampus) {
                        return false;
                      }

                      return true;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text("No matches fit your settings!"),
                      );
                    }

                    cardUserIds.clear();
                    List<UserCard> cards = filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      cardUserIds.add(data['uid']);
                      return UserCard(
                        name: data['name'] ?? 'Unknown',
                        age: (data['age'] ?? 0).toString(),
                        bio: data['bio'] ?? '',
                        campus: data['campus'] ?? 'Unknown',
                        imageUrl: data['imageUrl'] ?? '',
                      );
                    }).toList();

                    return CardSwiper(
                      controller: controller,
                      cardsCount: cards.length,
                      numberOfCardsDisplayed: 3,
                      backCardOffset: const Offset(0, 40),
                      padding: const EdgeInsets.all(20),
                      cardBuilder: (context, index, x, y) => cards[index],
                      onSwipe: _onSwipe,
                    );
                  },
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 60, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(
                      Icons.close_rounded,
                      Colors.red,
                      () => controller.swipe(CardSwiperDirection.left),
                    ),
                    _buildButton(
                      Icons.star_rounded,
                      Colors.blue,
                      () => controller.swipe(CardSwiperDirection.top),
                    ),
                    _buildButton(
                      Icons.favorite_rounded,
                      Colors.green,
                      () => controller.swipe(CardSwiperDirection.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 35),
        onPressed: onTap,
        padding: const EdgeInsets.all(15),
      ),
    );
  }
}
