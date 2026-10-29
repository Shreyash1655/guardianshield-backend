import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // <-- Make sure 'const' is present here

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9F0),
              Color(0xFFFFF0DD),
              Color(0xFFFFE4BF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const SafeNestLogo(),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(
                      text: 'Safe',
                      style: TextStyle(color: navy),
                    ),
                    TextSpan(
                      text: 'Nest',
                      style: TextStyle(color: orange),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stay Safe. Stay Connected.',
                style: TextStyle(fontSize: 17, color: navy),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.45,
                    minHeight: 5,
                    backgroundColor: Color(0xFFD9C9B5),
                    color: orange,
                  ),
                ),
              ),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}

class SafeNestLogo extends StatelessWidget {
  const SafeNestLogo({super.key, this.size = 145});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.home_rounded,
            size: size * 0.79,
            color: orange,
          ),
          Positioned(
            right: size * 0.08,
            bottom: size * 0.08,
            child: Icon(
              Icons.verified_user_rounded,
              size: size * 0.43,
              color: navy,
            ),
          ),
          Positioned(
            right: size * 0.21,
            bottom: size * 0.18,
            child: Icon(
              Icons.check_rounded,
              size: size * 0.19,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}