import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'quiz_screen.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// --- COMPRESS FUNCTION ---
Future<File> testCompressAndGetFile(File file, String targetPath) async {
  var result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 70,
    minWidth: 1080,
    minHeight: 1080,
  );
  if (result == null) return file;
  return File(result.path);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isUploading = false;

  final String imgbbApiKey = "9d1f20d60ce3987573f040dd78b7bd7e";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _campusController =
      TextEditingController(); // NEW: For displaying selected campus

  final List<TextEditingController> _photoControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<String> _genderList = ["Male", "Female", "Other"];
  String? _selectedGender;

  final List<String> _allInterests = [
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
    "Photographers",
    "Techies",
    "Anime Fans",
    "Fitness",
    "Designers",
    "Entrepreneurs",
  ];
  List<String> _selectedInterests = [];

  final List<String> _availablePrompts = [
    "My simple pleasure is...",
    "I'm convinced that...",
    "The best way to win me over is...",
    "Two truths and a lie...",
    "I geek out on...",
    "My most controversial opinion is...",
    "Dating me is like...",
    "Change my mind about...",
  ];
  String? _selectedPrompt1;
  final TextEditingController _answer1Controller = TextEditingController();
  String? _selectedPrompt2;
  final TextEditingController _answer2Controller = TextEditingController();

  // --- FULL COLLEGE LIST ---
  final List<String> _collegeList = [
    "Acharya Institute of Technology",
    "A.C.S. College of Engineering",
    "Adichunchanagiri Institute Of Technology",
    "Akash Institute of Engineering and Technology",
    "Alva's Institute of Engineering & Technology",
    "AMC Engineering College",
    "Angadi Institute of Technology and Management",
    "APS College of Engineering",
    "Atria Institute of Technology",
    "Akshaya Institute of Technology",
    "Anuvartik Mirji Bharatesh Institute of Technology",
    "B.N.M. Institute of Technology",
    "KLE Technological University (BVBCET)",
    "Ballari Institute of Technology & Management",
    "Bangalore Institute of Technology",
    "Bangalore Technological Institute",
    "Bapuji Institute of Engineering & Technology",
    "Basavakalyan Engineering College",
    "Basaveshwar Engineering College",
    "BLDEA's V.P. Dr. P.G. Halakatti College of Engg & Tech",
    "BMS College of Engineering",
    "BMS Institute of Technology & Management",
    "Brindavan College of Engineering",
    "C.M.R. Institute of Technology",
    "Cambridge Institute of Technology",
    "Channabasaveshwara Institute of Technology",
    "Chanakya University",
    "City Engineering College",
    "Coorg Institute of Technology",
    "Dayananda Sagar Academy of Technology & Management",
    "Dayananda Sagar College of Engineering",
    "DON BOSCO Institute of Technology",
    "Dr. Ambedkar Institute of Technology",
    "Yenepoya Institute of Technology",
    "Dr.Shri Shri Shivakumara Mahaswamy College of Engg",
    "Dr H N National College Of Engineering",
    "East Point College of Engineering and Technology",
    "East West Institute of Technology",
    "Garden City University",
    "Global Academy of Technology",
    "GM Institute of Technology",
    "Gopalan College of Engineering And Management",
    "GSSS Institute of Engineering and Technology for Women",
    "H.K.E.Society's P.D.A. College of Engineering",
    "Sri Jayachamarajendra College of Engineering (SJCE)",
    "Jawaharlal Nehru New College of Engineering (JNNCE)",
    "JSS Academy of Technical Education",
    "JSS Science & Technology University",
    "Jain College of Engineering",
    "Jnana Vikas Institute of Technology",
    "Jain College Of Engineering & Research",
    "KLE Technological University (Belagavi)",
    "KLE College of Engineering and Technology",
    "K.S School of Engineering And Management",
    "K.S. Institute of Technology",
    "KVG College Of Engineering",
    "Kalpataru Institute of Technology",
    "Karavali Institute of Technology",
    "KLS Gogte Institute of Technology",
    "KLS's Vishwanathrao Deshpande Institute of Technology",
    "K. N. S. INSTITUTE OF TECHNOLOGY",
    "M.S. Engineering College",
    "M.S. Ramaiah Institute of Technology",
    "Maharaja Institute of Technology (Mandya)",
    "Malnad College of Engineering",
    "Mangalore Institute of Technology & Engineering",
    "Moodalakatte Institute of Technology",
    "Maharaja Institute of Technology (Mysuru)",
    "Mysuru Royal Institute of Technology",
    "Nagarjuna College of Engineering & Technology",
    "The National Institute of Engineering (North)",
    "Navodaya Institute of Technology",
    "P.E.S.College of Engineering",
    "PES Institute of Technology & Management",
    "Proudhadevaraya Institute of Technology",
    "R V College of Engineering",
    "R.L. Jalappa Institute of Technology",
    "R.R. Institute of Technology",
    "R.T.E. Society's Rural Engineering College",
    "Raja Rajeswari College of Engineering",
    "Rajeev Institute of Technology",
    "Rajiv Gandhi Institute of Technology",
    "Rao Bahadur Y Mahabaleswarappa Engineering College",
    "RNS Institute of Technology",
    "Bheemanna Khandre Institute of Technology",
    "SJB Institute of Technology",
    "S J C Institute of Technology",
    "S.E.A. College of Engineering & Technology",
    "SSET's S.G. Balekundri Institute of Technology",
    "Hirasugar Institute of Technology",
    "Sahyadri College of Engineering and Management",
    "Sai Vidya Institute of Technology",
    "Sambhram Institute of Technology",
    "SAPTHAGIRI NPS UNIVERSITY",
    "SDM College of Engineering & Technology",
    "SDM Institute of Technology",
    "SECAB Institute of Engineering &Technology",
    "Sri Sairam College of Engineering",
    "Shree Devi Institute of Technology",
    "Shri Madhwa Vadiraja Institute of Tech & Mgmt",
    "Shridevi Institute of Engineering & Technology",
    "Siddaganga Institute of Technology",
    "Sir M.Visvesvaraya Institute of Technology",
    "S J M Institute of Technology",
    "Smt. Kamala and Sri Venkappa M. Agadi College of Engg",
    "Sri Krishna Institute of Technology",
    "Sri Taralabalu Jagadguru Institute of Technology",
    "Sri Venkateshwara College of Engineering",
    "Srinivas Institute of Technology",
    "T. John Institute of Technology",
    "The National Institute of Engineering (South)",
    "Tontadarya College of Engineering",
    "Veerappa Nisty Engineering College",
    "Vemana Institute of Technology",
    "Vidya Vikas Institute of Engineering & Technology",
    "Vidyavardhaka College of Engineering",
    "Vivekananda College of Engineering and Technology",
    "ATME College of Engineering",
    "Jyothy Institute of Technology",
    "Shetty Institute of Technology",
    "Lingaraj Appa Engineering",
    "Cambridge Institute of Technology (North)",
    "Reva University",
    "Alliance College of Engineering & Design",
    "GITAM (Deemed to be University)",
    "Mysore College of Engineering and Management",
    "Presidency University",
    "Jain Institute of Technology",
    "CMR University",
    "Sir M V School Of Architecture",
    "Jain College of Engineering and Technology",
    "Navkis College of Engineering",
    "M.S. Ramaiah University of Applied Sciences",
    "R V Institute of Technology and Management",
    "Biluru Gurubasava Mahaswamiji Institute of Technology",
    "G Madegowda Institute of Technology",
    "C Byregowda Institute of Technology",
    "Amruta Institute of Engineering and Management Science",
    "H.K.E. Society's Sir M. Visvesvaraya College of Engg",
    "Vijaya Vittala Institution of Technology",
    "Cauvery Institute Of Technology",
    "BGS College of Engineering and Technology",
    "A.G.M Rural College of Engineering and Technology",
    "Aditya College of Engineering and Technology",
    "East West College of Engineering",
    "Seshadripuram Institute of Technology",
    "Sri Siddhartha School of Engineering",
    "Cauvery College of Engineering",
    "New Ebenezer Institute of Technology",
    "Harsha Institute of Technology",
    "IISc Bangalore",
    "IIIT Bangalore",
    "IIT Bombay",
    "IIT Delhi",
    "IIT Madras",
    "BITS Pilani",
    "VIT Vellore",
    "Manipal Institute of Technology",
    "Siksha 'O' Anusandhan",
    "Bangalore Medical College and Research Institute",
    "Kalinga Institute of Medical Sciences"
        "Other",
  ];

  String? _selectedCampus;

  @override
  void initState() {
    super.initState();
    // Sort logic
    _collegeList.sort((a, b) {
      if (a == "Other") return 1;
      if (b == "Other") return -1;
      return a.compareTo(b);
    });
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['name'] ?? '';
          _majorController.text = data['major'] ?? '';
          _bioController.text = data['bio'] ?? '';

          if (_genderList.contains(data['gender']))
            _selectedGender = data['gender'];

          String loadedCampus = data['campus'] ?? '';
          if (_collegeList.contains(loadedCampus)) {
            _selectedCampus = loadedCampus;
            _campusController.text = loadedCampus;
          } else if (loadedCampus.isNotEmpty) {
            _collegeList.insert(0, loadedCampus);
            _selectedCampus = loadedCampus;
            _campusController.text = loadedCampus;
          }

          List<dynamic> existingPhotos = data['imageUrls'] ?? [];
          for (int i = 0; i < existingPhotos.length; i++) {
            if (i < 6) _photoControllers[i].text = existingPhotos[i].toString();
          }

          if (data['interests'] != null) {
            _selectedInterests = List<String>.from(data['interests']);
          }

          List<dynamic> prompts = data['prompts'] ?? [];
          if (prompts.isNotEmpty) {
            _selectedPrompt1 = prompts[0]['question'];
            _answer1Controller.text = prompts[0]['answer'];
          }
          if (prompts.length > 1) {
            _selectedPrompt2 = prompts[1]['question'];
            _answer2Controller.text = prompts[1]['answer'];
          }
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      Uint8List imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var url = Uri.parse("https://api.imgbb.com/1/upload");
      var response = await http.post(
        url,
        body: {"key": imgbbApiKey, "image": base64Image},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String uploadedUrl = jsonResponse['data']['url'];

        setState(() {
          _photoControllers[index].text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Photo added!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _photoControllers[index].clear();
    });
  }

  // --- 🚀 NEW: SEARCHABLE CAMPUS PICKER ---
  void _showCampusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full height
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    children: [
                      // Handle Bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Search your college...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                        ),
                        onChanged: (query) {
                          setModalState(() {}); // Rebuild list locally
                        },
                      ),
                      const SizedBox(height: 20),

                      // List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _collegeList.length,
                          itemBuilder: (context, index) {
                            final collegeName = _collegeList[index];

                            // Simple Search Filter
                            // If search is empty OR college matches search query
                            // We use a static variable inside this scope isn't ideal,
                            // but accessing the TextField value is trickier without a controller.
                            // Better approach: Filtering logic inside builder.

                            // Let's assume we filter based on text field value?
                            // Actually, let's just make the list filtered inside the builder.
                            // Since we can't easily access the text value without a controller:
                            // We will use a controller for the search bar!
                            return _buildCollegeListItem(
                              collegeName,
                              scrollController,
                              context,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper for cleaner Search Logic
  // We need to re-implement the Search Picker to properly filter
  // The method above was a bit simplistic. Here is the ROBUST version.
  void _openSearchableCampusSheet() {
    TextEditingController searchController = TextEditingController();
    List<String> filteredList = List.from(_collegeList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Search College...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFFD297B),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (query) {
                        // We need to update the UI of the Modal, not the main screen
                        // So we can't use standard setState.
                        // But since we are inside a builder, we need a StatefulBuilder.
                        // However, to keep it simple, we will just use this pattern:
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setStateModal) {
                        // Update filter logic
                        searchController.addListener(() {
                          if (searchController.text.isEmpty) {
                            if (filteredList.length != _collegeList.length) {
                              setStateModal(
                                () => filteredList = List.from(_collegeList),
                              );
                            }
                          } else {
                            setStateModal(() {
                              filteredList = _collegeList
                                  .where(
                                    (c) => c.toLowerCase().contains(
                                      searchController.text.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                            });
                          }
                        });

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredList.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final college = filteredList[index];
                            final isSelected = college == _selectedCampus;

                            return ListTile(
                              title: Text(
                                college,
                                style: GoogleFonts.inter(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFFFD297B)
                                      : Colors.black87,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFFFD297B),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedCampus = college;
                                  _campusController.text = college;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Placeholder for simple builder (not used in favor of _openSearchableCampusSheet)
  Widget _buildCollegeListItem(
    String name,
    ScrollController sc,
    BuildContext ctx,
  ) {
    return Container();
  }

  Future<void> _saveProfile() async {
    if (_selectedCampus == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Gender and Campus"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> newPhotos = [];
    for (var controller in _photoControllers) {
      if (controller.text.trim().isNotEmpty)
        newPhotos.add(controller.text.trim());
    }

    List<Map<String, String>> promptsToSave = [];
    if (_selectedPrompt1 != null && _answer1Controller.text.isNotEmpty) {
      promptsToSave.add({
        'question': _selectedPrompt1!,
        'answer': _answer1Controller.text.trim(),
      });
    }
    if (_selectedPrompt2 != null && _answer2Controller.text.isNotEmpty) {
      promptsToSave.add({
        'question': _selectedPrompt2!,
        'answer': _answer2Controller.text.trim(),
      });
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'campus': _selectedCampus,
      'major': _majorController.text.trim(),
      'bio': _bioController.text.trim(),
      'imageUrls': newPhotos,
      'prompts': promptsToSave,
      'interests': _selectedInterests,
      'isProfileComplete': true,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFD297B)),
        ),
      );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD297B),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Profile Photos"),
                const SizedBox(height: 10),
                _buildPhotoGrid(),
                const SizedBox(height: 25),

                _buildSectionTitle("The Basics"),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _buildModernTextField(
                        "Full Name",
                        _nameController,
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 15),
                      _buildModernDropdown(
                        "Gender",
                        _genderList,
                        _selectedGender,
                        (v) => setState(() => _selectedGender = v),
                      ),
                      const SizedBox(height: 15),

                      // 🚀 MODIFIED: Campus Picker Trigger
                      GestureDetector(
                        onTap: _openSearchableCampusSheet,
                        child: AbsorbPointer(
                          // Prevents keyboard from opening
                          child: TextFormField(
                            controller: _campusController,
                            decoration: InputDecoration(
                              labelText: "Campus",
                              prefixIcon: const Icon(
                                Icons.school_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      _buildModernTextField(
                        "Major",
                        _majorController,
                        Icons.school_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("About Me"),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write a short bio about yourself...",
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(15),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFD297B)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Quiz Section
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFD297B), Color(0xFFFF655B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFD297B).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Compatibility Quiz",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Answer 5 questions to improve matching",
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("My Interests"),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _allInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: FilterChip(
                          label: Text(interest),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          selected: isSelected,
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFFFD297B),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("Conversation Starters"),
                const SizedBox(height: 10),
                _buildPromptCard(
                  1,
                  _selectedPrompt1,
                  _answer1Controller,
                  (v) => setState(() => _selectedPrompt1 = v),
                ),
                const SizedBox(height: 15),
                _buildPromptCard(
                  2,
                  _selectedPrompt2,
                  _answer2Controller,
                  (v) => setState(() => _selectedPrompt2 = v),
                ),
              ],
            ),
          ),

          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFD297B)),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        String url = _photoControllers[index].text;
        bool hasImage = url.isNotEmpty;

        return GestureDetector(
          onTap: () => hasImage ? null : _pickAndUploadImage(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? Colors.transparent : Colors.grey.shade300,
                width: 2,
              ),
              image: hasImage
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(url),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (!hasImage)
                  Center(
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                if (hasImage)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                if (hasImage)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFD297B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildModernDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPromptCard(
    int index,
    String? selectedPrompt,
    TextEditingController controller,
    Function(String?) onPromptChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFD297B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Prompt $index",
                  style: const TextStyle(
                    color: Color(0xFFFD297B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPrompt,
              isExpanded: true,
              hint: const Text("Select a question..."),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _availablePrompts
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onPromptChanged,
            ),
          ),
          const Divider(),
          TextField(
            controller: controller,
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: "Type your answer here...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
