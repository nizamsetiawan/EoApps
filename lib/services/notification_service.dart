import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:async';
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      await requestPermissions();

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

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            selectNotificationStream.add(payload);
          }
        },
      );

      final androidPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_notification_channel',
            'Task Notifications',
            description: 'Notifications for task updates',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          ),
        );
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      // Handle initialization error silently
    }
  }

  Future<bool> _isAndroidPermissionGranted() async {
    return await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled() ??
        false;
  }

  Future<bool> _requestAndroidNotificationsPermission() async {
    return await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        false;
  }

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
      final notificationEnabled = await _isAndroidPermissionGranted();
      if (!notificationEnabled) {
        return await _requestAndroidNotificationsPermission();
      }
      return notificationEnabled;
    } else {
      return false;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    String channelId = "task_notification_channel",
    String channelName = "Task Notifications",
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(body),
    );

    final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      // Handle notification error silently
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
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
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
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
    try {
      final now = DateTime.now();
      final scheduledTimeZone = tz.TZDateTime.from(
        scheduledTime,
        tz.getLocation('Asia/Jakarta'),
      );

      final finalScheduledTime =
          scheduledTimeZone.isBefore(
                tz.TZDateTime.now(tz.getLocation('Asia/Jakarta')),
              )
              ? tz.TZDateTime.now(
                tz.getLocation('Asia/Jakarta'),
              ).add(Duration(minutes: 1))
              : scheduledTimeZone;

      var currentTime = tz.TZDateTime.now(tz.getLocation('Asia/Jakarta'));
      var notificationCount = 1;

      while (currentTime.isBefore(finalScheduledTime)) {
        final minutesLeft =
            finalScheduledTime.difference(currentTime).inMinutes;
        String timeMessage;
        if (minutesLeft >= 60) {
          final hours = minutesLeft ~/ 60;
          final minutes = minutesLeft % 60;
          timeMessage =
              hours > 0
                  ? '$hours jam ${minutes > 0 ? '$minutes menit' : ''} lagi'
                  : '$minutes menit lagi';
        } else {
          timeMessage = '$minutesLeft menit lagi';
        }

        await flutterLocalNotificationsPlugin.zonedSchedule(
          '${taskId}_reminder_$notificationCount'.hashCode,
          'Pengingat Tugas',
          'Tugas "$title" akan dimulai dalam $timeMessage',
          currentTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'task_notification_channel',
              'Notifikasi Tugas',
              channelDescription: 'Notifikasi untuk pembaruan tugas',
              importance: Importance.max,
              priority: Priority.max,
              styleInformation: BigTextStyleInformation(
                'Tugas "$title" akan dimulai dalam $timeMessage',
                htmlFormatBigText: true,
                contentTitle: 'Pengingat Tugas',
                summaryText: 'Pengingat Tugas',
              ),
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
              enableVibration: true,
              playSound: true,
              showWhen: true,
              autoCancel: false,
              ongoing: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        currentTime = currentTime.add(const Duration(minutes: 2));
        notificationCount++;
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        taskId.hashCode,
        'Tugas Dimulai',
        'Tugas "$title" dimulai sekarang!',
        finalScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_notification_channel',
            'Notifikasi Tugas',
            channelDescription: 'Notifikasi untuk pembaruan tugas',
            importance: Importance.max,
            priority: Priority.max,
            styleInformation: BigTextStyleInformation(
              'Tugas "$title" dimulai sekarang!',
              htmlFormatBigText: true,
              contentTitle: 'Tugas Dimulai',
              summaryText: 'Tugas Dimulai',
            ),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            enableVibration: true,
            playSound: true,
            showWhen: true,
            autoCancel: false,
            ongoing: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Handle scheduling error silently
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
