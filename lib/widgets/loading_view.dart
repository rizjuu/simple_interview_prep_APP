import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({super.key, this.message = "Loading..."});

  @override
  Widget build(BuildContext context) {
    return Center(
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
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF00F5D4),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
