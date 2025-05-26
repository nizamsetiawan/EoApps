import '../models/task.dart';
import 'fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();
  final Set<String> _processedNotifications = {};

  // Dapatkan semua user dengan role yang relevan (PM, PIC, Admin)
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
      return [];
    }
  }

  // Dapatkan token FCM pertama yang valid dari user yang relevan
  Future<Map<String, String?>> _getValidFCMToken() async {
    try {
      final usersQuery = await _firestore.collection('users').get();
      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        final role = userData['role'] as String?;

        // Lewati jika role tidak relevan
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
      return {'userId': null, 'token': null};
    }
  }

  // Kirim notifikasi FCM ke semua user yang relevan
  Future<void> _sendFCMToUsers({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Buat ID notifikasi unik
      final notificationId =
          '${data['type']}_${data['taskId']}_${DateTime.now().millisecondsSinceEpoch}';

      // Cek apakah notifikasi sudah diproses
      if (_processedNotifications.contains(notificationId)) {
        return;
      }

      // Dapatkan semua token untuk semua role
      final roleTokens = await _fcmService.getAllTokens();

      // Kumpulkan semua ID user untuk notifikasi Firestore
      List<String> allUserIds = [];

      // Kirim ke semua token
      for (var role in roleTokens.keys) {
        for (var tokenData in roleTokens[role]!) {
          final token = tokenData['token'] as String;
          final email = tokenData['email'] as String?;
          final userId = tokenData['userId'] as String;
          allUserIds.add(userId);

          final success = await FCMService.sendNotification(
            token: token,
            title: title,
            body: body,
            data: {...data, 'role': role, 'email': email, 'userId': userId},
          );
        }
      }

      // Simpan notifikasi ke Firestore
      await _firestore.collection('notifications').add({
        'userIds': allUserIds,
        'title': title,
        'body': body,
        'type': data['type'],
        'taskId': data['taskId'],
        'taskName': data['taskName'],
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'notificationId': notificationId,
      });

      // Tambahkan ke notifikasi yang sudah diproses
      _processedNotifications.add(notificationId);
    } catch (e) {}
  }

  // Simpan notifikasi ke Firestore
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
      // Abaikan error
    }
  }

  // Notifikasi task baru
  Future<void> notifyNewTask(Task task) async {
    try {
      final taskStartTime = _parseTaskTime(task.tanggal, task.jamMulai);
      if (taskStartTime != null) {
        final now = DateTime.now();
        final startTime = taskStartTime;
        final taskId =
            task.uid ?? DateTime.now().millisecondsSinceEpoch.toString();
        final currentTimeFormatted = DateFormat('HH:mm').format(now);

        // Kirim notifikasi FCM untuk task baru
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

        // Jadwalkan pengingat
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

          // Jadwalkan notifikasi pengingat
          await Workmanager().registerOneOffTask(
            '${taskId}_reminder_${minutesBeforeStart}_${reminderTime.millisecondsSinceEpoch}',
            'taskNotificationTask',
            initialDelay: initialDelayReminder,
            constraints: Constraints(
              networkType: NetworkType.connected,
              requiresBatteryNotLow: true,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiresStorageNotLow: false,
            ),
            inputData: {
              'id': reminderId,
              'title': 'Pengingat Task',
              'body':
                  'Task "${task.namaTugas}" akan dimulai dalam $minutesBeforeStart menit.',
              'payload': taskId,
              'type': 'reminder',
              'taskId': taskId,
              'taskName': task.namaTugas,
              'minutesBeforeStart': minutesBeforeStart,
            },
          );
        }

        // Jadwalkan notifikasi mulai
        if (startTime.isAfter(now)) {
          final startId = '${taskId}_start'.hashCode;
          final initialDelayStart = startTime.difference(now);

          // Jadwalkan notifikasi mulai
          await Workmanager().registerOneOffTask(
            '${taskId}_start_${startTime.millisecondsSinceEpoch}',
            'taskNotificationTask',
            initialDelay: initialDelayStart,
            constraints: Constraints(
              networkType: NetworkType.connected,
              requiresBatteryNotLow: true,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiresStorageNotLow: false,
            ),
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
      // Abaikan error
    }
  }

  // Notifikasi perubahan status
  Future<void> notifyStatusChanged(Task task, String newStatus) async {
    try {
      final notificationId =
          '${task.uid}_status_${DateTime.now().millisecondsSinceEpoch}'
              .hashCode;

      // Kirim notifikasi FCM
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
      // Abaikan error
    }
  }

  // Notifikasi tambah keterangan
  Future<void> notifyAddKeterangan(Task task, String keterangan) async {
    try {
      final notificationId =
          '${task.uid}_keterangan_${DateTime.now().millisecondsSinceEpoch}'
              .hashCode;

      // Kirim notifikasi FCM
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
      // Abaikan error
    }
  }

  // Notifikasi upload bukti
  Future<void> notifyUploadBukti(Task task, String buktiUrl) async {
    try {
      final notificationId =
          '${task.uid}_bukti_${DateTime.now().millisecondsSinceEpoch}'.hashCode;

      // Kirim notifikasi FCM
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
      // Abaikan error
    }
  }

  // Notifikasi task selesai
  Future<void> notifyTaskSelesai(Task task) async {
    try {
      final notificationId =
          '${task.uid}_selesai_${DateTime.now().millisecondsSinceEpoch}'
              .hashCode;

      // Kirim notifikasi FCM
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
      // Abaikan error
    }
  }

  // Parse waktu task
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

  // Proses notifikasi terjadwal
  Future<void> processScheduledNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final String? title = notificationData['title'] as String?;
      final String? body = notificationData['body'] as String?;
      final String? type = notificationData['type'] as String?;
      final String? taskId = notificationData['taskId'] as String?;
      final String? taskName = notificationData['taskName'] as String?;

      if (title != null && body != null && type != null) {
        // Buat ID notifikasi unik untuk notifikasi terjadwal
        final notificationId =
            '${type}_${taskId}_${DateTime.now().millisecondsSinceEpoch}';

        // Cek apakah notifikasi sudah diproses
        if (_processedNotifications.contains(notificationId)) {
          return;
        }

        // Kirim notifikasi FCM
        await _sendFCMToUsers(
          title: title,
          body: body,
          data: {
            'type': type,
            'taskId': taskId ?? '',
            'taskName': taskName ?? '',
            'notificationId': notificationId,
          },
        );
      }
    } catch (e) {
      // Abaikan error
    }
  }
}
