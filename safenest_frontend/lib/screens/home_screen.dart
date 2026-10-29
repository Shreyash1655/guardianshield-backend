import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../services/scam_store.dart';
import 'trusted_circle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _log = [];
  Map<String, double> _stats = {'scanned': 0, 'avgMs': 0};
  String _tab = 'all';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScamStore.changes.addListener(_load);
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _load());
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScamStore.changes.removeListener(_load);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final l = await ScamStore.all();
    final s = await ScamStore.stats();
    if (mounted) setState(() { _log = l; _stats = s; });
  }

  Color _col(int s) => s >= 70 ? Colors.red : orange;
  IconData _ico(String c) => switch (c) {
    'sms' => Icons.sms_rounded,
    'email' => Icons.email_rounded,
    'whatsapp' => Icons.chat_rounded,
    _ => Icons.warning_rounded,
  };

  Widget _metric(String v, String l) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy)),
        Text(l, style: const TextStyle(fontSize: 11, color: Color(0xFF52627A))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final shown = _tab == 'all' ? _log : _log.where((e) => e['channel'] == _tab).toList();
    final unseen = _log.where((e) => e['seen'] == false).toList();
    final alert = unseen.isEmpty ? null : unseen.first;
    return Stack(children: [
      Scaffold(
        backgroundColor: cream,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SafeNest Shield',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: navy)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: const Color(0xFF16865D), borderRadius: BorderRadius.circular(22)),
                    child: const Column(children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 56),
                      SizedBox(height: 12),
                      Text('Protection Active',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('SafeNest reads incoming SMS, email and chat notifications and warns you about scams.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    _metric('${_stats['scanned']!.toInt()}', 'Scanned'),
                    const SizedBox(width: 8),
                    _metric('${_log.length}', 'Threats'),
                    const SizedBox(width: 8),
                    _metric('${_stats['avgMs']!.toStringAsFixed(2)} ms', 'Avg detect time'),
                  ]),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const TrustedCircleScreen())),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(children: [
                          Icon(Icons.people_alt_rounded, color: orange, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                              child: Text('Caretaker Network',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: navy))),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: navy),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Detected scams',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    for (final t in ['all', 'sms', 'email', 'whatsapp'])
                      ChoiceChip(
                        label: Text(t == 'sms' ? 'SMS' : t[0].toUpperCase() + t.substring(1)),
                        selected: _tab == t,
                        onSelected: (_) => setState(() => _tab = t),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  if (shown.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No scams here yet.', style: TextStyle(color: Color(0xFF52627A)))),
                  for (final e in shown)
                    Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: Icon(_ico(e['channel']), color: _col(e['score'])),
                        title: Text(e['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          Chip(
                              label: Text(e['type'], style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact),
                          Text('${e['channel'].toString().toUpperCase()} · risk ${e['score']}',
                              style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
      if (alert != null)
        Positioned.fill(
          child: _RedAlert(
            a: alert,
            onDismiss: () async {
              await ScamStore.markSeen();
              _load();
            },
          ),
        ),
    ]);
  }
}

class _RedAlert extends StatelessWidget {
  final Map<String, dynamic> a;
  final VoidCallback onDismiss;
  const _RedAlert({required this.a, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final reasons = ((a['reasons'] as List?) ?? []).cast<String>();
    return Material(
      color: const Color(0xFFB3261E),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            const Icon(Icons.gpp_bad_rounded, color: Colors.white, size: 80),
            const SizedBox(height: 12),
            const Text('Scam detected',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${a['channel'].toString().toUpperCase()} · ${a['type']} · risk ${a['score']}/100',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
              child: Text(a['content'], style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
            const SizedBox(height: 20),
            const Text('Why this is dangerous',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            for (final r in reasons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 16))),
                ]),
              ),
            const SizedBox(height: 16),
            const Text('Do not click any link, call back, or share OTPs or card details.',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFB3261E),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: onDismiss,
                child: const Text('I understand, I will not respond',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}