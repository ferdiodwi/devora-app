import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Handler untuk notifikasi saat app di background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'devora_notifications',
    'Devora Notifications',
    description: 'Notifikasi peminjaman dan pengembalian buku',
    importance: Importance.high,
  );

  /// Inisialisasi Firebase + local notifications + request permission
  static Future<void> init() async {
    await Firebase.initializeApp();

    // Setup background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup local notifications (untuk saat app foreground)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Buat notification channel Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request permission
    await requestPermission();

    // Setup foreground handler
    _setupForegroundHandler();

    // Simpan FCM token ke backend
    await saveFcmToken();
  }

  /// Minta izin notifikasi dari user
  static Future<void> requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS: izin dari local notifications
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Tampilkan notif lokal saat app sedang terbuka (foreground)
  static void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });
  }

  /// Ambil FCM token dan kirim ke backend
  static Future<void> saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final device = Platform.isIOS ? 'ios' : 'android';
        await ApiService.saveFcmToken(token, device);
      }

      // Auto-refresh token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final device = Platform.isIOS ? 'ios' : 'android';
        await ApiService.saveFcmToken(newToken, device);
      });
    } catch (_) {
      // Gagal simpan token tidak fatal
    }
  }

  /// Ambil jumlah notifikasi belum dibaca dari backend
  static Future<int> getUnreadCount() async {
    try {
      final res = await ApiService.getNotifications();
      if (res['status'] == 200) {
        return res['data']['unread_count'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }
}
