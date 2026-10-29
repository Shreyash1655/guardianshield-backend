import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../services/api_service.dart';
import 'risk_result_screen.dart';

class AnalyzeThreatScreen extends StatefulWidget {
  const AnalyzeThreatScreen({super.key});

  @override
  State<AnalyzeThreatScreen> createState() => _AnalyzeThreatScreenState();
}

class _AnalyzeThreatScreenState extends State<AnalyzeThreatScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedChannel = 'sms';

  final List<Map<String, dynamic>> _channels = [
    {'id': 'sms', 'title': 'SMS', 'icon': Icons.sms_outlined},
    {'id': 'email', 'title': 'Email', 'icon': Icons.email_outlined},
    {'id': 'url', 'title': 'Website URL', 'icon': Icons.link_rounded},
    {'id': 'voice', 'title': 'Call Transcript', 'icon': Icons.call_outlined},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String get _hintText {
    switch (_selectedChannel) {
      case 'sms':
        return 'Paste the suspicious text message here...';
      case 'email':
        return 'Paste the suspicious email content here...';
      case 'url':
        return 'Paste the website link here...';
      case 'voice':
        return 'Enter the words spoken during the call...';
      default:
        return 'Enter suspicious content here...';
    }
  }

  void _analyzeContent() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter something to check.')),
      );
      return;
    }

    // Show a loading dialog while connecting to Flask
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: orange)),
    );

    final result = await ApiService.analyzeContent(_selectedChannel, content);

    // Pop loading dialog
    if (mounted) Navigator.pop(context);

    if (result != null) {
      final score = result['risk_score'] ?? 50;
      final level = result['risk_level'] ?? 'SUSPICIOUS';
      final List<String> extractedReasons = List<String>.from(
        result['reasons'] ?? ['Potential risk detected.'],
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiskResultScreen(
              content: content,
              channel: _selectedChannel,
              riskScore: score,
              riskLevel: level,
              reasons: extractedReasons,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach backend server. Showing demo result.')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiskResultScreen(
              content: content,
              channel: _selectedChannel,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Check for Scams', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: cream,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Not sure if it is safe?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: navy),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose what you received and we will help you check it for possible scam signs.',
                    style: TextStyle(color: Color(0xFF52627A), fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'What would you like to check?',
                    style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _channels.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 105,
                    ),
                    itemBuilder: (context, index) {
                      final channel = _channels[index];
                      final selected = _selectedChannel == channel['id'];

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedChannel = channel['id'] as String;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFFE7CE) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? orange : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                channel['icon'] as IconData,
                                color: selected ? orange : navy,
                                size: 29,
                              ),
                              const SizedBox(height: 9),
                              Text(
                                channel['title'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Enter the content',
                    style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    minLines: 5,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: _hintText,
                      hintStyle: const TextStyle(color: Color(0xFF8A94A3), fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _analyzeContent,
                      icon: const Icon(Icons.security_rounded),
                      label: const Text(
                        'Analyze Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
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