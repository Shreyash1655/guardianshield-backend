import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class LinkVerdict {
  final String level; // danger, caution, clear
  final String domain;
  final List<String> reasons;
  LinkVerdict(this.level, this.domain, this.reasons);
}

class LinkGuard {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const _channel = MethodChannel('safenest/link_guard');
  static bool _busy = false;
  static final ValueNotifier<PendingLink?> pending = ValueNotifier<PendingLink?>(null);

  static const _short = {'bit.ly','tinyurl.com','t.co','goo.gl','is.gd','cutt.ly','rb.gy','ow.ly','buff.ly','shorturl.at','tiny.cc','rebrand.ly','t.ly'};
  static const _badTld = {'xyz','top','click','live','icu','buzz','tk','ml','gq','cf','ga','work','support','cam','rest','monster','cyou','sbs','vip','loan','zip','mov'};
  static const _words = ['secure','verify','update','login','signin','account','auth','bank','kyc','wallet','support','alert','confirm','refund','reward','prize','lucky','gift','suspended','blocked'];
  static const _sld = {'co.in','org.in','gov.in','ac.in','nic.in','net.in','co.uk','org.uk','com.au','co.nz','com.br','co.za'};
  static const Map<String, List<String>> _brands = {
    'sbi': ['sbi.co.in', 'onlinesbi.sbi'], 'hdfc': ['hdfcbank.com'], 'icici': ['icicibank.com'],
    'axis': ['axisbank.com'], 'paytm': ['paytm.com'], 'phonepe': ['phonepe.com'],
    'google': ['google.com', 'google.co.in'], 'amazon': ['amazon.com', 'amazon.in'],
    'flipkart': ['flipkart.com'], 'paypal': ['paypal.com'], 'microsoft': ['microsoft.com'],
    'apple': ['apple.com'], 'netflix': ['netflix.com'], 'irctc': ['irctc.co.in'],
    'whatsapp': ['whatsapp.com'], 'instagram': ['instagram.com'], 'facebook': ['facebook.com'],
  };
  static const _known = {
    'secure-auth-update-bank.com', 'secure-kyc-update-bank.com', 'lucky-prize-claim.top',
    'courier-delivery-fee.top', 'quick-profit-earn.vip', 'mail-verify-login-secure.com',
    'outlook-secure-login.com', 'power-bill-update.in', 'sbi-kyc-update.xyz',
  };
  static Future<void> check(String url) => _handle(url);
  static final _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  static Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'incomingLink') {
        final url = call.arguments as String?;
        if (url != null) _handle(url);
      }
    });
    try {
      final url = await _channel.invokeMethod<String>('getInitialLink');
      if (url != null) {
        await Future.delayed(const Duration(milliseconds: 600));
        _handle(url);
      }
    } catch (_) {}
  }

  static Future<void> open(String url) async {
    try {
      await _channel.invokeMethod('openInBrowser', url);
    } catch (_) {}
  }

  static Future<String> _urlhaus(String url) async {
    try {
      final r = await http
          .post(
            Uri.parse('https://safenest-url-checker.avkhalesanjay.workers.dev/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) return (jsonDecode(r.body)['status'] as String?) ?? 'unknown';
    } catch (_) {}
    return 'unknown';
  }

  static String _regDomain(String host) {
    if (_ipv4.hasMatch(host) || host.startsWith('[')) return host;
    final l = host.split('.');
    if (l.length >= 3 && _sld.contains(l.sublist(l.length - 2).join('.'))) {
      return l.sublist(l.length - 3).join('.');
    }
    return l.length >= 2 ? l.sublist(l.length - 2).join('.') : host;
  }

  static LinkVerdict analyze(Uri u, String status) {
    final host = u.host.toLowerCase();
    final reg = _regDomain(host);
    final why = <MapEntry<int, String>>[];
    void add(int p, String t) => why.add(MapEntry(p, t));
    final tokens = host.split(RegExp(r'[.-]'));

    if (status == 'malicious') add(100, 'This link is listed as a known malware address.');
    if (u.scheme == 'http') add(15, "It doesn't use HTTPS, so the connection isn't encrypted.");
    if (u.userInfo.isNotEmpty) add(30, 'It contains an @ sign, a trick used to disguise the real address.');
    if (_ipv4.hasMatch(host) || host.startsWith('[')) add(35, 'It points to a raw number address instead of a website name.');
    if (host.contains('xn--') || host.runes.any((c) => c > 127)) add(30, 'It uses look-alike letters to imitate a real site.');
    if (_short.contains(reg)) add(20, 'It is a shortened link, so the real destination is hidden.');
    final tld = host.split('.').last;
    if (_badTld.contains(tld)) add(20, 'The .$tld ending is common on throwaway scam sites.');
    final hy = '-'.allMatches(host).length;
    if (hy >= 3) {
      add(20, 'The address has $hy hyphens, typical of made-up "official" names.');
    } else if (hy == 2) {
      add(8, 'The address has several hyphens.');
    }
    if (host.split('.').length - reg.split('.').length >= 3) add(15, 'It has a long chain of sub-names in front of the real domain.');
    final hits = _words.where((w) => host.contains(w)).toList();
    if (hits.length >= 2) {
      add(25, 'The address stacks urgent words: ${hits.take(4).join(', ')}.');
    } else if (hits.length == 1) {
      add(8, 'The address contains the word "${hits.first}".');
    }
    for (final e in _brands.entries) {
      final name = e.key;
      final ok = e.value.any((d) => reg == d || host.endsWith('.$d'));
      if (ok) continue;
      if (tokens.contains(name)) {
        add(40, 'It mentions "$name" but is not a $name website. Its real domain is $reg.');
      } else if (tokens.any((t) => t != name && t.replaceAll('0', 'o').replaceAll('1', 'l').replaceAll('3', 'e').replaceAll('5', 's') == name)) {
        add(40, 'It imitates "$name" by swapping letters for numbers.');
      }
    }
    if (u.hasPort) add(10, 'It uses an unusual port number (${u.port}).');
    if (u.toString().length > 120) add(8, 'The link is unusually long.');
    if (RegExp(r'/(login|signin|verify|otp|kyc|update)', caseSensitive: false).hasMatch(u.path)) {
      add(8, 'The page path asks you to log in or verify something.');
    }

    final score = why.fold<int>(0, (a, b) => a + b.key);
    why.sort((a, b) => b.key.compareTo(a.key));
    final level = score >= 45 ? 'danger' : (score >= 15 ? 'caution' : 'clear');
    return LinkVerdict(level, reg, why.map((e) => e.value).toList());
  }

  static Future<void> _handle(String url) async {
    if (_busy) return;
    final u = Uri.tryParse(url.trim());
    if (u == null || u.host.isEmpty || (u.scheme != 'http' && u.scheme != 'https')) return;
    _busy = true;
    try {
      final status = _known.contains(_regDomain(u.host.toLowerCase())) ? 'malicious' : await _urlhaus(url);
      final v = analyze(u, status);
      print('LINKGUARD ${v.level} $status $url');
      if (v.level == 'clear') {
        await open(url);
        return;
      }
      for (var i = 0; i < 10 && navigatorKey.currentState == null; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      pending.value = PendingLink(url, v);
    } finally {
      _busy = false;
    }
  }
}

class LinkWarningPage extends StatelessWidget {
  final String url;
  final LinkVerdict verdict;
  const LinkWarningPage({super.key, required this.url, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final danger = verdict.level == 'danger';
    final bg = danger ? const Color(0xFFB3261E) : const Color(0xFF8A5A00);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
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
                Text(verdict.domain, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SelectableText(url, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 24),
                const Text('What we noticed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final r in verdict.reasons)
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
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text('Go back to safety', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      LinkGuard.open(url);
                    },
                    child: const Text('Open it anyway (not recommended)', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class PendingLink {
  final String url;
  final LinkVerdict verdict;
  PendingLink(this.url, this.verdict);
}

