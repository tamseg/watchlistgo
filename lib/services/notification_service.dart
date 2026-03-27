import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_database_service.dart';
import '../app.dart';
import '../screens/series_detail_page.dart';
import '../screens/movie_detail_page.dart';

const _channelId = 'watchlstgo_notifications';
const _channelName = 'Watchlist Notifications';
const _channelDescription = 'Notifications for new episodes and movie releases.';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
}

void _handleNotificationRouting(Map<String, dynamic> data) {
  final type = data['type'];
  final idRaw = data['id'];
  if (type == null || idRaw == null) return;

  final id = int.tryParse(idRaw.toString());
  if (id == null) return;

  final context = navigatorKey.currentContext;
  if (context != null) {
    if (type == 'tv') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailPage(seriesId: id)));
    } else if (type == 'movie') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailPage(movieId: id)));
    }
  }
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirestoreDatabaseService _db;

  NotificationService({required FirestoreDatabaseService db}) : _db = db;

  Future<void> init() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            _handleNotificationRouting(Map<String, dynamic>.from(data));
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationRouting(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationRouting(initialMessage.data);
      });
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _setupToken();
  }

  Future<void> _setupToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await updateStoredToken(token);
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        updateStoredToken(newToken);
      });
    } catch (e) {
      debugPrint('FCM setup failed: $e');
    }
  }

  Future<void> updateStoredToken(String? token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _db.updateFcmToken(uid: user.uid, token: token);
      }
    } catch (e) {
      debugPrint('FCM token update failed: $e');
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      BigPictureStyleInformation? bigPictureStyle;
      String? largeIconPath;
      final imageUrl = android.imageUrl;

      if (imageUrl != null) {
        try {
          final fileInfo = await DefaultCacheManager().downloadFile(imageUrl);
          largeIconPath = fileInfo.file.path;
          bigPictureStyle = BigPictureStyleInformation(
            FilePathAndroidBitmap(largeIconPath),
            hideExpandedLargeIcon: true,
          );
        } catch (e) {
          debugPrint('Error loading notification image: $e');
        }
      }

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        payload: jsonEncode(message.data),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
            styleInformation: bigPictureStyle,
          ),
        ),
      );
    }
  }
}
