import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

// 1. ADD THESE IMPORTS AT THE TOP
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

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _jobController = TextEditingController();

  // Images
  final List<TextEditingController> _urlControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  // Dropdowns & Selection
  String _selectedGender = 'Man';

  // --- NEW: College Search Logic ---
  String? _selectedCollege; // Stores the final selected college string
  final TextEditingController _collegeSearchController =
      TextEditingController();

  // FULL LIST OF COLLEGES
  final List<String> _allColleges = [
    "E001 - Acharya Institute of Technology - Bengaluru",
    "E003 - A.C.S. College of Engineering - Bengaluru",
    "E004 - Adichunchanagiri Institute Of Technology - Chikkamagaluru",
    "E005 - Akash Institute of Engineering and Technology - Bengaluru Rural",
    "E006 - Alva's Institute of Engineering & Technology - Mangaluru",
    "E007 - AMC Engineering College - Bengaluru",
    "E009 - Angadi Institute of Technology and Management - Belagavi",
    "E011 - APS College of Engineering - Bengaluru",
    "E012 - Atria Institute of Technology - Bengaluru",
    "E013 - Akshaya Institute of Technology - Tumakuru",
    "E014 - Anuvartik Mirji Bharatesh Institute of Technology - Belagavi",
    "E015 - B.N.M. Institute of Technology - Bengaluru",
    "E016 - KLE Technological University (BVBCET) - Hubballi",
    "E017 - Ballari Institute of Technology & Management - Ballari",
    "E019 - Bangalore Institute of Technology - Bengaluru",
    "E020 - Bangalore Technological Institute - Bengaluru",
    "E021 - Bapuji Institute of Engineering & Technology - Davangere",
    "E023 - Basavakalyan Engineering College - Bidar",
    "E024 - Basaveshwar Engineering College - Bagalkot",
    "E026 - BLDEA's V.P. Dr. P.G. Halakatti College - Vijayapura",
    "E027 - BMS College of Engineering - Bengaluru",
    "E028 - BMS Institute of Technology & Management - Bengaluru",
    "E030 - Brindavan College of Engineering - Bengaluru",
    "E032 - C.M.R. Institute of Technology - Bengaluru",
    "E033 - Cambridge Institute of Technology - Bengaluru",
    "E035 - Channabasaveshwara Institute of Technology - Tumakuru",
    "E036 - Chanakya University - Bengaluru Rural",
    "E037 - City Engineering College - Bengaluru",
    "E038 - Coorg Institute of Technology - South Kodagu",
    "E039 - Dayananda Sagar Academy of Technology & Management - Bengaluru",
    "E040 - Dayananda Sagar College of Engineering - Bengaluru",
    "E041 - DON BOSCO Institute of Technology - Bengaluru",
    "E042 - Dr. Ambedkar Institute of Technology - Bengaluru",
    "E043 - Yenepoya Institute of Technology - Mangaluru",
    "E044 - Dr.Shri Shri Shivakumara Mahaswamy College - Bengaluru Rural",
    "E045 - Dr H N National College Of Engineering - Bengaluru",
    "E046 - East Point College of Engineering and Technology - Bengaluru",
    "E048 - East West Institute of Technology - Bengaluru",
    "E049 - Garden City University - Bengaluru",
    "E050 - Global Academy of Technology - Bengaluru",
    "E051 - GM Institute of Technology - Davangere",
    "E053 - Gopalan College of Engineering And Management - Bengaluru",
    "E055 - GSSS Institute of Engineering and Technology for Women - Mysuru",
    "E056 - H.K.E.Society's P.D.A. College of Engineering - Kalaburgi",
    "E058 - Sri Jayachamarajendra College of Engineering - Mysuru",
    "E059 - Jawaharlal Nehru New College of Engineering (JNNCE) - Shivamogga",
    "E060 - JSS Academy of Technical Education - Bengaluru",
    "E061 - JSS Science & Technology University - Mysuru",
    "E062 - Jain College of Engineering - Belagavi",
    "E063 - Jnana Vikas Institute of Technology - Bengaluru Rural",
    "E064 - Jain College Of Engineering & Research - Belagavi",
    "E065 - KLE Technological University - Belagavi",
    "E066 - KLE College of Engineering and Technology - Belagavi",
    "E067 - K.S School of Engineering And Management - Bengaluru",
    "E068 - K.S. Institute of Technology - Bengaluru",
    "E069 - KVG College Of Engineering - Dakshina Kannada",
    "E070 - Kalpataru Institute of Technology - Tiptur",
    "E071 - Karavali Institute of Technology - Mangaluru",
    "E073 - KLS Gogte Institute of Technology - Belagavi",
    "E074 - KLS's. Vishwanathrao Deshpande Institute of Technology - Haliyal",
    "E075 - K. N. S. INSTITUTE OF TECHNOLOGY - Bengaluru",
    "E076 - M.S. Engineering College - Bengaluru",
    "E077 - M.S. Ramaiah Institute of Technology - Bengaluru",
    "E078 - Maharaja Institute of Technology - Mandya",
    "E079 - Malnad College of Engineering - Hassan",
    "E080 - Mangalore Institute of Technology & Engineering - Mangaluru",
    "E081 - Moodalakatte Institute of Technology - Kundapura",
    "E082 - Maharaja Institute of Technology - Mysuru",
    "E083 - Mysuru Royal Institute of Technology - Mandya",
    "E084 - Nagarjuna College of Engineering & Technology - Bengaluru",
    "E085 - The National Institute of Engineering (North) - Mysuru",
    "E088 - Navodaya Institute of Technology - Raichur",
    "E089 - P.E.S.College of Engineering - Mandya",
    "E090 - PES Institute of Technology & Management - Shivamogga",
    "E094 - Proudhadevaraya Institute of Technology - Hosapete",
    "E095 - R V College of Engineering - Bengaluru",
    "E096 - R.L. Jalappa Institute of Technology - Doddaballapur",
    "E097 - R.R. Institute of Technology - Bengaluru",
    "E098 - R.T.E. Society's Rural Engineering College - Gadag",
    "E099 - Raja Rajeswari College of Engineering - Bengaluru",
    "E100 - Rajeev Institute of Technology - Hassan",
    "E101 - Rajiv Gandhi Institute of Technology - Bengaluru",
    "E102 - Rao Bahadur Y Mahabaleswarappa Engineering College - Ballari",
    "E104 - RNS Institute of Technology - Bengaluru",
    "E105 - Bheemanna Khandre Institute of Technology - Bidar",
    "E107 - SJB Institute of Technology - Bengaluru",
    "E108 - S J C Institute of Technology - Chikkaballapur",
    "E109 - S.E.A. College of Engineering & Technology - Bengaluru",
    "E110 - SSET's S.G. Balekundri Institute of Technology - Belagavi",
    "E111 - Hirasugar Institute of Technology - Nidasoshi",
    "E112 - Sahyadri College of Engineering and Management - Mangaluru",
    "E113 - Sai Vidya Institute of Technology - Bengaluru",
    "E114 - Sambhram Institute of Technology - Bengaluru",
    "E116 - SAPTHAGIRI NPS UNIVERSITY - Bengaluru",
    "E117 - SDM College of Engineering & Technology - Dharwad",
    "E118 - SDM Institute of Technology - Dakshina Kannada",
    "E119 - SECAB Institute of Engineering & Technology - Vijayapura",
    "E121 - Sri Sairam College of Engineering - Bengaluru",
    "E122 - Shree Devi Institute of Technology - Mangaluru",
    "E123 - Shri Madhwa Vadiraja Institute of Technology - Udupi",
    "E124 - Shridevi Institute of Engineering & Technology - Tumakuru",
    "E125 - Siddaganga Institute of Technology - Tumakuru",
    "E126 - Sir M.Visvesvaraya Institute of Technology - Bengaluru",
    "E127 - S J M Institute of Technology - Chitradurga",
    "E128 - Smt. Kamala and Sri Venkappa M. Agadi College - Gadag",
    "E132 - Sri Krishna Institute of Technology - Bengaluru",
    "E136 - Sri Taralabalu Jagadguru Institute of Technology - Ranebennur",
    "E137 - Sri Venkateshwara College of Engineering - Bengaluru",
    "E138 - Srinivas Institute of Technology - Mangaluru",
    "E141 - T. John Institute of Technology - Bengaluru",
    "E142 - The National Institute of Engineering (South) - Mysuru",
    "E143 - Tontadarya College of Engineering - Gadag",
    "E144 - Veerappa Nisty Engineering College - Yadgir",
    "E145 - Vemana Institute of Technology - Bengaluru",
    "E146 - Vidya Vikas Institute of Engineering & Technology - Mysuru",
    "E147 - Vidyavardhaka College of Engineering - Mysuru",
    "E148 - Vivekananda College of Engineering and Technology - Dakshina Kannada",
    "E152 - ATME College of Engineering - Mysuru",
    "E156 - Jyothy Institute of Technology - Bengaluru",
    "E158 - Shetty Institute of Technology - Kalaburagi",
    "E159 - Lingaraj Appa Engineering - Bidar",
    "E161 - Cambridge Institute of Technology (North) - Bengaluru",
    "E164 - Reva University - Bengaluru",
    "E165 - Alliance College of Engineering & Design - Bengaluru",
    "E171 - GITAM (Deemed to be University) - Bengaluru",
    "E172 - Mysore College of Engineering and Management - Mysuru",
    "E173 - Presidency University - Bengaluru",
    "E183 - Jain Institute of Technology - Davangere",
    "E187 - CMR University - Bengaluru",
    "E191 - Sir M V School Of Architecture - Bengaluru",
    "E194 - Jain College of Engineering and Technology - Hubballi",
    "E195 - Navkis College of Engineering - Hassan",
    "E197 - M.S. Ramaiah University of Applied Sciences - Bengaluru",
    "E198 - R V Institute of Technology and Management - Bengaluru",
    "E199 - Biluru Gurubasava Mahaswamiji Institute - Bagalkot",
    "E201 - G Madegowda Institute of Technology - Mandya",
    "E202 - C Byregowda Institute of Technology - Kolar",
    "E203 - Amruta Institute of Engineering - Bengaluru Rural",
    "E204 - Sir M. Visvesvaraya College of Engineering - Raichur",
    "E205 - Vijaya Vittala Institution of Technology - Bengaluru",
    "E206 - Cauvery Institute Of Technology - Mandya",
    "E207 - BGS College of Engineering and Technology - Bengaluru",
    "E208 - A.G.M Rural College of Engineering - Hubballi",
    "E209 - Aditya College of Engineering and Technology - Bengaluru",
    "E211 - East West College of Engineering - Bengaluru",
    "E212 - Seshadripuram Institute of Technology - Mysuru",
    "E214 - Sri Siddhartha School of Engineering - Tumakuru",
    "E215 - Cauvery College of Engineering - Mysuru",
    "E216 - New Ebenezer Institute of Technology - Bengaluru",
    "E217 - Harsha Institute of Technology - Bengaluru Rural",
    "IIT Bombay", "IIT Delhi", "BITS Pilani", // Kept your originals too
  ];

  final Color _accentColor = const Color(0xFFFD297B);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _ageController.text = (data['age'] ?? '').toString();
          _phoneController.text = data['phoneNumber'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _jobController.text = data['job'] ?? '';
          _selectedGender = data['gender'] ?? 'Man';

          // Load College
          if (data['campus'] != null) {
            _selectedCollege = data['campus'];
            _collegeSearchController.text = data['campus'];
          }

          List<dynamic> savedImages = data['userImages'] ?? [];
          if (savedImages.isEmpty && data['imageUrl'] != null) {
            savedImages.add(data['imageUrl']);
          }
          for (int i = 0; i < 5; i++) {
            if (i < savedImages.length) {
              _urlControllers[i].text = savedImages[i].toString();
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix errors"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Check College
    if (_selectedCollege == null || _selectedCollege!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid University/College"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<String> validImages = _urlControllers
            .map((c) => c.text.trim())
            .where((url) => url.isNotEmpty)
            .toList();

        if (validImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add at least 1 image URL")),
          );
          setState(() => _isLoading = false);
          return;
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 18,
          'phoneNumber': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
          'job': _jobController.text.trim(),
          'campus': _selectedCollege, // Save the selected college
          'gender': _selectedGender,
          'userImages': validImages,
          'imageUrl': validImages[0],
          'isProfileComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    "Save",
                    style: GoogleFonts.inter(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Profile Photos"),
              const SizedBox(height: 10),

              // Photo Grid
              SizedBox(
                height: 300,
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildPhotoPreview(0)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(child: _buildPhotoPreview(1)),
                          const SizedBox(height: 10),
                          Expanded(child: _buildPhotoPreview(2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Expanded(child: _buildPhotoPreview(3)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildPhotoPreview(4)),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              _buildSectionHeader("Photo URLs"),
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _urlControllers[index],
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.link, color: Colors.grey),
                      hintText: "Photo ${index + 1} URL",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("About You"),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _nameController,
                label: "Full Name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _phoneController,
                label: "Phone Number (Required)",
                icon: Icons.phone_outlined,
                isNumber: true,
                isPhone: true,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _jobController,
                label: "Job Title / Major",
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      label: "Age",
                      icon: Icons.calendar_today,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          items: ['Man', 'Woman', 'Non-binary']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedGender = val!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _bioController,
                label: "Bio",
                icon: Icons.edit,
                maxLines: 4,
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("University / College"),
              const SizedBox(height: 10),

              // --- SEARCHABLE COLLEGE DROPDOWN (AUTOCOMPLETE) ---
              LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<String>(
                    initialValue: TextEditingValue(
                      text: _selectedCollege ?? '',
                    ),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _allColleges.where((String option) {
                        return option.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _selectedCollege = selection;
                      });
                      debugPrint('You selected: $selection');
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          // Sync initial value if loaded from DB
                          if (_selectedCollege != null &&
                              controller.text.isEmpty) {
                            controller.text = _selectedCollege!;
                          }
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText:
                                  "Search University (e.g. 'Bangalore' or 'E001')",
                              prefixIcon: const Icon(
                                Icons.school,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _accentColor),
                              ),
                            ),
                          );
                        },
                  );
                },
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPhotoPreview(int index) {
    String url = _urlControllers[index].text.trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : Center(child: Icon(Icons.add_a_photo, color: Colors.grey[300])),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return "$label is required";
        if (isPhone && val.trim().length < 10) return "Invalid Number";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
