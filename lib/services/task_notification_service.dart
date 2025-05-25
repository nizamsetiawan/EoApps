import '../models/task.dart';
import 'notification_service.dart';
import 'fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  // Get all users with relevant roles (PM, PIC, Admin)
  Future<List<String>> _getRelevantUserIds() async {
    try {
      final usersQuery = await _firestore.collection('users').get();
      return usersQuery.docs
          .where((doc) {
            final role = doc.data()['role'] as String?;
            return role == 'pm' || role == 'pic' || role == 'admin';
          })
          .map((doc) => doc.id)
          .toList();
    } catch (e) {
      print('Error getting relevant user IDs: $e');
      return [];
    }
  }

  // Get first valid FCM token from relevant users
  Future<Map<String, String?>> _getValidFCMToken() async {
    try {
      final usersQuery = await _firestore.collection('users').get();
      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        final role = userData['role'] as String?;

        // Skip if user role is not relevant
        if (role != 'pm' && role != 'pic' && role != 'admin') {
          continue;
        }

        final fcmToken = userData['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          return {'userId': doc.id, 'token': fcmToken};
        }
      }
      return {'userId': null, 'token': null};
    } catch (e) {
      print('Error getting valid FCM token: $e');
      return {'userId': null, 'token': null};
    }
  }

  // Send FCM notification to all relevant users
  Future<void> _sendFCMToUsers({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('Sending notification to all relevant roles');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');

      // Get all tokens for all roles
      final roleTokens = await _fcmService.getAllTokens();
      print('Retrieved tokens by role: $roleTokens');

      // Collect all user IDs for Firestore notification
      List<String> allUserIds = [];

      // Send to all tokens
      for (var role in roleTokens.keys) {
        for (var tokenData in roleTokens[role]!) {
          final token = tokenData['token'] as String;
          final email = tokenData['email'] as String?;
          final userId = tokenData['userId'] as String;
          allUserIds.add(userId);

          print('Sending to role $role, email $email, userId $userId');
          final success = await FCMService.sendNotification(
            token: token,
            title: title,
            body: body,
            data: {...data, 'role': role, 'email': email, 'userId': userId},
          );

          if (success) {
            print('Successfully sent notification to $role with email $email');
          } else {
            print('Failed to send notification to $role with email $email');
          }
        }
      }

      // Save notification to Firestore
      await _firestore.collection('notifications').add({
        'userIds': allUserIds,
        'title': title,
        'body': body,
        'type': data['type'],
        'taskId': data['taskId'],
        'taskName': data['taskName'],
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('Notification saved to Firestore for users: $allUserIds');
    } catch (e) {
      print('Error sending FCM to users: $e');
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    String? taskId,
    String? taskName,
  }) async {
    try {
      final notificationData = {
        'userIds': userIds,
        'title': title,
        'body': body,
        'type': type,
        'taskId': taskId,
        'taskName': taskName,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  // Notify new task
  Future<void> notifyNewTask(Task task) async {
    try {
      final taskStartTime = _parseTaskTime(task.tanggal, task.jamMulai);
      if (taskStartTime != null) {
        final now = DateTime.now();
        final startTime = taskStartTime;
        final taskId =
            task.uid ?? DateTime.now().millisecondsSinceEpoch.toString();
        final currentTimeFormatted = DateFormat('HH:mm').format(now);

        // Show local notification
        await _notificationService.showNotification(
          id: taskId.hashCode + 1000000,
          title: 'Task Baru Dibuat',
          body:
              'Task "${task.namaTugas}" dibuat pada $currentTimeFormatted, dijadwalkan mulai ${task.jamMulai} tanggal ${task.tanggal.toString().split(' ')[0]}',
          payload: taskId,
        );

        // Send FCM notification
        await _sendFCMToUsers(
          title: 'Task Baru Dibuat',
          body:
              'Task "${task.namaTugas}" dibuat pada $currentTimeFormatted, dijadwalkan mulai ${task.jamMulai} tanggal ${task.tanggal.toString().split(' ')[0]}',
          data: {
            'type': 'task_created',
            'taskId': taskId,
            'taskName': task.namaTugas,
          },
        );

        // Schedule reminders
        final reminderIntervals = [6, 4, 2];
        for (var minutesBeforeStart in reminderIntervals) {
          final reminderTime = startTime.subtract(
            Duration(minutes: minutesBeforeStart),
          );
          if (!reminderTime.isAfter(now)) continue;

          final reminderId =
              '${taskId}_reminder_${reminderTime.millisecondsSinceEpoch}'
                  .hashCode;
          final initialDelayReminder = reminderTime.difference(now);

          await Workmanager().registerOneOffTask(
            '${taskId}_reminder_${minutesBeforeStart}_${reminderTime.millisecondsSinceEpoch}',
            'taskNotificationTask',
            initialDelay: initialDelayReminder,
            inputData: {
              'id': reminderId,
              'title': 'Pengingat Task',
              'body':
                  'Task "${task.namaTugas}" akan dimulai dalam $minutesBeforeStart menit.',
              'payload': taskId,
              'type': 'reminder',
              'taskId': taskId,
              'taskName': task.namaTugas,
            },
          );
        }

        // Schedule start notification
        if (startTime.isAfter(now)) {
          final startId = '${taskId}_start'.hashCode;
          final initialDelayStart = startTime.difference(now);

          await Workmanager().registerOneOffTask(
            '${taskId}_start_${startTime.millisecondsSinceEpoch}',
            'taskNotificationTask',
            initialDelay: initialDelayStart,
            inputData: {
              'id': startId,
              'title': 'Task Dimulai',
              'body':
                  'Task "${task.namaTugas}" DIMULAI SEKARANG! (${task.jamMulai})',
              'payload': taskId,
              'type': 'task_started',
              'taskId': taskId,
              'taskName': task.namaTugas,
            },
          );
        }
      }
    } catch (e) {
      print('Error in notifyNewTask: $e');
    }
  }

  // Notify status changed
  Future<void> notifyStatusChanged(Task task, String newStatus) async {
    try {
      final notificationId =
          '${task.uid}_status_${DateTime.now().millisecondsSinceEpoch}'
              .hashCode;

      // Show local notification
      await _notificationService.showNotification(
        id: notificationId,
        title: 'Status Task Berubah',
        body: 'Status task "${task.namaTugas}" berubah menjadi "$newStatus"',
        payload: task.uid ?? '',
      );

      // Send FCM notification
      await _sendFCMToUsers(
        title: 'Status Task Berubah',
        body: 'Status task "${task.namaTugas}" berubah menjadi "$newStatus"',
        data: {
          'type': 'status_changed',
          'taskId': task.uid ?? '',
          'taskName': task.namaTugas,
          'newStatus': newStatus,
        },
      );
    } catch (e) {
      print('Error in notifyStatusChanged: $e');
    }
  }

  // Notify add keterangan
  Future<void> notifyAddKeterangan(Task task, String keterangan) async {
    try {
      final notificationId =
          '${task.uid}_keterangan_${DateTime.now().millisecondsSinceEpoch}'
              .hashCode;

      // Show local notification
      await _notificationService.showNotification(
        id: notificationId,
        title: 'Keterangan Ditambahkan',
        body: 'Keterangan pada task "${task.namaTugas}": $keterangan',
        payload: task.uid ?? '',
      );

      // Send FCM notification
      await _sendFCMToUsers(
        title: 'Keterangan Ditambahkan',
        body: 'Keterangan pada task "${task.namaTugas}": $keterangan',
        data: {
          'type': 'add_keterangan',
          'taskId': task.uid ?? '',
          'taskName': task.namaTugas,
          'keterangan': keterangan,
        },
      );
    } catch (e) {
      print('Error in notifyAddKeterangan: $e');
    }
  }

  // Notify upload bukti
  Future<void> notifyUploadBukti(Task task, String buktiUrl) async {
    try {
      final notificationId =
          '${task.uid}_bukti_${DateTime.now().millisecondsSinceEpoch}'.hashCode;

      // Show local notification
      await _notificationService.showNotification(
        id: notificationId,
        title: 'Bukti Diunggah',
        body: 'Bukti untuk task "${task.namaTugas}" telah berhasil diunggah.',
        payload: task.uid ?? '',
      );

      // Send FCM notification
      await _sendFCMToUsers(
        title: 'Bukti Diunggah',
        body: 'Bukti untuk task "${task.namaTugas}" telah berhasil diunggah.',
        data: {
          'type': 'upload_bukti',
          'taskId': task.uid ?? '',
          'taskName': task.namaTugas,
          'buktiUrl': buktiUrl,
        },
      );
    } catch (e) {
      print('Error in notifyUploadBukti: $e');
    }
  }

  // Notify task selesai
  Future<void> notifyTaskSelesai(Task task) async {
    try {
      final notificationId =
          '${task.uid}_selesai_${DateTime.now().millisecondsSinceEpoch}'
              .hashCode;

      // Show local notification
      await _notificationService.showNotification(
        id: notificationId,
        title: 'Task Selesai',
        body: 'Task "${task.namaTugas}" telah selesai.',
        payload: task.uid ?? '',
      );

      // Send FCM notification
      await _sendFCMToUsers(
        title: 'Task Selesai',
        body: 'Task "${task.namaTugas}" telah selesai.',
        data: {
          'type': 'task_selesai',
          'taskId': task.uid ?? '',
          'taskName': task.namaTugas,
        },
      );
    } catch (e) {
      print('Error in notifyTaskSelesai: $e');
    }
  }

  // Parse task time
  DateTime? _parseTaskTime(DateTime date, String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  // Process scheduled notification
  Future<void> processScheduledNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final int? id = notificationData['id'] as int?;
      final String? title = notificationData['title'] as String?;
      final String? body = notificationData['body'] as String?;
      final String? payload = notificationData['payload'] as String?;
      final String? type = notificationData['type'] as String?;
      final String? taskId = notificationData['taskId'] as String?;
      final String? taskName = notificationData['taskName'] as String?;

      if (id != null && title != null && body != null && type != null) {
        // Show local notification
        await _notificationService.showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload ?? '',
        );

        // Send FCM notification
        await _sendFCMToUsers(
          title: title,
          body: body,
          data: {
            'type': type,
            'taskId': taskId ?? '',
            'taskName': taskName ?? '',
          },
        );
      }
    } catch (e) {
      print('Error processing scheduled notification: $e');
    }
  }
}
