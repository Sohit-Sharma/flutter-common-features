import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:minimind_marvels2/constants/route_const.dart';
import 'package:permission_handler/permission_handler.dart';

// Handles notification tap actions in the background
void backgroundTapHandler(NotificationResponse response){
  print('Background Notification clicked');
  // Get.toNamed(RouteConst.parentDashboard);
}

class NotificationService{

  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize the notification service
  static Future initialize() async {
    // Request permissions for iOS devices
    if (Platform.isIOS) {
      await _requestIOSPermission();
    }else {
      await checkNotificationPermission();
    }

    // Set up local notifications
    await _initializeLocalNotifications();

    // Listen for incoming messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message data: ${message.data}');
      if (message.notification != null) {
        _showLocalNotification(message);
        print('Notification data: ${message.notification}');
      }
    });

    // Handle notification taps when the app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Opened Message: ${message.data} ${message.notification}');
      // Get.toNamed(RouteConst.parentDashboard);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(backgroundHandler);

    // Retrieve the device's Firebase Messaging token
    getToken();
  }

  // Background message handler
  static Future<void> backgroundHandler(RemoteMessage message) async {
    print('Handling firebase background message ${message.messageId}');
    WidgetsBinding.instance.addPostFrameCallback((value){
      // Get.toNamed(RouteConst.parentDashboard);
    });
  }

  // Retrieve the Firebase token for push notifications
  static Future<String?> getToken() async {
    String? token = await messaging.getToken();
    print('Token: $token');
    return token;
  }

  // Request notification permissions specifically for iOS devices
  static Future<void> _requestIOSPermission() async {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // Set up the local notification system
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Default icon for notifications

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Foreground Notification clicked');
        // Get.toNamed(RouteConst.parentDashboard);
      },
      onDidReceiveBackgroundNotificationResponse:backgroundTapHandler,
    );
  }

  // Display a local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'default_channel_id', // Channel ID for grouping notifications
      'Default Notifications', // Channel name visible to the user
      channelDescription: 'This channel is for default notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: null, // Custom sound can be set here
      icon: '@mipmap/ic_launcher', // Custom icon for this notification
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode, // Unique ID for this notification
      message.notification?.title ?? 'No Title', // Notification title
      message.notification?.body ?? 'No Body', // Notification body
      notificationDetails,
      payload: message.data.toString(), // Additional data passed with the notification
    );
  }

  // Check and request notification permissions for Android
  static Future<void> checkNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;
    if (status.isGranted) {
      print("Notification permission already granted");
    } else if (status.isDenied) {
      print("Notification permission denied, requesting now...");
      PermissionStatus newStatus = await Permission.notification.request();
      if (newStatus.isGranted) {
        print("Notification permission granted after request");
      } else {
        print("Notification permission still denied");
      }
    } else if (status.isPermanentlyDenied) {
      print("Notification permission permanently denied, opening settings...");
    }
  }
}
