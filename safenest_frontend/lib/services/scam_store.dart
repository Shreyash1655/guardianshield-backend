import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScamStore {
  static const _key = 'scam_log';
  static final changes = ValueNotifier<int>(0);

  static Future<List<Map<String, dynamic>>> all() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final raw = p.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> markSeen() async {
    final list = await all();
    for (final e in list) {
      if (e['seen'] == false) e['seen'] = true;
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(list));
    changes.value++;
  }

  static Future<Map<String, double>> stats() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final n = p.getInt('scan_count') ?? 0;
    final us = p.getInt('latency_total_us') ?? 0;
    return {'scanned': n.toDouble(), 'avgMs': n == 0 ? 0 : us / n / 1000};
  }

  // On-device rule engine (same rules as the Kotlin listener).
  static Map<String, dynamic> assess(String text) {
    final t = text.toLowerCase();
    int s = 0;
    final why = <String>[];
    void hit(int p, String r, String rx) {
      if (RegExp(rx).hasMatch(t)) {
        s += p;
        why.add(r);
      }
    }

    hit(30, 'Asks for an OTP, PIN or CVV. Banks never do this.',
        r'\botp\b|\bpin\b|\bcvv\b|verification code');
    hit(25, 'Claims your account is blocked or suspended.',
        r'blocked|suspended|deactivated|frozen|locked');
    hit(20, 'Asks you to verify KYC or identity.',
        r'\bkyc\b|verify your (account|identity)');
    hit(20, 'Promises a prize or lottery win.',
        r'lottery|you (have )?won|prize|reward');
    hit(20, 'Threatens arrest or legal action.',
        r'arrest|police|\bcbi\b|warrant');
    hit(20, 'Asks for money or a fee.',
        r'send money|transfer|gift card|processing fee');
    hit(15, 'Creates false urgency.',
        r'urgent|immediately|within \d+ (hours|minutes)|act now');
    hit(15, 'Contains a link.', r'https?://|www\.');
    hit(10, 'Link uses a hyphenated look-alike address.',
        r'https?://[^\s]*-[^\s]*');

    final type = RegExp(r'\botp\b|\bpin\b').hasMatch(t)
        ? 'OTP'
        : RegExp(r'lottery|won|prize').hasMatch(t)
        ? 'Lottery/Prize'
        : RegExp(r'arrest|police|cbi').hasMatch(t)
        ? 'Impersonation'
        : RegExp(r'kyc|bank|account|suspended|blocked').hasMatch(t)
        ? 'Bank/KYC'
        : RegExp(r'https?://|www\.').hasMatch(t)
        ? 'Phishing link'
        : 'Other';
    return {'score': s > 100 ? 100 : s, 'type': type, 'reasons': why};
  }

  // Saves a flagged message, skipping one the notification listener already saved.
  static Future<void> addAssessed(
      String channel, String content, Map<String, dynamic> a) async {
    final list = await all();
    final dup = list.take(5).any((e) {
      final c = (e['content'] ?? '') as String;
      return c.contains(content) || content.contains(c);
    });
    if (dup) return;
    list.insert(0, {
      'channel': channel.toLowerCase(),
      'type': a['type'],
      'content': content,
      'score': a['score'],
      'reasons': a['reasons'],
      'seen': false,
      'time': DateTime.now().toIso8601String(),
    });
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(list.take(200).toList()));
    changes.value++;
  }
}