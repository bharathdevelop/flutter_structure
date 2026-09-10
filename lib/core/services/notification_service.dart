import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService();

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initializePlatformNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: darwinInitializationSettings,
        );

    await _localNotifications.initialize(settings: initializationSettings);

    const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      'gcam_alert_channel_1',
      'Gcam Alert Notifications',
      description: 'Gcam Alert Notifications with custom sound',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alert'),
    );

    const AndroidNotificationChannel onlineChannel = AndroidNotificationChannel(
      'gcam_online_channel_1',
      'Gcam Online Notifications',
      description: 'Gcam Online Notifications with custom sound',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('online'),
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(alertChannel);
    await androidPlugin?.createNotificationChannel(onlineChannel);
  }

  Future<NotificationDetails> _notificationDetails(bool isOnline) async {
    if (isOnline) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'gcam_online_channel_1',
            'Gcam Online Notifications',
            channelDescription: 'Gcam Online Notifications with custom sound',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('online'),
            ticker: 'ticker',
          );
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
            sound: 'online.mp3',
          );

      return NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinNotificationDetails,
      );
    } else {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'gcam_alert_channel_1',
            'Gcam Alert Notifications',
            channelDescription: 'Gcam Alert Notifications with custom sound',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            ticker: 'ticker',
          );
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
            sound: 'alert.mp3',
          );

      return NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinNotificationDetails,
      );
    }
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool isOnline = false,
  }) async {
    final platformChannelSpecifics = await _notificationDetails(isOnline);
    await _localNotifications.show(
      id:id,
      title:  title,
      body:  body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}
