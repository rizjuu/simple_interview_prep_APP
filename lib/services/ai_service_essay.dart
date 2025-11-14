import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

class AIService {
  // Use VertexAI to create a GenerativeModel. gemini-1.5 is retired; use
  // a current Gemini model. You can change this string as needed.
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
  );

  Future<String> getEssayFeedback(String essayText) async {
    try {
      final prompt =
          '''
You are an expert English language teacher and essay editor with extensive experience in academic writing. Your task is to thoroughly analyze and improve the given essay by:

1. Making substantial corrections to:
   - Grammar, spelling, and punctuation
   - Sentence structure and flow
   - Word choice and formality
   - Argument structure and logic

2. For each correction:
   - Identify the problematic text exactly
   - Provide a significantly improved version
   - Focus on making meaningful improvements, not just capitalization

3. Evaluate and provide feedback on:
   - Argument strength and evidence
   - Organization and coherence
   - Academic tone and style
   - Overall effectiveness

Response Format:
Return ONLY a valid JSON object with this exact structure:

{
  "corrections": [
    {
      "original": "exact problematic text",
      "corrected": "improved version with meaningful changes",
      "explanation": "brief explanation of why this improvement helps"
    }
  ],
  "structure_feedback": [
    "specific feedback about essay organization and flow"
  ],
  "content_feedback": [
    "specific feedback about argument strength and evidence"
  ],
  "style_feedback": [
    "specific feedback about academic tone and writing style"
  ],
  "grade": {
    "score": "letter grade A-F",
    "reason": "brief explanation of the grade"
  }
}


Instructions:

Output must be valid JSON.

Include at least one grammar correction if applicable.

Include at least one item of writing feedback.

Assign a suggested grade (A, B, C, D, or F).

Do not include any other text, formatting, or explanation.

$essayText
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      if (raw.isEmpty) return 'No feedback generated.';

      try {
        // Clean up common JSON formatting issues before parsing
        var cleanJson = raw
            .replaceAll(RegExp(r'[\u201C\u201D]'), '"') // Fix smart quotes
            .replaceAll(RegExp(r'```json\s*|\s*```'), '') // Remove code blocks
            .trim();

        // Find the first { and last } to extract just the JSON object
        final start = cleanJson.indexOf('{');
        final end = cleanJson.lastIndexOf('}') + 1;
        if (start >= 0 && end > start) {
          cleanJson = cleanJson.substring(start, end);
        }

        final parsed = json.decode(cleanJson);
        final corrections =
            (parsed['corrections'] as List?)
                ?.map((c) {
                  if (c is Map) {
                    return {
                      'original': c['original']?.toString() ?? '',
                      'corrected': c['corrected']?.toString() ?? '',
                      'explanation': c['explanation']?.toString() ?? '',
                    };
                  }
                  return null;
                })
                .where((c) => c != null)
                .toList() ??
            [];
        final structureFeedback =
            (parsed['structure_feedback'] as List?)?.cast<String>() ?? [];
        final contentFeedback =
            (parsed['content_feedback'] as List?)?.cast<String>() ?? [];
        final styleFeedback =
            (parsed['style_feedback'] as List?)?.cast<String>() ?? [];
        final grade = parsed['grade'] as Map? ?? {};

        final buffer = StringBuffer();
        buffer.writeln('Grade: ${grade['score'] ?? 'N/A'}');
        buffer.writeln('Reason: ${grade['reason'] ?? ''}\n');

        buffer.writeln('Content Corrections:');
        if (corrections.isEmpty) {
          buffer.writeln('  (none)');
        } else {
          for (var c in corrections) {
            buffer.writeln('  • Original: "${c?['original']}"');
            buffer.writeln('    Improved: "${c?['corrected']}"');
            buffer.writeln('    Why: ${c?['explanation']}\n');
          }
        }

        buffer.writeln('Structure Feedback:');
        for (var f in structureFeedback) {
          buffer.writeln('  • $f');
        }

        buffer.writeln('\nArgument & Evidence Feedback:');
        for (var f in contentFeedback) {
          buffer.writeln('  • $f');
        }

        buffer.writeln('\nWriting Style Feedback:');
        for (var f in styleFeedback) {
          buffer.writeln('  • $f');
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
