import 'link_overlay.dart';
import 'link_guard.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'app_colors.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

// Top-level function to handle SMS in the background
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'scam_alerts',
        channelName: 'Scam Alerts',
        channelDescription: 'Scam SMS alerts',
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
    ],
  );
  await _processSmsSecurity(message.body ?? "");
}

// Function to process SMS and detect threats automatically
Future<void> _processSmsSecurity(String text) async {
  print('PROCESSING SMS: $text');
  if (text.isEmpty) return;

  // Call Flask API automatically in the background
  final result = await ApiService.analyzeContent("sms", text);

  if (result == null) {
    await AwesomeNotifications().createNotification(content: NotificationContent(id: 1, channelKey: 'scam_alerts', title: 'API unreachable', body: 'Phone cannot reach the backend'));
    return;
  }
  if (result != null) {
    final score = result['risk_score'] ?? 0;

    // If risk is high, alert user and caretaker!
    if (score >= 0) {
      // 1. Alert user via Awesome Notifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'scam_alerts',
          title: '⚠️ Scam Detected!',
          body: 'A malicious message was just blocked. Do not click any links.',
          color: const Color(0xFFC93426), // Red alert color
        ),
      );

      // 2. Alert Caretaker silently in background
      await ApiService.alertCaretaker(text, score);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup Awesome Notifications
  AwesomeNotifications().initialize(
    null, // Uses default app icon
    [
      NotificationChannel(
        channelKey: 'scam_alerts',
        channelName: 'Scam Alerts',
        channelDescription: 'Alerts for dangerous messages',
        defaultColor: const Color(0xFFC93426),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      )
    ],
  );

  runApp(const SafeNestApp());
}

class SafeNestApp extends StatefulWidget {
  const SafeNestApp({super.key});

  @override
  State<SafeNestApp> createState() => _SafeNestAppState();
}

class _SafeNestAppState extends State<SafeNestApp> {
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    LinkGuard.init();

    // Request Notification Permissions from the user
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    _startShield();
  }

  void _startShield() async {
    await AwesomeNotifications().createNotification(content: NotificationContent(id: 99, channelKey: 'scam_alerts', title: 'SafeNest test', body: 'Notifications work'));
    // Request SMS permissions and start listening
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          print("Foreground SMS received: ${message.body}");
          _processSmsSecurity(message.body ?? "");
        },
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: LinkGuard.navigatorKey,
      builder: (context, child) => LinkGuardOverlay(child: child ?? const SizedBox()),
      title: 'SafeNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: cream,
        primaryColor: orange,
      ),
      home: const SplashScreen(),
    );
  }
}