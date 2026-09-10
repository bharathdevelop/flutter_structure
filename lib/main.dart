import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_structure/core/constant/colors.dart';
import 'package:flutter_structure/core/services/notification_service.dart';

import 'core/pref/shared_pref.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:firebase_core/firebase_core.dart';

import 'feature/Pages/presentation/page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp( MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: "Poppins",
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(color: secondary),
          backgroundColor: primary,
          iconTheme: IconThemeData(color: secondary),
        ),
        
      ),
      home: HomePage(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> initFireBase() async {
  await Firebase.initializeApp();
  log("Firebase initialized successfully");
  final firebaseMessaging = FirebaseMessaging.instance;
  await firebaseMessaging.requestPermission();

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          criticalAlert: true,
          alert: true,
          badge: true,
          sound: true,
        );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      getFCMNotifications();
    } else {
      Fluttertoast.showToast(
        msg: "Permission denied for notifications",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  } else {
    await firebaseMessaging.requestPermission();
    await getFCMNotifications();
  }
}

Future<void> getFCMNotifications() async {
  String? token = await FirebaseMessaging.instance.getToken();
  final sharepref = Sharepref();
  await sharepref.saveLoginData(fcm: token);
  log("FCM Token: $token");
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    log("onMessage: $message");
    onBackgroundMessage(message);
  });
  FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final title =
        message.notification?.title ??
        message.data['title'] as String? ??
        "Notification";
    final content =
        message.notification?.body ??
        message.data['body'] as String? ??
        message.data['message'] as String? ??
        "";

    // Ignore empty/silent data notifications
    if ((title == "Notification" || title.isEmpty) && content.trim().isEmpty) {
      log("Skipping empty notification");
      return;
    }

    // Save to local database
    // try {
    //   final dbHelper = DatabaseHelper();
    //   await dbHelper.insertNotification({
    //     'title': title,
    //     'body': content,
    //     'timestamp': DateTime.now().toIso8601String(),
    //   });
    // } catch (e) {
    //   log("Error saving notification: $e");
    // }

    NotificationService notificationService = NotificationService();
    await notificationService.initializePlatformNotifications();

    // Check if it's an online notification
    bool isOnline =
        title.toLowerCase().contains("back online") ||
        title.toLowerCase().contains("is online");

    notificationService.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: content,
      payload: "",
      isOnline: isOnline,
    );
    log('Notification displayed: ');
  } catch (ignored) {
    log(ignored.toString());
  }
}
