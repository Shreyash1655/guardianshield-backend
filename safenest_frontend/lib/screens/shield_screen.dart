import 'package:flutter/material.dart';
import '../app_colors.dart';

class ShieldScreen extends StatelessWidget {
  const ShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Real-Time Shield', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: cream,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE7CE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 70, color: orange),
              ),
              const SizedBox(height: 24),
              const Text(
                'Protection Active',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navy),
              ),
              const SizedBox(height: 12),
              const Text(
                'SafeNest is actively protecting incoming SMS and URL links.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF52627A), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}