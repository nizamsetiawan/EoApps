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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}


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
    // Initialize NotificationService if not already initialized
    // Perlu cara untuk mengecek apakah sudah diinisialisasi atau memanggil initialize dengan aman
    // Untuk sederhana, panggil initialize saja, pastikan implementasinya aman dipanggil berulang
    await notificationService.initialize();

    print("Native called background task: $taskName");

    // Handle specific tasks based on taskName and inputData
    switch (taskName) {
      case "taskNotificationTask":
        // Panggil method di TaskNotificationService untuk memproses notifikasi terjadwal
        final taskNotificationService = TaskNotificationService();
        if (inputData != null) {
          print(
            'Workmanager received taskNotificationTask with inputData: $inputData',
          );
          // Tunggu hingga proses notifikasi (tampil dan simpan ke Firestore) selesai
          await taskNotificationService.processScheduledNotification(inputData);
        }
        break;
      // Tambahkan case lain jika ada jenis task background lain
    }

    // Return true jika task berhasil (setelah semua async operation selesai)
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set background message handler (untuk FCM, tetap dipertahankan)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inisialisasi Workmanager
  Workmanager().initialize(
    callbackDispatcher, // Fungsi top-level yang akan dijalankan
    isInDebugMode: false, // Set false untuk menonaktifkan debug notifications
  );

  // Initialize notification service (untuk notifikasi foreground/instan)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request permission for notifications
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token
  String? token = await FirebaseMessaging.instance.getToken();

  // Listen for FCM token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
    // Update token in Firestore if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token},
      );
    }
  });

  // Listen for foreground messages (untuk FCM)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {});

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
