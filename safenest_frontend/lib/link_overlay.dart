import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'link_guard.dart';

class LinkGuardOverlay extends StatelessWidget {
  final Widget child;
  const LinkGuardOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PendingLink?>(
      valueListenable: LinkGuard.pending,
      builder: (context, p, _) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (p != null) Positioned.fill(child: _Warning(link: p)),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final PendingLink link;
  const _Warning({required this.link});

  @override
  Widget build(BuildContext context) {
    final v = link.verdict;
    final danger = v.level == 'danger';
    final bg = danger ? const Color(0xFFB3261E) : const Color(0xFF8A5A00);
    return Material(
      color: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.shield_outlined, color: Colors.white, size: 72),
              const SizedBox(height: 16),
              Text(
                danger ? "Don't open this link" : 'Be careful with this link',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.15),
              ),
              const SizedBox(height: 8),
              Text(
                danger
                    ? 'It shows several signs of a scam. If a message pushed you to tap it, ignore the message.'
                    : "A few things look off. Don't enter passwords, OTPs or card details on the page.",
                style: const TextStyle(color: Colors.white, fontSize: 17),
              ),
              const SizedBox(height: 24),
              const Text('Where this link really goes', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(v.domain, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(link.url, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 24),
              const Text('What we noticed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final r in v.reasons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 16))),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    LinkGuard.pending.value = null;
                  },
                  child: const Text('Go back to safety', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    LinkGuard.pending.value = null;
                    LinkGuard.open(link.url);
                  },
                  child: const Text('Open it anyway (not recommended)', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
