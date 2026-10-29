import 'package:flutter/material.dart';
import '../app_colors.dart';

class WarningDetailScreen extends StatelessWidget {
  const WarningDetailScreen({
    super.key,
    this.title = 'Scam Alert Details',
    this.description = 'Potential risk detected on linked account.',
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Threat Warning', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: cream,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navy)),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 15, color: Color(0xFF52627A))),
          ],
        ),
      ),
    );
  }
}