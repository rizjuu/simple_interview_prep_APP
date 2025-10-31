import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/ai_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/feedback_card.dart';
import '../widgets/glow_button.dart';

class InterviewPage extends StatefulWidget {
  const InterviewPage({super.key});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> {
  final AIService _aiService = AIService();
  final TextEditingController _answerController = TextEditingController();

  String _selectedNiche = 'Banking';
  bool _isLoading = false;
  String _resultText = '';
  int _currentIndex = 0;

  // Built-in short interview questions per niche
  final Map<String, List<String>> _questionsByNiche = {
    'Banking': [
      'Tell me about yourself and why you want to work in banking.',
      'Describe a time you handled a difficult client or stakeholder.',
      'How do you ensure accuracy when working with numbers and reports?',
    ],
    'Tech Job': [
      'Tell me about a challenging technical problem you solved.',
      'How do you stay current with new technologies?',
      'Describe a project where you had to collaborate with others.',
    ],
    'School Admission': [
      'Why do you want to join this program/school?',
      'Describe a meaningful extracurricular or achievement.',
      'How will this program help you reach your goals?',
    ],
    'Customer Service': [
      'Tell me about a time you turned an unhappy customer into a satisfied one.',
      'How do you prioritize tasks during a busy shift?',
      'What does excellent customer service mean to you?',
    ],
  };

  List<Map<String, String>> get _currentQnA {
    final questions = _questionsByNiche[_selectedNiche] ?? [];
    final entries = <Map<String, String>>[];
    for (var i = 0; i < questions.length; i++) {
      entries.add({
        'question': questions[i],
        'answer': i < _givenAnswers.length ? _givenAnswers[i] : '',
      });
    }
    return entries;
  }

  final List<String> _givenAnswers = [];

  void _startInterview() {
    setState(() {
      _givenAnswers.clear();
      _currentIndex = 0;
      _answerController.clear();
      _resultText = '';
    });
  }

  void _saveAnswerAndNext() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    if (_currentIndex < _questionsByNiche[_selectedNiche]!.length) {
      if (_givenAnswers.length > _currentIndex) {
        _givenAnswers[_currentIndex] = answer;
      } else {
        _givenAnswers.add(answer);
      }
    }
    _answerController.clear();
    setState(() {
      _currentIndex++;
    });
  }

  Future<void> _finishAndGetFeedback() async {
    // Ensure all answers are collected
    if (_givenAnswers.length < (_questionsByNiche[_selectedNiche]?.length ?? 0)) {
      // If last answer not saved yet, try saving
      final text = _answerController.text.trim();
      if (text.isNotEmpty) {
        _givenAnswers.add(text);
      }
    }

    final qna = <Map<String, String>>[];
    final questions = _questionsByNiche[_selectedNiche] ?? [];
    for (var i = 0; i < questions.length; i++) {
      qna.add({
        'question': questions[i],
        'answer': i < _givenAnswers.length ? _givenAnswers[i] : '',
      });
    }

    setState(() => _isLoading = true);
    final feedback = await _aiService.getInterviewFeedback(niche: _selectedNiche, qna: qna);
    setState(() => _isLoading = false);

    if (!mounted) return;

    // Show results in bottom sheet (same pattern as your original app)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "✨ AI Interview Feedback",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                feedback,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("Close"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questionsByNiche[_selectedNiche] ?? [];
    final isLast = _currentIndex >= questions.length;
    final currentQuestion = !isLast ? questions[_currentIndex] : null;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "InterviewPrep: AI Interview Coach",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // niche selector + restart
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedNiche,
                          items: _questionsByNiche.keys
                              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedNiche = v;
                              _startInterview();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _startInterview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Restart', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
              const SizedBox(height: 18),

              // animated helper
              Lottie.asset(
                'assets/aiai.json',
                width: 120,
                height: 120,
                repeat: true,
              ),
              const SizedBox(height: 8),

              // Interview area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isLast
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "You completed the mock interview 🎉",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Tap Finish to get tailored AI feedback.",
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              GlowButton(
                                isLoading: _isLoading,
                                label: 'Finish & Get Feedback',
                                onPressed: _isLoading ? null : _finishAndGetFeedback,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${_currentIndex + 1} of ${questions.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentQuestion ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _answerController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Type your answer here (be concise but specific)...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Save current without moving (allow edit)
                                      final text = _answerController.text.trim();
                                      if (text.isEmpty) return;
                                      if (_givenAnswers.length > _currentIndex) {
                                        _givenAnswers[_currentIndex] = text;
                                      } else {
                                        _givenAnswers.add(text);
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Answer saved')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Save'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GlowButton(
                                    isLoading: false,
                                    label: 'Next',
                                    onPressed: () {
                                      _saveAnswerAndNext();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_givenAnswers.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _givenAnswers.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      dense: true,
                                      title: Text('Q${index + 1}: ${questions[index]}'),
                                      subtitle: Text(_givenAnswers[index]),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (_resultText.isNotEmpty) FeedbackCard(feedback: _resultText),
            ],
          ),
        ),
      ),
    );
  }
}
