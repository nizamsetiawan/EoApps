import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'services/task_notification_service.dart';
import 'services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  await notificationService.showNotification(
    id: message.hashCode,
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? '',
    payload: message.data['taskId'] ?? '',
  );
}

// Entry point for background tasks managed by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final NotificationService notificationService = NotificationService();
    await notificationService.initialize();

    switch (taskName) {
      case "taskNotificationTask":
        final taskNotificationService = TaskNotificationService();
        if (inputData != null) {
          await taskNotificationService.processScheduledNotification(inputData);
        }
        break;
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Workmanager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize FCM Service
  final fcmService = FCMService();
  await fcmService.initialize();

  runApp(const TaskSchedulingApp());
}

class TaskSchedulingApp extends StatelessWidget {
  const TaskSchedulingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Scheduling WO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF50C878),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF50C878),
          primary: const Color(0xFF50C878),
        ),
      ),
      home: LoginPage(),
    );
  }
}
