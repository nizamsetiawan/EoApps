import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Plugin untuk menangani notifikasi lokal
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Stream untuk menangani notifikasi yang dipilih
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inisialisasi service notifikasi
  Future<void> initialize() async {
    try {
      // Atur timezone ke Jakarta
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      await requestPermissions();

      // Konfigurasi untuk Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Konfigurasi untuk iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Gabungkan konfigurasi
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      // Inisialisasi plugin notifikasi
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            selectNotificationStream.add(payload);
          }
        },
      );

      // Konfigurasi khusus untuk Android
      final androidPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        // Buat channel untuk notifikasi penting
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            'Notifikasi Penting',
            description: 'Channel ini digunakan untuk notifikasi penting',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          ),
        );

        // Buat channel untuk notifikasi task
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_notification_channel',
            'Notifikasi Task',
            description: 'Notifikasi untuk pembaruan task',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
            enableLights: true,
            ledColor: Color(0xFF50C878),
          ),
        );

        // Buat channel untuk pengingat task
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_reminder_channel',
            'Pengingat Task',
            description: 'Notifikasi pengingat untuk task',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
            showBadge: true,
            enableLights: true,
            ledColor: Color(0xFFFFA500),
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Minta izin notifikasi
  Future<bool?> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iOSImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      return await iOSImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final notificationEnabled =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
      if (!notificationEnabled) {
        return await flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      }
      return notificationEnabled;
    } else {
      return false;
    }
  }

  // Tampilkan notifikasi
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    String channelId = 'task_notification_channel',
    String channelName = 'Notifikasi Task',
  }) async {
    try {
      // Konfigurasi untuk Android
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifikasi untuk pembaruan task',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(body),
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        showWhen: true,
        autoCancel: true,
        ongoing: false,
        ticker: 'Notifikasi baru',
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF50C878),
      );

      // Konfigurasi untuk iOS
      final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        sound: 'default',
        badgeNumber: 1,
      );

      // Gabungkan konfigurasi
      final notificationDetails = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Tampilkan notifikasi
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Batalkan notifikasi
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      // Abaikan error jika notifikasi tidak ditemukan
    }
  }

  // Kirim notifikasi FCM
  Future<void> sendFCMNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    String? taskId,
    String? taskName,
  }) async {
    try {
      // Kirim notifikasi ke setiap user
      for (String userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final String? fcmToken = userDoc.data()?['fcmToken'];

        if (fcmToken != null) {
          // Simpan pesan FCM ke Firestore
          await _firestore.collection('fcm_messages').add({
            'token': fcmToken,
            'notification': {'title': title, 'body': body},
            'data': {'type': type, 'taskId': taskId, 'taskName': taskName},
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Jadwalkan notifikasi task
  Future<void> scheduleTaskNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int notificationId,
  }) async {
    try {
      // Konversi waktu ke timezone Jakarta
      final jakarta = tz.getLocation('Asia/Jakarta');
      final scheduledTimeZone = tz.TZDateTime.from(scheduledTime, jakarta);
      final now = tz.TZDateTime.now(jakarta);

      // Abaikan jika waktu sudah lewat
      if (scheduledTimeZone.isBefore(now)) {
        return;
      }

      // Konfigurasi untuk Android
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'task_notification_channel',
        'Notifikasi Task',
        channelDescription: 'Notifikasi untuk pembaruan task',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          summaryText: title,
        ),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        enableVibration: true,
        playSound: true,
        showWhen: true,
        autoCancel: true,
        ongoing: false,
      );

      // Konfigurasi untuk iOS
      final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      // Gabungkan konfigurasi
      final notificationDetails = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Batalkan notifikasi lama jika ada
      try {
        await flutterLocalNotificationsPlugin.cancel(notificationId);
      } catch (e) {}

      // Periksa waktu lagi
      final scheduledTimeMillis = scheduledTimeZone.millisecondsSinceEpoch;
      final nowMillis = now.millisecondsSinceEpoch;

      if (scheduledTimeMillis <= nowMillis) {
        return;
      }

      // Jadwalkan notifikasi baru
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTimeZone,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      rethrow;
    }
  }
}
