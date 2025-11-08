import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

class AIService {
  // Create a Gemini model via Firebase Vertex AI
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
  );

  /// ==============================
  /// 🧠 Generate Interview Questions
  /// ==============================
  Future<List<String>> generateInterviewQuestions({
    required String mode,
    required String niche,
  }) async {
    try {
      String modeInstruction;
      switch (mode) {
        case 'Rapid Fire':
          modeInstruction =
              'Generate 5 short-answer questions designed for quick, 1-minute responses.';
          break;
        case 'Deep Dive':
          modeInstruction =
              'Generate 5 in-depth, multi-part questions that require detailed, analytical answers.';
          break;
        default: // Mock Interview
          modeInstruction =
              'Generate 5 realistic and challenging interview questions.';
      }
      final prompt =
          '''$modeInstruction for a "$niche" interview. Make them sound like they are from a real interviewer.
Return ONLY a numbered plain list (no commentary, no JSON, no explanation). Example:

1. Tell me about yourself.
2. Describe a situation where you showed leadership.
3. What are your strengths and weaknesses?
4. Why do you want to work in this field?
5. How do you handle stress or pressure?
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Split into lines, clean, and ensure we have exactly 5 questions
      var questions = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map(
            (line) => line.replaceAll(RegExp(r'^\d+[\).]?\s*'), ''),
          ) // Remove numbers like "1. "
          .toList();

      // If we have more than 5, take the first 5.
      if (questions.length > 5) {
        questions = questions.sublist(0, 5);
      }
      // If we have fewer than 5, add from the fallback list.
      else if (questions.length < 5) {
        final fallback = _getFallbackQuestions();
        final needed = 5 - questions.length;
        questions.addAll(fallback.take(needed));
      }

      return questions;
    } catch (e) {
      // On error, return a fixed list of 5 fallback questions.
      return _getFallbackQuestions();
    }
  }

  /// ==============================
  /// 🧠 Generate Follow-up Question
  /// ==============================
  Future<String> getFollowUpQuestion({
    required String niche,
    required String question,
    required String answer,
  }) async {
    try {
      final prompt =
          '''
You are an interviewer for a "$niche" position.
The original question was: "$question"
The user's answer was: "$answer"

Based on this, generate a single, concise, and relevant follow-up question.
Return ONLY the question text (no commentary, no numbering, no explanation).
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      return text.isEmpty ? 'Can you elaborate on that?' : text;
    } catch (e) {
      return 'Interesting. Can you give me an example?';
    }
  }

  ///feeback
  Future<Map<String, dynamic>> getInterviewFeedback({
    required String niche,
    required List<Map<String, String>>
    qna, // [{'question': '', 'answer': ''}, ...]
  }) async {
    try {
      // Build a compact but explicit prompt that requests ONLY the JSON object.
      final questionsPart = qna
          .map((e) => '- Q: ${e['question']}\n  A: ${e['answer']}')
          .join('\n');

      final prompt =
          '''
IMPORTANT: Return ONLY a valid JSON object exactly like the example below (no extra commentary, no code fences, no explanation). Use correct JSON quoting and commas.

Example:
{
  "overall_score": 8.5,
  "overall_summary": "A solid performance. You were articulate and professional, but you could strengthen your answers by providing more specific, quantifiable examples.",
  "answer_feedback": [
    { "question": "Tell me about yourself.", "answer_score": 7, "feedback": "Good start, but could be more structured and tied to the role." },
    { "question": "Why this company?", "answer_score": 9, "feedback": "Excellent, well-researched answer that showed genuine interest." }
  ],
  "feedback_categories": {
    "Communication 🗣️": "Your verbal communication was clear and well-paced. You answered questions directly.",
    "Content Accuracy 📚": "Your understanding of the core topics is good, but you missed some nuances in the question about X.",
    "Confidence 💪": "You appeared confident and maintained good eye contact, which is excellent.",
    "Professionalism 👔": "Your tone and language were professional throughout the entire interview."
  },
  "suggested_improvements": [
    "Add specific numbers to achievements",
    "Practice STAR format for behavioral answers"
  ]
}

Now evaluate the interview for the niche: "$niche".
Provide a score from 1-10 for each answer, an overall score, and constructive, actionable, concise feedback.
Return ONLY the JSON object.

Interview (questions and user answers):
$questionsPart
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      if (raw.isEmpty) return {'error': 'No feedback generated.'};

      try {
        // Basic cleanup: smart quotes, code fences, stray text
        var cleanJson = raw
            .replaceAll(RegExp(r'[\u201C\u201D]'), '"')
            .replaceAll(RegExp(r'```json\s*|\s*```'), '')
            .trim();

        // Extract JSON block
        final start = cleanJson.indexOf('{');
        final end = cleanJson.lastIndexOf('}') + 1;
        if (start >= 0 && end > start) {
          cleanJson = cleanJson.substring(start, end);
        }

        // Return the parsed JSON object directly.
        return json.decode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        return {'error': 'Could not parse feedback. Raw output:\n\n$raw'};
      }
    } catch (e) {
      return {'error': 'Error generating feedback: $e'};
    }
  }

  /// ==============================
  /// 📦 Fallback Questions
  /// ==============================
  List<String> _getFallbackQuestions() => [
    'Tell me about yourself.',
    'What are your biggest strengths?',
    'What are your biggest weaknesses?',
    'Why are you interested in this role?',
    'Describe a challenge you faced and how you overcame it.',
  ];
}
