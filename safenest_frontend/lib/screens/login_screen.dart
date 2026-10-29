import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'home_screen.dart';
import 'caretaker_home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.role,
  });

  final String role;

  void _continueToDashboard(BuildContext context) {
    if (role == 'elder') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CaretakerHomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isElder = role == 'elder';

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 95,
                    height: 95,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE7CE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: orange,
                      size: 52,
                    ),
                  ),

                  const SizedBox(height: 14),

                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(text: 'Safe', style: TextStyle(color: navy)),
                        TextSpan(text: 'Nest', style: TextStyle(color: orange)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Stay Safe. Stay Connected.',
                    style: TextStyle(
                      color: Color(0xFF52627A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    isElder
                        ? "Welcome! Let's keep you safe."
                        : "Welcome! Let's protect your loved ones.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _continueToDashboard(context),
                      icon: const Icon(Icons.person_outline_rounded, color: navy),
                      label: const Text(
                        'Continue as Guest (Demo)',
                        style: TextStyle(fontSize: 15, color: navy),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F6F9),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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