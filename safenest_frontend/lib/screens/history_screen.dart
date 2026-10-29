import 'package:flutter/material.dart';
import '../app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Scan History', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
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
              const Icon(Icons.history_rounded, size: 60, color: orange),
              const SizedBox(height: 16),
              const Text(
                'No Scans Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your past scam analysis reports will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF52627A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}