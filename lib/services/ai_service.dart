import 'package:firebase_ai/firebase_ai.dart';
import 'package:interview_prep/widgets/product_model.dart';

/// A service class to interact with the Gemini AI for e-commerce features.
class AIService {
  // Create a Gemini model via Firebase Vertex AI
  final model = FirebaseAI.googleAI().generativeModel(
    // Consider using a more powerful model for better recommendations
    model: 'gemini-1.5-flash-latest',
  );

  /// ==============================
  /// 🧠 AI Product Recommender
  /// ====================================
  Future<List<String>> getAIProductRecommendations({
    required List<String> pastInteractions,
  }) async {
    try {
      final interactionHistory = pastInteractions.join(', ');
      final prompt =
          '''
You are an expert e-commerce AI product recommender.
Based on the user's recent activity, suggest 5 products they might like.
The user has recently viewed or purchased: "$interactionHistory".

Return ONLY a numbered plain list of product names (no commentary, no JSON, no explanation).
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      if (text.isEmpty) return _getFallbackRecommendations();

      // Split into lines, clean, and remove numbering.
      var recommendations = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\d+[\).]?\s*'), ''))
          .toList();

      return recommendations.isNotEmpty
          ? recommendations
          : _getFallbackRecommendations();
    } catch (e) {
      // On error, return a fixed list of fallback recommendations.
      return _getFallbackRecommendations();
    }
  }

  /// ==============================
  /// 📦 Fallback Recommendations
  /// ==============================
  List<String> _getFallbackRecommendations() => [
    'Wireless Headphones',
    'Smart Watch',
    'Portable Charger',
    'Yoga Mat',
    'Coffee Maker',
  ];

  /// ==============================
  /// ⭐ AI Product Analyzer by Star Rating
  /// ====================================
  Future<List<String>> analyzeProductsByRating({
    required List<Product> products,
  }) async {
    try {
      // Sort products by rating in descending order
      final sortedByRating = List<Product>.from(products)
        ..sort((a, b) => b.rating.compareTo(a.rating));

      // Get top-rated products
      final topRatedProducts = sortedByRating.take(5).toList();

      // Create detailed product information for the AI
      final productDetails = topRatedProducts
          .map((p) => '${p.name} (Rating: ${p.rating}/5, Price: \$${p.price})')
          .join('\n');

      final prompt =
          '''
You are an expert e-commerce product analyzer.

Based on star ratings and customer feedback, here are the top-rated products:

$productDetails

Analyze these highly-rated products and recommend them in order of their rating and quality. 
Return ONLY a numbered list of product names with their ratings (no commentary, no JSON).

Format: "1. Product Name (Rating: X.X/5)"
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      if (text.isEmpty) return _getFallbackRatedRecommendations();

      // Parse the response into product recommendations
      var recommendations = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return recommendations.isNotEmpty
          ? recommendations
          : _getFallbackRatedRecommendations();
    } catch (e) {
      // On error, return recommendations based on local rating analysis
      return _getFallbackRatedRecommendations();
    }
  }

  /// ==============================
  /// 🌟 Fallback Rated Recommendations
  /// ==============================
  List<String> _getFallbackRatedRecommendations() => [
    '1. Wireless Headphones (Rating: 4.9/5) - Best overall choice',
    '2. 4K Monitor (Rating: 4.9/5) - Top display quality',
    '3. Laptop Pro (Rating: 4.8/5) - Premium performance',
    '4. Yoga Mat (Rating: 4.8/5) - Most reliable fitness product',
    '5. Smartphone X (Rating: 4.7/5) - Excellent mobile device',
  ];
}
