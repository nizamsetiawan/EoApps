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
        print('Waktu sekarang: $now');
        print('Waktu mulai task: $startTime');
        final taskId =
            task.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

        // Format jam sekarang
        final currentTimeFormatted = DateFormat('HH:mm').format(now);

        // Send immediate notification for task creation
        await _notificationService.showNotification(
          id: taskId.hashCode + 1000000,
          title: 'Task Baru Dibuat',
          body:
              'Task "${task.namaTugas}" dibuat pada $currentTimeFormatted, dijadwalkan mulai ${task.jamMulai} tanggal ${task.tanggal.toString().split(' ')[0]}',
          payload: taskId,
        );

        // Save task creation notification to Firestore for both PM and PIC
        await _saveNotificationToFirestore(
          userIds: [task.namaPM, task.pic],
          title: 'Task Baru Dibuat',
          body:
              'Task "${task.namaTugas}" dibuat pada $currentTimeFormatted, dijadwalkan mulai ${task.jamMulai} tanggal ${task.tanggal.toString().split(' ')[0]}',
          type: 'task_created',
          taskId: taskId,
          taskName: task.namaTugas,
        );

        // Schedule reminders every 2 minutes before start time
        // Jadwalkan 3 pengingat: 6 menit, 4 menit, dan 2 menit sebelum mulai
        final reminderIntervals = [6, 4, 2]; // Menit sebelum task dimulai

        for (var minutesBeforeStart in reminderIntervals) {
          final reminderTime = startTime.subtract(
            Duration(minutes: minutesBeforeStart),
          );

          if (!reminderTime.isAfter(now)) {
            print(
              'Melewati pengingat untuk waktu: $reminderTime (sudah lewat)',
            );
            continue;
          }
          print('Menjadwalkan pengingat untuk: $reminderTime');

          // Gunakan satu ID untuk setiap waktu pengingat
          final reminderId =
              '${taskId}_reminder_${reminderTime.millisecondsSinceEpoch}'
                  .hashCode;

          // Hitung delay untuk Workmanager
          final initialDelayReminder = reminderTime.difference(now);

          // Jadwalkan task pengingat dengan Workmanager
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
            // Optional: add constraints if needed, e.g., networkType
            // constraints: Constraints(networkType: NetworkType.connected),
          );

          // Save reminder notification to Firestore for both PM and PIC
        }

        final startId = '${taskId}_start'.hashCode;

        // Task Dimulai (scheduled only)
        if (startTime.isAfter(now)) {
          print('Menjadwalkan notifikasi mulai task untuk: $startTime');

          // Hitung delay untuk Workmanager
          final initialDelayStart = startTime.difference(now);

          // Jadwalkan task task dimulai dengan Workmanager
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
            // Optional: add constraints if needed
            // constraints: Constraints(networkType: NetworkType.connected),
          );

          // Notifikasi task dimulai akan disimpan ke Firestore saat workmanager dijalankan
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
      print('Attempting to save notification to Firestore...');
      print('User IDs being saved: $userIds');
      print('Notification type being saved: $type');
      print('Notification title being saved: $title');
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

  // Notifikasi perubahan status
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

  // Notifikasi tambah keterangan
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

  // Notifikasi upload bukti
  Future<void> notifyUploadBukti(Task task, String buktiUrl) async {
    final notificationId =
        '${task.uid}_bukti_${DateTime.now().millisecondsSinceEpoch}'.hashCode;
    print('Mengirim notifikasi bukti diunggah untuk task: ${task.namaTugas}');
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
    print('Notifikasi bukti diunggah berhasil disimpan ke Firestore');
  }

  // Notifikasi task selesai
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

  // Method yang dipanggil dari Workmanager untuk memproses dan menyimpan notifikasi terjadwal
  Future<void> processScheduledNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      print('Processing scheduled notification with data: $notificationData');

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
        // Tampilkan notifikasi di layar
        print(
          'Attempting to show notification: ID=$id, Title=$title, Body=$body, Payload=$payload',
        );
        await _notificationService.showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload ?? '',
        );

        print('showNotification successful for ID: $id');

        // Simpan notifikasi ke Firestore
        await _saveNotificationToFirestore(
          userIds: userIds,
          title: title,
          body: body,
          type: type,
          taskId: taskId,
          taskName: taskName,
        );
        print(
          'Notifikasi background berhasil ditampilkan dan disimpan ke Firestore',
        );
      } else {
        print('Data notifikasi background tidak lengkap atau tidak valid');
        // Log data yang tidak valid untuk debugging
        print(
          'Invalid data received: ID=$id, Title=$title, Body=$body, UserIds=$userIds, Type=$type',
        );
      }
    } catch (e) {
      print('Error processing scheduled notification in background: $e');
      rethrow;
    }
  }
}
