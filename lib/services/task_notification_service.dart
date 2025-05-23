import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import '../models/task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TaskNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Send notification when a new task is created
  Future<void> notifyNewTask(Task task) async {
    // Get PM and PIC FCM tokens
    final pmToken = await getUserFCMToken(task.namaPM);
    final picToken = await getUserFCMToken(task.pic);

    // 1. Notifikasi pembuatan task
    if (pmToken != null) {
      await sendNotification(
        token: pmToken,
        title: 'Task Baru Dibuat',
        body:
            'Task "${task.namaTugas}" telah dibuat untuk tanggal ${task.tanggal.toString().split(' ')[0]}',
      );
    }

    if (picToken != null) {
      await sendNotification(
        token: picToken,
        title: 'Task Baru Ditugaskan',
        body:
            'Anda ditugaskan untuk task "${task.namaTugas}" pada tanggal ${task.tanggal.toString().split(' ')[0]}',
      );
    }

    // 2. Notifikasi pengingat 2 menit sebelum task
    final taskStartTime = _parseTaskTime(task.tanggal, task.jamMulai);
    if (taskStartTime != null) {
      // Schedule notification 2 minutes before task start
      final notificationTime = taskStartTime.subtract(
        const Duration(minutes: 2),
      );

      // Schedule notification for PM
      if (pmToken != null) {
        await _notificationService.scheduleTaskNotification(
          taskId: '${task.uid}_pm',
          title: 'Pengingat Task',
          body: 'Task "${task.namaTugas}" akan dimulai dalam 2 menit',
          scheduledTime: notificationTime,
        );
      }

      // Schedule notification for PIC
      if (picToken != null) {
        await _notificationService.scheduleTaskNotification(
          taskId: '${task.uid}_pic',
          title: 'Pengingat Task',
          body: 'Task "${task.namaTugas}" akan dimulai dalam 2 menit',
          scheduledTime: notificationTime,
        );
      }
    }
  }

  // Get user's FCM token from Firestore
  Future<String?> getUserFCMToken(String email) async {
    try {
      final userDoc =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userDoc.docs.isNotEmpty) {
        return userDoc.docs.first.data()['fcmToken'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Send FCM notification
  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, Object>? extraData,
  }) async {
    try {
      final Map<String, Object> notificationData = {
        'token': token,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (extraData != null) {
        notificationData.addAll(extraData);
      }
      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      // Handle error silently
    }
  }

  // Parse task time from date and time string
  DateTime? _parseTaskTime(DateTime date, String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_notification_channel',
            'Task Notifications',
            channelDescription: 'Notifications for task updates',
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  Future<void> scheduleTaskNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String taskId,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      taskId.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_notification_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task updates',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
