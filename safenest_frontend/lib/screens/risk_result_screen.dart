import 'package:flutter/material.dart';
import '../app_colors.dart';

class RiskResultScreen extends StatelessWidget {
  final String content;
  final String channel;
  final int riskScore;
  final String riskLevel;
  final List<String> reasons;

  const RiskResultScreen({
    super.key,
    required this.content,
    required this.channel,
    this.riskScore = 85,
    this.riskLevel = 'HIGH RISK',
    this.reasons = const [
      'This is a demonstration result.',
      'Never share OTPs, passwords or banking PINs.',
    ],
  });

  Color get riskColor {
    switch (riskLevel.toUpperCase()) {
      case 'SAFE':
        return const Color(0xFF218838);
      case 'SUSPICIOUS':
        return const Color(0xFFE69A00);
      default:
        return const Color(0xFFC93426);
    }
  }

  IconData get riskIcon {
    switch (riskLevel.toUpperCase()) {
      case 'SAFE':
        return Icons.verified_user_rounded;
      case 'SUSPICIOUS':
        return Icons.warning_amber_rounded;
      default:
        return Icons.gpp_bad_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: navy,
        elevation: 0,
        title: const Text('Safety Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(riskIcon, color: riskColor, size: 56),
                  const SizedBox(height: 18),
                  Text(riskLevel, style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: riskColor)),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Risk Score', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: navy)),
                        const SizedBox(height: 14),
                        Text('$riskScore / 100', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: riskColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Check Another Message'),
                      style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white),
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