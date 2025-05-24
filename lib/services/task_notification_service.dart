import '../models/task.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

class TaskNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> notifyNewTask(Task task) async {
    try {
      final taskStartTime = _parseTaskTime(task.tanggal, task.jamMulai);
      if (taskStartTime != null) {
        final now = DateTime.now();
        final startTime = taskStartTime;
        final taskId =
            task.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

        final currentTimeFormatted = DateFormat('HH:mm').format(now);

        await _notificationService.showNotification(
          id: taskId.hashCode + 1000000,
          title: 'Task Baru Dibuat',
          body:
              'Task "${task.namaTugas}" dibuat pada $currentTimeFormatted, dijadwalkan mulai ${task.jamMulai} tanggal ${task.tanggal.toString().split(' ')[0]}',
          payload: taskId,
        );

        await _saveNotificationToFirestore(
          userIds: [task.namaPM, task.pic],
          title: 'Task Baru Dibuat',
          body:
              'Task "${task.namaTugas}" dibuat pada $currentTimeFormatted, dijadwalkan mulai ${task.jamMulai} tanggal ${task.tanggal.toString().split(' ')[0]}',
          type: 'task_created',
          taskId: taskId,
          taskName: task.namaTugas,
        );

        final reminderIntervals = [6, 4, 2];

        for (var minutesBeforeStart in reminderIntervals) {
          final reminderTime = startTime.subtract(
            Duration(minutes: minutesBeforeStart),
          );

          if (!reminderTime.isAfter(now)) {
            continue;
          }

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
              'userIds': [task.namaPM, task.pic],
              'type': 'reminder',
              'taskId': taskId,
              'taskName': task.namaTugas,
            },
          );
        }

        final startId = '${taskId}_start'.hashCode;

        if (startTime.isAfter(now)) {
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
              'userIds': [task.namaPM, task.pic],
              'type': 'task_started',
              'taskId': taskId,
              'taskName': task.namaTugas,
            },
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

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
      rethrow;
    }
  }

  DateTime? _parseTaskTime(DateTime date, String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      if (timeParts.length != 2) {
        return null;
      }
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> notifyStatusChanged(Task task, String newStatus) async {
    final notificationId =
        '${task.uid}_status_${DateTime.now().millisecondsSinceEpoch}'.hashCode;
    await _notificationService.showNotification(
      id: notificationId,
      title: 'Status Task Berubah',
      body: 'Status task "${task.namaTugas}" berubah menjadi "$newStatus"',
      payload: task.uid ?? '',
    );
    await _saveNotificationToFirestore(
      userIds: [task.namaPM, task.pic],
      title: 'Status Task Berubah',
      body: 'Status task "${task.namaTugas}" berubah menjadi "$newStatus"',
      type: 'status_changed',
      taskId: task.uid,
      taskName: task.namaTugas,
    );
  }

  Future<void> notifyAddKeterangan(Task task, String keterangan) async {
    final notificationId =
        '${task.uid}_keterangan_${DateTime.now().millisecondsSinceEpoch}'
            .hashCode;
    await _notificationService.showNotification(
      id: notificationId,
      title: 'Keterangan Ditambahkan',
      body: 'Keterangan pada task "${task.namaTugas}": $keterangan',
      payload: task.uid ?? '',
    );
    await _saveNotificationToFirestore(
      userIds: [task.namaPM, task.pic],
      title: 'Keterangan Ditambahkan',
      body: 'Keterangan pada task "${task.namaTugas}": $keterangan',
      type: 'add_keterangan',
      taskId: task.uid,
      taskName: task.namaTugas,
    );
  }

  Future<void> notifyUploadBukti(Task task, String buktiUrl) async {
    final notificationId =
        '${task.uid}_bukti_${DateTime.now().millisecondsSinceEpoch}'.hashCode;
    await _notificationService.showNotification(
      id: notificationId,
      title: 'Bukti Diunggah',
      body: 'Bukti untuk task "${task.namaTugas}" telah berhasil diunggah.',
      payload: task.uid ?? '',
    );
    await _saveNotificationToFirestore(
      userIds: [task.namaPM, task.pic],
      title: 'Bukti Diunggah',
      body: 'Bukti untuk task "${task.namaTugas}" telah berhasil diunggah.',
      type: 'upload_bukti',
      taskId: task.uid,
      taskName: task.namaTugas,
    );
  }

  Future<void> notifyTaskSelesai(Task task) async {
    final notificationId =
        '${task.uid}_selesai_${DateTime.now().millisecondsSinceEpoch}'.hashCode;
    await _notificationService.showNotification(
      id: notificationId,
      title: 'Task Selesai',
      body: 'Task "${task.namaTugas}" telah selesai.',
      payload: task.uid ?? '',
    );
    await _saveNotificationToFirestore(
      userIds: [task.namaPM, task.pic],
      title: 'Task Selesai',
      body: 'Task "${task.namaTugas}" telah selesai.',
      type: 'task_selesai',
      taskId: task.uid,
      taskName: task.namaTugas,
    );
  }

  Future<void> processScheduledNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final int? id = notificationData['id'] as int?;
      final String? title = notificationData['title'] as String?;
      final String? body = notificationData['body'] as String?;
      final String? payload = notificationData['payload'] as String?;
      final List<String>? userIds =
          (notificationData['userIds'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList();
      final String? type = notificationData['type'] as String?;
      final String? taskId = notificationData['taskId'] as String?;
      final String? taskName = notificationData['taskName'] as String?;

      if (id != null &&
          title != null &&
          body != null &&
          userIds != null &&
          type != null) {
        await _notificationService.showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload ?? '',
        );

        await _saveNotificationToFirestore(
          userIds: userIds,
          title: title,
          body: body,
          type: type,
          taskId: taskId,
          taskName: taskName,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
