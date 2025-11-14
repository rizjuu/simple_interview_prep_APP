import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'glow_button.dart';

class InterviewContent extends StatelessWidget {
  final bool isLast;
  final bool isLoading;
  final int questionIndex;
  final int totalQuestions;
  final String? currentQuestion;
  final TextEditingController answerController;
  final bool isListening;
  final VoidCallback onFinish;
  final VoidCallback onNext;
  final String mode;
  final int remainingTime;
  final VoidCallback onToggleListening;

  const InterviewContent({
    super.key,
    required this.isLast,
    required this.isLoading,
    required this.questionIndex,
    required this.totalQuestions,
    this.currentQuestion,
    required this.answerController,
    required this.isListening,
    required this.onFinish,
    required this.onNext,
    required this.mode,
    required this.remainingTime,
    required this.onToggleListening,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Lottie.asset(
            'assets/aiai.json',
            width: 120,
            height: 120,
            repeat: true,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isLast ? _buildCompletionView() : _buildQuestionView(),
        ),
      ],
    );
  }

  Widget _buildCompletionView() {
    return Column(
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
          isLoading: isLoading,
          label: 'Finish & Get Feedback',
          onPressed: isLoading ? null : onFinish,
        ),
      ],
    );
  }

  Widget _buildQuestionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mode == 'Rapid Fire') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '0:${remainingTime.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        // Progress Tracker
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (questionIndex + 1) / totalQuestions,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Question ${questionIndex + 1} of $totalQuestions',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(currentQuestion ?? '', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        _buildAnswerInput(),
        const SizedBox(height: 12),
        Row(
          children: [
            const Spacer(), // This could be a save button if needed
            Expanded(
              child: GlowButton(
                isLoading: isLoading,
                label: 'Next',
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerInput() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        TextField(
          controller: answerController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Speak or type your answer here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            mini: true,
            backgroundColor: isListening ? Colors.redAccent : Colors.blueAccent,
            onPressed: onToggleListening,
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
