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
  Future<List<String>> generateInterviewQuestions({required String niche}) async {
    try {
      final prompt = '''
Generate 5 realistic and challenging interview questions for a "$niche" interview.
Make them sound like real interviewer questions.
Return ONLY a numbered plain list (no commentary, no JSON, no explanation). Example:

1. Tell me about yourself.
2. Describe a situation where you showed leadership.
3. What are your strengths and weaknesses?
4. Why do you want to work in this field?
5. How do you handle stress or pressure?
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Split into lines and clean
      final questions = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\d+[\).]?\s*'), '')) // Remove numbers like "1. "
          .toList();

      // Fallback in case the AI returns less than 3 questions
      if (questions.length < 3) {
        questions.addAll([
          'Why are you interested in this role?',
          'Describe a challenge you faced and how you overcame it.',
          'Where do you see yourself in five years?',
        ]);
      }

      return questions;
    } catch (e) {
      return [
        'Tell me about yourself.',
        'Describe a time you overcame a challenge.',
        'Why do you want this position?'
      ];
    }
  }
///feeback
  Future<String> getInterviewFeedback({
    required String niche,
    required List<Map<String, String>> qna, // [{'question': '', 'answer': ''}, ...]
  }) async {
    try {
      // Build a compact but explicit prompt that requests ONLY the JSON object.
      final questionsPart = qna
          .map((e) => '- Q: ${e['question']}\n  A: ${e['answer']}')
          .join('\n');

      final prompt = '''
IMPORTANT: Return ONLY a valid JSON object exactly like the example below (no extra commentary, no code fences, no explanation). Use correct JSON quoting and commas.

Example:
{
  "niche": "banking",
  "overall_feedback": "Good clarity but improve specifics in answers.",
  "question_feedback": [
    {
      "question": "Tell me about yourself",
      "user_answer": "...user text...",
      "feedback": "Focus on one storyline and quantify achievements."
    }
  ],
  "suggested_improvements": [
    "Add specific numbers to achievements",
    "Practice STAR format for behavioral answers"
  ],
  "suggested_score": "B+"
}

Now evaluate the interview for the niche: "$niche".
Provide constructive, actionable, concise feedback for each question listed below.
Return ONLY the JSON object.

Interview (questions and user answers):
$questionsPart
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      if (raw.isEmpty) return 'No feedback generated.';

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

        final parsed = json.decode(cleanJson);

        // Extract components
        final overall = parsed['overall_feedback']?.toString() ?? '(none)';
        final suggested = (parsed['suggested_improvements'] as List?)?.cast<String>() ?? [];
        final score = parsed['suggested_score']?.toString() ?? 'N/A';
        final qFeedbackRaw = (parsed['question_feedback'] as List?) ?? [];

        // Build readable summary for display
        final buffer = StringBuffer();
        buffer.writeln('Niche: ${parsed['niche'] ?? niche}\n');
        buffer.writeln('Suggested score: $score\n');
        buffer.writeln('Overall feedback:\n$overall\n');
        buffer.writeln('\nPer-question feedback:');
        if (qFeedbackRaw.isEmpty) {
          buffer.writeln('  (none)');
        } else {
          for (var item in qFeedbackRaw) {
            final q = item['question']?.toString() ?? '';
            final a = item['user_answer']?.toString() ?? '';
            final f = item['feedback']?.toString() ?? '';
            buffer.writeln('\n• Question: $q');
            buffer.writeln('  Your answer: $a');
            buffer.writeln('  Feedback: $f');
          }
        }

        buffer.writeln('\nSuggested improvements:');
        if (suggested.isEmpty) {
          buffer.writeln('  (none)');
        } else {
          for (var s in suggested) buffer.writeln('  • $s');
        }

        return buffer.toString();
      } catch (e) {
        return 'Could not parse JSON. Raw output:\n\n$raw';
      }
    } catch (e) {
      return 'Error generating feedback: $e';
    }
  }
}
