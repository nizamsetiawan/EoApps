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

// Handler untuk menangani pesan saat aplikasi di background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi service notifikasi
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  // Tampilkan notifikasi jika ada
  if (message.notification != null) {
    await notificationService.showNotification(
      id: message.hashCode,
      title: message.notification!.title ?? 'Notifikasi Baru',
      body: message.notification!.body ?? '',
      payload: message.data['taskId'] ?? '',
    );
  }
}

// Entry point untuk background tasks yang dikelola oleh Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Inisialisasi Firebase jika belum ada
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Inisialisasi service notifikasi
    final NotificationService notificationService = NotificationService();
    await notificationService.initialize();

    // Proses task notifikasi terjadwal
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

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Atur handler untuk pesan background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inisialisasi Workmanager untuk notifikasi terjadwal
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Inisialisasi service notifikasi
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Inisialisasi service FCM
  final fcmService = FCMService();
  await fcmService.initialize();

  runApp(const TaskSchedulingApp());
}

// Widget utama aplikasi
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
