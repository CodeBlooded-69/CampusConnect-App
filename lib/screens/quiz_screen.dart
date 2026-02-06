import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // THE 5 QUESTIONS
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'q1',
      'question': "Friday Night Vibe?",
      'options': ["Party Hard 🎉", "Netflix & Chill 🍿"],
    },
    {
      'id': 'q2',
      'question': "Mess Food?",
      'options': ["Love it 😋", "Survival Only 🤢"],
    },
    {
      'id': 'q3',
      'question': "Exam Strategy?",
      'options': ["One Night Bat 🦇", "Plan Weeks Ahead 🤓"],
    },
    {
      'id': 'q4',
      'question': "Dream Vacation?",
      'options': ["Beach 🏖️", "Mountains 🏔️"],
    },
    {
      'id': 'q5',
      'question': "Communication Style?",
      'options': ["Texting 💬", "Calling 📞"],
    },
  ];

  // Store selected answers here (Map of Question ID -> Answer String)
  final Map<String, String> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadPreviousAnswers();
  }

  Future<void> _loadPreviousAnswers() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (doc.exists && doc.data()!.containsKey('quizAnswers')) {
      setState(() {
        _selectedAnswers.addAll(
          Map<String, String>.from(doc.data()!['quizAnswers']),
        );
      });
    }
  }

  Future<void> _saveQuiz() async {
    if (_selectedAnswers.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'quizAnswers': _selectedAnswers});
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz Saved! Compatibility Active.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Compatibility Quiz 💘",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  "Answer these 5 questions to find your vibe match!",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                ..._questions.map((q) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q['question'],
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // OPTION A
                              Expanded(
                                child: _buildOptionButton(
                                  q['id'],
                                  q['options'][0],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // OPTION B
                              Expanded(
                                child: _buildOptionButton(
                                  q['id'],
                                  q['options'][1],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Save & Find Matches",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildOptionButton(String questionId, String optionLabel) {
    bool isSelected = _selectedAnswers[questionId] == optionLabel;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnswers[questionId] = optionLabel;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.pink : Colors.grey.shade300,
          ),
        ),
        child: Text(
          optionLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
