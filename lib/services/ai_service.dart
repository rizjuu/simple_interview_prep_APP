import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

class AIService {
  // Use VertexAI to create a GenerativeModel.
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
  );

  /// Send interview data (niche, questions & answers) and request ONLY JSON back.
  Future<String> getInterviewFeedback({
    required String niche,
    required List<Map<String, String>> qna, // [{'question': '', 'answer': ''}, ...]
  }) async {
    try {
      // Build a compact but explicit prompt that requests ONLY the JSON object.
      final questionsPart = qna.map((e) => '- Q: ${e['question']}\n  A: ${e['answer']}').join('\n');
      final prompt = '''
IMPORTANT: Return ONLY a valid JSON object exactly like the example below (no extra commentary, no code fences, no explanation). Use correct JSON quoting and commas.

Example:
{
  "niche": "banking",
  "overall_feedback": "Good clarity but improve specifics in answers.",
  "question_feedback":[
    {
      "question":"Tell me about yourself",
      "user_answer":"...user text...",
      "feedback":"Focus on one storyline and quantify achievements."
    }
  ],
  "suggested_improvements":[
    "Add specific numbers to achievements",
    "Practice STAR format for behavioral answers"
  ],
  "suggested_score":"B+"
}

Now evaluate the interview for the niche: "$niche". Provide constructive, actionable, concise feedback for each question listed below. Return ONLY the JSON object.

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

        // Extract the JSON object substring
        final start = cleanJson.indexOf('{');
        final end = cleanJson.lastIndexOf('}') + 1;
        if (start >= 0 && end > start) {
          cleanJson = cleanJson.substring(start, end);
        }

        final parsed = json.decode(cleanJson);

        final overall = parsed['overall_feedback']?.toString() ?? '(none)';
        final suggested = (parsed['suggested_improvements'] as List?)?.cast<String>() ?? [];
        final score = parsed['suggested_score']?.toString() ?? 'N/A';
        final qFeedbackRaw = (parsed['question_feedback'] as List?) ?? [];

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
