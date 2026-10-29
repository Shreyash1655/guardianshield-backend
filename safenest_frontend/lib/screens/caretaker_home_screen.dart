import 'package:flutter/material.dart';
import '../app_colors.dart';

class CaretakerHomeScreen extends StatelessWidget {
  const CaretakerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFE7CE),
                        child: Icon(
                          Icons.shield_rounded,
                          color: orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SafeNest',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                            Text(
                              'Caretaker dashboard',
                              style: TextStyle(
                                color: Color(0xFF52627A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile screen coming next!'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          color: navy,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Hello, Caretaker!',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Stay connected and help your loved ones stay safe online.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF52627A),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Linked elder
                  const Text(
                    'Connected Elder',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Color(0xFFFFE7CE),
                          child: Icon(
                            Icons.elderly_rounded,
                            color: orange,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your linked elder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: navy,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Connection status will appear here',
                                style: TextStyle(
                                  color: Color(0xFF52627A),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.people_alt_rounded,
                          color: orange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Alert summary
                  const Text(
                    'Threat Overview',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.check_circle_outline,
                          title: 'Safe',
                          count: '—',
                          color: const Color(0xFF16865D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.warning_amber_rounded,
                          title: 'Suspicious',
                          count: '—',
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.gpp_bad_outlined,
                          title: 'High Risk',
                          count: '—',
                          color: const Color(0xFFC93426),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Recent alerts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Alerts',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Incident history screen coming next!'),
                            ),
                          );
                        },
                        child: const Text('View all', style: TextStyle(color: orange)),
                      ),
                    ],
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 38,
                          color: orange,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No alerts to display yet',
                          style: TextStyle(
                            color: navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'New alerts will appear here when available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF52627A),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Safety reminder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.favorite_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A little support goes a long way',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: navy,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Help your loved one pause and verify before sharing sensitive information or sending money.',
                                style: TextStyle(
                                  color: Color(0xFF52627A),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF52627A),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}