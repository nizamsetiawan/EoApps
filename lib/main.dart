import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Ini adalah fungsi top-level yang akan dijalankan oleh Workmanager
// @pragma('vm:entry-point') diperlukan untuk Flutter 3.1+ atau jika aplikasi diobfuscate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Inisialisasi Firebase dan flutter_local_notifications di dalam isolate background
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inisialisasi NotificationService di sini
    final NotificationService notificationService = NotificationService();
    await notificationService
        .initialize(); // Pastikan ada metode initialize di NotificationService

    print("Native called background task: $taskName");

    // Handle specific tasks based on taskName and inputData
    switch (taskName) {
      case "taskNotificationTask":
        // Contoh: Mendapatkan data notifikasi dari inputData
        final int? id = inputData?['id'] as int?;
        final String? title = inputData?['title'] as String?;
        final String? body = inputData?['body'] as String?;
        final String? payload = inputData?['payload'] as String?;

        if (id != null && title != null && body != null) {
          print('Memicu notifikasi background: $title - $body');
          await notificationService.showNotification(
            id: id,
            title: title,
            body: body,
            payload: payload ?? '',
          );
        }
        break;
      // Tambahkan case lain jika ada jenis task background lain
    }

    // Return true jika task berhasil
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
    isInDebugMode: true, // Set true untuk debugging
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
