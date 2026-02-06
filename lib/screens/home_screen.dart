import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';

// --- IMPORTS ---
import 'chat_screen.dart';
import 'profile_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'matches_screen.dart';
import 'liked_me_screen.dart';
import 'confessions_screen.dart';
import 'ghost_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- THE 4 MAIN TABS ---
  static final List<Widget> _widgetOptions = <Widget>[
    const SwipeTab(), // 0: Swipe
    const ExploreTab(), // 1: Explore
    const ConfessionsScreen(), // 2: Buzz
    const ProfileTab(), // 3: Profile
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "CampusConnect",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // 1. Who Liked Me Button
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.pink,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LikedMeScreen()),
              );
            },
          ),
          // 2. Chat / Matches Button
          IconButton(
            icon: const Icon(Icons.forum_rounded, color: Colors.pink, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MatchesScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Required for 4+ items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Swipe'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Explore',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Buzz'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        backgroundColor: bgColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// ==========================================
// TAB 1: SWIPE (HERO + HAPTIC + CACHED)
// ==========================================
class SwipeTab extends StatefulWidget {
  const SwipeTab({super.key});

  @override
  State<SwipeTab> createState() => _SwipeTabState();
}

class _SwipeTabState extends State<SwipeTab> {
  final CardSwiperController _controller = CardSwiperController();
  final currentUser = FirebaseAuth.instance.currentUser;

  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
  }

  Future<void> _handleRightSwipe(
    Map<String, dynamic> targetUser,
    String targetUserId,
  ) async {
    // 📳 INTERACTIVE: Vibrate on Like
    HapticFeedback.mediumImpact();

    final myId = currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('likes')
          .doc(myId)
          .set({'timestamp': FieldValue.serverTimestamp()});

      final likeCheck = await FirebaseFirestore.instance
          .collection('users')
          .doc(myId)
          .collection('likes')
          .doc(targetUserId)
          .get();
      if (likeCheck.exists) {
        _createMatchInDatabase(myId, targetUserId);
        _showMatchDialog(targetUser, targetUserId);
      }
    } catch (e) {
      print("Error swiping: $e");
    }
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
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': "New Match! Say Hi.",
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showMatchDialog(Map<String, dynamic> userData, String targetUserId) {
    // 📳 INTERACTIVE: Heavy vibration for match!
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String matchImage =
            (userData['imageUrls'] != null && userData['imageUrls'].isNotEmpty)
            ? userData['imageUrls'][0]
            : 'https://via.placeholder.com/150';

        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Stack(
            alignment: Alignment.center,
            children: [
              // 1. The Match Card
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFD297B), Color(0xFFFF655B)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "IT'S A MATCH!",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: CachedNetworkImageProvider(matchImage),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Text(
                      "You and ${userData['name']} dig each other!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                matchData: userData,
                                matchId: targetUserId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.chat_bubble,
                          color: Color(0xFFFD297B),
                        ),
                        label: const Text(
                          "Say Hello",
                          style: TextStyle(
                            color: Color(0xFFFD297B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Keep Swiping",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. ✨ INTERACTIVE: Lottie Confetti Animation
              IgnorePointer(
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json', // Confetti JSON
                  repeat: false,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, mySnapshot) {
        if (!mySnapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          );

        Map<String, dynamic> myData =
            mySnapshot.data!.data() as Map<String, dynamic>;
        String myGender = myData['gender'] ?? 'Other';
        String? targetGender;
        if (myGender == 'Male')
          targetGender = 'Female';
        else if (myGender == 'Female')
          targetGender = 'Male';

        Query query = FirebaseFirestore.instance
            .collection('users')
            .where('isProfileComplete', isEqualTo: true);
        if (targetGender != null)
          query = query.where('gender', isEqualTo: targetGender);

        return StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              );
            final users =
                snapshot.data?.docs
                    .where((doc) => doc.id != currentUser?.uid)
                    .toList() ??
                [];

            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      "No profiles found!",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      targetGender != null
                          ? "Showing only: $targetGender"
                          : "No users yet.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: users.length,
                    numberOfCardsDisplayed: users.length == 1 ? 1 : 2,
                    allowedSwipeDirection: const AllowedSwipeDirection.all(),
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final userDoc = users[previousIndex];
                      if (direction == CardSwiperDirection.right)
                        _handleRightSwipe(
                          userDoc.data() as Map<String, dynamic>,
                          userDoc.id,
                        );
                      if (direction == CardSwiperDirection.left)
                        HapticFeedback.lightImpact();
                      return true;
                    },
                    cardBuilder: (context, index, h, v) {
                      final data = users[index].data() as Map<String, dynamic>;
                      final userId =
                          users[index].id; // Gets Doc ID for Hero Tag
                      String image =
                          (data['imageUrls'] != null &&
                              data['imageUrls'].isNotEmpty)
                          ? data['imageUrls'][0]
                          : 'https://via.placeholder.com/400';

                      return GestureDetector(
                        onTap: () {
                          // PASS USER ID HERE
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileDetailScreen(
                                userData: data,
                                userId: userId,
                              ),
                            ),
                          );
                        },
                        // --- HERO ANIMATION START ---
                        child: Hero(
                          tag: userId, // Match this tag in Detail Screen
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    image,
                                    maxWidth: 800,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(20),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black87,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? 'Unknown',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      data['campus'] ?? 'Unknown Campus',
                                      style: GoogleFonts.inter(
                                        color: Colors.pinkAccent,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          data['major'] ?? 'Student',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          "Tap for info",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // --- HERO ANIMATION END ---
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 40,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.close, Colors.red, () {
                        _controller.swipe(CardSwiperDirection.left);
                        HapticFeedback.lightImpact();
                      }),
                      _buildActionButton(Icons.favorite, Colors.green, () {
                        _controller.swipe(CardSwiperDirection.right);
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

// ==========================================
// TAB 2: EXPLORE (HERO + OPTIMIZED)
// ==========================================
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  final List<String> interests = const [
    "Gamers",
    "Coders",
    "Artists",
    "Athletes",
    "Musicians",
    "Foodies",
    "Movie Buffs",
    "Bookworms",
    "Travelers",
    "Dancers",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Discover",
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // --- GHOST MODE BUTTON ---
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GhostModeScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_off,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Enter Ghost Mode 👻",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Blind date based on personality.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),
          Text(
            "Categories",
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCategoryCard(context, "Men", Icons.male, Colors.blue),
              const SizedBox(width: 15),
              _buildCategoryCard(context, "Women", Icons.female, Colors.pink),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            "Interests",
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: interests.length,
              itemBuilder: (context, index) {
                return _buildInterestCard(context, interests[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryListScreen(
                title: title,
                filterType: 'gender',
                filterValue: title == "Men" ? "Male" : "Female",
              ),
            ),
          );
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 5),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestCard(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryListScreen(
              title: title,
              filterType: 'interest',
              filterValue: title,
            ),
          ),
        );
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.pink.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.pink.shade100),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.pink,
          ),
        ),
      ),
    );
  }
}

// --- CATEGORY LIST SCREEN (HERO + OPTIMIZED) ---
class CategoryListScreen extends StatelessWidget {
  final String title;
  final String filterType;
  final String filterValue;

  const CategoryListScreen({
    super.key,
    required this.title,
    required this.filterType,
    required this.filterValue,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('isProfileComplete', isEqualTo: true);

    if (filterType == 'gender') {
      query = query.where('gender', isEqualTo: filterValue);
    } else if (filterType == 'interest') {
      query = query.where('interests', arrayContains: filterValue);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser?.uid)
              .toList();
          if (users.isEmpty)
            return const Center(child: Text("No users found here."));

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              String image =
                  (data['imageUrls'] != null && data['imageUrls'].isNotEmpty)
                  ? data['imageUrls'][0]
                  : 'https://via.placeholder.com/200';

              return GestureDetector(
                onTap: () {
                  // PASS USER ID HERE
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileDetailScreen(
                        userData: data,
                        userId: users[index].id,
                      ),
                    ),
                  );
                },
                // --- HERO ANIMATION START ---
                child: Hero(
                  tag: users[index].id,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            image,
                            maxWidth: 400,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [Colors.transparent, Colors.black54],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Text(
                          data['name'] ?? "User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // --- HERO ANIMATION END ---
              );
            },
          );
        },
      ),
    );
  }
}

// --- PROFILE TAB (OPTIMIZED) ---
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not Logged In"));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String name = data['name'] ?? "User";
        String image =
            (data['imageUrls'] != null && data['imageUrls'].isNotEmpty)
            ? data['imageUrls'][0]
            : 'https://via.placeholder.com/150';
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                // 🚀 OPTIMIZATION
                backgroundImage: CachedNetworkImageProvider(image),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.pink),
              title: const Text("Edit Profile"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text("Settings"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        );
      },
    );
  }
}
