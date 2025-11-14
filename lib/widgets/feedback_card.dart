import 'package:flutter/material.dart';

class FeedbackCard extends StatelessWidget {
  final String feedback;
  final TextStyle? style;
  const FeedbackCard({super.key, required this.feedback, this.style});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          feedback,
          style: style ?? const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }
}
