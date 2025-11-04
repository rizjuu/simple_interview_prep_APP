import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  String _resultText = '';
  String _selectedNiche = 'Banking';
  int _currentIndex = 0;

  final Map<String, List<String>> _questionsByNiche = {
    'Banking': [],
    'Tech Job': [],
    'School Admission': [],
    'Customer Service': [],
  };

  final List<String> _givenAnswers = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadQuestions(); // Load first set of AI questions
  }

  Future<void> _loadQuestions() async {
    setState(() => _isGenerating = true);
    try {
      final generated =
          await _aiService.generateInterviewQuestions(niche: _selectedNiche);
      setState(() {
        _questionsByNiche[_selectedNiche] = generated;
      });
    } catch (e) {
      debugPrint("Error loading AI questions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load AI questions.')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _startInterview() async {
    setState(() {
      _givenAnswers.clear();
      _currentIndex = 0;
      _answerController.clear();
      _resultText = '';
    });
    await _loadQuestions();
  }

  void _saveAnswerAndNext() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    final questions = _questionsByNiche[_selectedNiche] ?? [];
    if (_currentIndex < questions.length) {
      if (_givenAnswers.length > _currentIndex) {
        _givenAnswers[_currentIndex] = answer;
      } else {
        _givenAnswers.add(answer);
      }
    }

    _answerController.clear();
    setState(() => _currentIndex++);
  }

  Future<void> _finishAndGetFeedback() async {
    if (_givenAnswers.length <
        (_questionsByNiche[_selectedNiche]?.length ?? 0)) {
      final text = _answerController.text.trim();
      if (text.isNotEmpty) _givenAnswers.add(text);
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
    final feedback = await _aiService.getInterviewFeedback(
      niche: _selectedNiche,
      qna: qna,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
              Text(feedback, style: const TextStyle(fontSize: 16, height: 1.5)),
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

  /// 🎤 Voice recognition logic
  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') setState(() => _isListening = false);
        },
        onError: (error) => debugPrint('Speech error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _answerController.text = result.recognizedWords;
            });
          },
        );
      } else {
        debugPrint('Microphone permission denied');
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questionsByNiche[_selectedNiche] ?? [];
    final isLast = _currentIndex >= questions.length;
    final currentQuestion = !isLast ? questions[_currentIndex] : null;

    return GradientBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _isGenerating
                ? Center(
                    key: const ValueKey('loading'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/aiai.json',
                          width: 180,
                          height: 180,
                          repeat: true,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Generating AI interview questions...",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    key: const ValueKey('content'),
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dropdown + Restart
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedNiche,
                                    items: _questionsByNiche.keys
                                        .map(
                                          (k) => DropdownMenuItem(
                                            value: k,
                                            child: Text(k),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      setState(() => _selectedNiche = v);
                                      await _loadQuestions();
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Restart',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Animation Header
                        Center(
                          child: Lottie.asset(
                            'assets/aiai.json',
                            width: 120,
                            height: 120,
                            repeat: true,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Interview Content
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: isLast
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "You completed the mock interview 🎉",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                      onPressed: _isLoading
                                          ? null
                                          : _finishAndGetFeedback,
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Question ${_currentIndex + 1} of ${questions.length}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentQuestion ?? '',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),

                                    // Answer input
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        TextField(
                                          controller: _answerController,
                                          maxLines: 5,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Speak or type your answer here...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: FloatingActionButton(
                                            mini: true,
                                            backgroundColor: _isListening
                                                ? Colors.redAccent
                                                : Colors.blueAccent,
                                            onPressed: _toggleListening,
                                            child: Icon(
                                              _isListening
                                                  ? Icons.mic
                                                  : Icons.mic_none,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              final text =
                                                  _answerController.text.trim();
                                              if (text.isEmpty) return;
                                              if (_givenAnswers.length >
                                                  _currentIndex) {
                                                _givenAnswers[_currentIndex] =
                                                    text;
                                              } else {
                                                _givenAnswers.add(text);
                                              }
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text('Answer saved'),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blueGrey,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Save'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GlowButton(
                                            isLoading: false,
                                            label: 'Next',
                                            onPressed: _saveAnswerAndNext,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_givenAnswers.isNotEmpty)
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _givenAnswers.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            dense: true,
                                            title: Text(
                                                'Q${index + 1}: ${questions[index]}'),
                                            subtitle:
                                                Text(_givenAnswers[index]),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 12),
                        if (_resultText.isNotEmpty)
                          FeedbackCard(feedback: _resultText),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
