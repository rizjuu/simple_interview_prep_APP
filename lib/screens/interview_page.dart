import 'package:flutter/material.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/loading_view.dart';
import '../widgets/interview_controls.dart';
import '../widgets/interview_content.dart';

class InterviewPage extends StatefulWidget {
  const InterviewPage({super.key});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> {
  final AIService _aiService = AIService();
  final PdfService _pdfService = PdfService();
  final TextEditingController _answerController = TextEditingController();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  String _selectedNiche = 'Banking';
  String _selectedMode = 'Mock Interview';
  int _questionIndex = 0;

  final Map<String, List<String>> _questionsByNiche = {
    'Banking': [],
    'Tech Job': [],
    'School Admission': [],
    'Customer Service': [],
  };

  final List<String> _interviewModes = [
    'Mock Interview',
    'Rapid Fire',
    'Deep Dive',
  ];

  final List<String> _givenAnswers = [];

  Timer? _timer;
  int _remainingTime = 60;
  String _lastRecognizedWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadQuestions(); // Load first set of AI questions
  }

  Future<void> _loadQuestions() async {
    setState(() => _isGenerating = true);
    try {
      final generated = await _aiService.generateInterviewQuestions(
        mode: _selectedMode,
        niche: _selectedNiche,
      );
      if (!mounted) return;
      setState(() {
        _questionsByNiche[_selectedNiche] = generated;
      });
    } catch (e) {
      debugPrint("Error loading AI questions: $e");
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load AI questions.')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _startInterview() async {
    setState(() {
      _givenAnswers.clear();
      _questionIndex = 0;
      _timer?.cancel();
      _answerController.clear();
    });
    await _loadQuestions();
  }

  Future<void> _saveAnswerAndNext() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    final questions = _questionsByNiche[_selectedNiche] ?? [];
    if (_questionIndex < questions.length) {
      if (_givenAnswers.length > _questionIndex) {
        _givenAnswers[_questionIndex] = answer;
      } else {
        _givenAnswers.add(answer);
      }
    }

    _answerController.clear();
    _nextQuestion();
  }

  void _nextQuestion() {
    _timer?.cancel();
    setState(() => _questionIndex++);

    final questions = _questionsByNiche[_selectedNiche] ?? [];
    if (_selectedMode == 'Rapid Fire' && _questionIndex < questions.length) {
      _startTimer();
    }
  }

  void _startTimer() {
    _remainingTime = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _timer?.cancel();
        _saveAnswerAndNext(); // Auto-advance when time is up
      }
    });
  }

  Future<void> _finishAndGetFeedback() async {
    if (_isLoading) return; // Prevent action while generating follow-up
    if (_givenAnswers.length <
        (_questionsByNiche[_selectedNiche]?.length ?? 0)) {
      final text = _answerController.text.trim();
      if (text.isNotEmpty) _givenAnswers.add(text);
    }
    _timer?.cancel();

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
    if (mounted) setState(() => _isLoading = false);

    if (!mounted) return;

    // ignore: use_build_context_synchronously
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
              _buildFeedbackContent(feedback),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text("Export PDF"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        backgroundColor: Colors.blue.shade50,
                      ),
                      onPressed: () => _pdfService.generateReport(feedback),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent(Map<String, dynamic> feedback) {
    if (feedback.containsKey('error')) {
      return Text(
        feedback['error'],
        style: const TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    final score = feedback['overall_score'] ?? 'N/A';
    final summary =
        feedback['overall_summary'] as String? ?? 'No summary provided.';
    final categories = feedback['feedback_categories'] as Map? ?? {};
    final improvements =
        (feedback['suggested_improvements'] as List?)?.cast<String>() ?? [];
    final answerFeedback = (feedback['answer_feedback'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score and Summary
        Center(
          child: Chip(
            label: Text(
              'Overall Score: $score / 10',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue.shade100,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Overall Summary:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(summary, style: const TextStyle(fontSize: 15, height: 1.4)),
        const SizedBox(height: 20),

        // Answer-by-answer feedback
        if (answerFeedback.isNotEmpty) ...[
          const Text(
            'Answer Breakdown:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...answerFeedback.map((item) {
            final itemMap = item as Map<String, dynamic>;
            final q = itemMap['question'] ?? 'Unknown Question';
            final s = itemMap['answer_score'] ?? 'N/A';
            final f = itemMap['feedback'] ?? 'No feedback.';
            return Card(
              elevation: 0,
              color: Colors.grey.shade100,
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(q, overflow: TextOverflow.ellipsis)),
                    Chip(label: Text('$s/10'), backgroundColor: Colors.white),
                  ],
                ),
                childrenPadding: const EdgeInsets.all(16),
                expandedAlignment: Alignment.centerLeft,
                children: [Text(f, style: const TextStyle(height: 1.4))],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Categorized Feedback
        if (categories.isNotEmpty)
          const Text(
            'Feedback Categories:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ...categories.entries.map((entry) {
          return Card(
            elevation: 0,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ExpansionTile(
              title: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.all(16),
              expandedAlignment: Alignment.centerLeft,
              children: [
                Text(
                  entry.value.toString(),
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),

        // Suggested Improvements
        if (improvements.isNotEmpty) ...[
          const Text(
            'Suggested Improvements:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...improvements.map((item) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  /// 🎤 Voice recognition logic
  Future<void> _toggleListening() async {
    if (!_isListening) {
      // Request microphone permission first
      final status = await Permission.microphone.request();

      if (status.isDenied) {
        debugPrint('Microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      } else if (status.isPermanentlyDenied) {
        debugPrint(
          'Microphone permission permanently denied, open app settings',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission permanently denied. Please enable it in settings.',
              ),
            ),
          );
        }
        openAppSettings();
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') setState(() => _isListening = false);
        },
        onError: (error) => debugPrint('Speech error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _lastRecognizedWords = '';
        _speech.listen(
          onResult: (result) {
            setState(() {
              // Show real-time partial results
              String currentWords = result.recognizedWords;

              if (result.finalResult) {
                // On final result, append to the answer field
                if (_answerController.text.isEmpty) {
                  _answerController.text = currentWords;
                } else {
                  _answerController.text =
                      '${_answerController.text} $currentWords';
                }
                _lastRecognizedWords = '';
              } else {
                // On partial result, just show preview without committing
                _lastRecognizedWords = currentWords;
              }
            });
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
          ),
        );
      } else {
        debugPrint('Speech to text not available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questionsByNiche[_selectedNiche] ?? [];
    final isLast = _questionIndex >= questions.length;
    final currentQuestion = !isLast ? questions[_questionIndex] : null;

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
                ? const LoadingView(
                    message: "Generating AI interview questions...",
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
                        InterviewControls(
                          selectedNiche: _selectedNiche,
                          nicheKeys: _questionsByNiche.keys.toList(),
                          selectedMode: _selectedMode,
                          modeKeys: _interviewModes,
                          onNicheChanged: (v) async {
                            if (v == null) return;
                            setState(() => _selectedNiche = v);
                            await _loadQuestions();
                          },
                          onModeChanged: (v) async {
                            if (v == null) return;
                            setState(() {
                              _selectedMode = v;
                              _startInterview();
                            });
                          },
                          onRestart: _startInterview,
                        ),
                        const SizedBox(height: 18),

                        // Interview Content
                        InterviewContent(
                          isLast: isLast,
                          isLoading: _isLoading,
                          questionIndex: _questionIndex,
                          totalQuestions: questions.length,
                          currentQuestion: currentQuestion,
                          answerController: _answerController,
                          isListening: _isListening,
                          onFinish: _finishAndGetFeedback,
                          onNext: _saveAnswerAndNext,
                          mode: _selectedMode,
                          remainingTime: _remainingTime,
                          onToggleListening: _toggleListening,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
