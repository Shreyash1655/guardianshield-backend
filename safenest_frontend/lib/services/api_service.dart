import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'scam_store.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api/v1';
  static const String devEmail = 'shreyash3@test.com';
  static const String devPassword = 'Test@1234';
  static String? authToken;

  static Future<void> saveToken(String token) async {
    authToken = token;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token);
  }

  static Future<String?> _login() async {
    try {
      final r = await http
          .post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': devEmail, 'password': devPassword}),
      )
          .timeout(const Duration(seconds: 4));
      print('LOGIN ${r.statusCode}');
      if (r.statusCode == 200) {
        final t = jsonDecode(r.body)['access_token'] as String;
        await saveToken(t);
        return t;
      }
    } catch (e) {
      print('LOGIN ERROR: $e');
    }
    return null;
  }

  static Future<String?> _getToken() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final t = p.getString('token');
      if (t != null) return t;
    } catch (_) {}
    return authToken ?? await _login();
  }

  static Future<Map<String, dynamic>?> analyzeContent(
      String channel, String content) async {
    final local = ScamStore.assess(content);
    final localScore = local['score'] as int;

    // Used when the backend is unreachable: score and save on the phone.
    Future<Map<String, dynamic>> offline() async {
      if (localScore >= 40) await ScamStore.addAssessed(channel, content, local);
      return {
        'risk_score': localScore,
        'risk_level': localScore >= 70
            ? 'HIGH_RISK'
            : (localScore >= 40 ? 'SUSPICIOUS' : 'SAFE'),
        'explanation': (local['reasons'] as List).join(' '),
      };
    }

    try {
      Future<http.Response> send(String t) => http
          .post(
        Uri.parse('$baseUrl/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t'
        },
        body: jsonEncode({'channel': channel, 'content': content}),
      )
          .timeout(const Duration(seconds: 5));

      String? token = await _getToken();
      if (token == null) return await offline();
      var res = await send(token);
      if (res.statusCode == 401) {
        token = await _login();
        if (token == null) return await offline();
        res = await send(token);
      }
      print('ANALYZE ${res.statusCode}: ${res.body}');
      if (res.statusCode != 200) return await offline();

      final ev =
      (jsonDecode(res.body)['evaluation'] ?? {}) as Map<String, dynamic>;
      final score = (ev['risk_score'] as num?)?.toInt() ?? 0;
      if (score >= 40) {
        await ScamStore.addAssessed(channel, content, {
          'score': score,
          'type': local['type'],
          'reasons': local['reasons'],
        });
      }
      return {
        'risk_score': score,
        'risk_level': ev['risk_level'],
        'explanation': ev['explanation'],
      };
    } catch (e) {
      print('ANALYZE ERROR: $e');
      return await offline();
    }
  }

  // The backend alerts the caretaker itself on HIGH_RISK, so nothing to do here.
  static Future<void> alertCaretaker(String threatContent, int riskScore) async {
    print('Caretaker alert is handled by the backend');
  }
}