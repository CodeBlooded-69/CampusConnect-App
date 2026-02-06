import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'quiz_screen.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// 2. USE THIS FIXED FUNCTION
Future<File> testCompressAndGetFile(File file, String targetPath) async {
  var result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 70,
    minWidth: 1080,
    minHeight: 1080,
  );

  // Safety Check: If compression fails, return the original file
  if (result == null) {
    return file;
  }

  // Convert XFile (from library) back to File (for Firebase)
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

  // ⚠️ PASTE YOUR API KEY HERE
  final String imgbbApiKey = "9d1f20d60ce3987573f040dd78b7bd7e";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final List<TextEditingController> _photoControllers = List.generate(
    5,
    (index) => TextEditingController(),
  );

  final List<String> _genderList = ["Male", "Female", "Other"];
  String? _selectedGender;

  // --- INTERESTS DATA ---
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
  ];
  List<String> _selectedInterests = [];

  // --- PROMPT DATA ---
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
    "Other",
  ];
  String? _selectedCampus;

  @override
  void initState() {
    super.initState();
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
          if (_collegeList.contains(loadedCampus))
            _selectedCampus = loadedCampus;
          else if (loadedCampus.isNotEmpty) {
            _collegeList.insert(0, loadedCampus);
            _selectedCampus = loadedCampus;
          }

          List<dynamic> existingPhotos = data['imageUrls'] ?? [];
          for (int i = 0; i < existingPhotos.length; i++) {
            if (i < 5) _photoControllers[i].text = existingPhotos[i].toString();
          }

          // LOAD INTERESTS
          if (data['interests'] != null) {
            _selectedInterests = List<String>.from(data['interests']);
          }

          // LOAD PROMPTS
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading...")));

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Upload Successful!")));
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedCampus == null || _selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Missing Required Fields")));
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
      'interests': _selectedInterests, // <--- SAVING INTERESTS
      'isProfileComplete': true,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
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
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.pink),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Basic Info",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            _buildTextField("Full Name", _nameController),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _selectedGender,
              items: _genderList
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v),
              decoration: const InputDecoration(
                labelText: "Gender",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _selectedCampus,
              isExpanded: true,
              hint: const Text("Select Campus"),
              items: _collegeList
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCampus = v),
              decoration: const InputDecoration(
                labelText: "Campus",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            _buildTextField("Major", _majorController),
            const SizedBox(height: 15),
            _buildTextField("Bio", _bioController, maxLines: 3),

            const SizedBox(height: 30),

            // --- INTERESTS SECTION ---
            Text(
              "Interests",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Select tags that describe you.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _allInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  selectedColor: Colors.pink.shade100,
                  checkmarkColor: Colors.pink,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.pink : Colors.black,
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
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // --- CONVERSATION STARTERS ---
            Text(
              "Conversation Starters",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedPrompt1,
              isExpanded: true,
              hint: const Text("Select Prompt 1"),
              items: _availablePrompts
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedPrompt1 = v),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 5),
            _buildTextField("Your Answer...", _answer1Controller),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedPrompt2,
              isExpanded: true,
              hint: const Text("Select Prompt 2"),
              items: _availablePrompts
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedPrompt2 = v),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 5),
            _buildTextField("Your Answer...", _answer2Controller),

            // --- ADD THIS BLOCK BEFORE "Profile Photos" ---
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.purple, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Compatibility Quiz",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          "Answer 5 questions to see Match %",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      "Take Quiz",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- END OF NEW BLOCK ---
            const SizedBox(height: 30),
            Text(
              "Profile Photos",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _photoControllers[index],
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Photo ${index + 1}",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cloud_upload, color: Colors.pink),
                      onPressed: () => _pickAndUploadImage(index),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
