import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'interview_page.dart'; // renamed from essay_page.dart

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // AI animation
                      Lottie.asset(
                        'assets/ai_intro.json',
                        width: 220,
                        height: 220,
                        repeat: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Welcome to InterviewPrep AI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Your AI-powered interview practice assistant",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        label: const Text(
                          "Start Interview",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const InterviewPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                                    .chain(CurveTween(curve: Curves.easeOutCubic));
                                return SlideTransition(position: animation.drive(tween), child: child);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
