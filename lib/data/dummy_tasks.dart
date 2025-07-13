import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenongotask2/models/task.dart';
import 'package:kenongotask2/services/task_notification_service.dart';
import 'package:kenongotask2/services/image_service.dart';
import 'dart:io';

List<Task> dummyTasks = [];

final taskNotificationService = TaskNotificationService();

Future<String?> addTask(Task task) async {
  try {
    final docRef = await FirebaseFirestore.instance.collection('tasks').add({
      'namaTugas': task.namaTugas,
      'tanggal': Timestamp.fromDate(task.tanggal),
      'jamMulai': task.jamMulai,
      'jamSelesai': task.jamSelesai,
      'namaPM': task.namaPM,
      'pic': task.pic,
      'vendor': task.vendor,
      'status': 'waiting approval', // Status default untuk approval PM
    });

    // Trigger notifikasi task baru ke PIC
    final createdTask = Task(
      uid: docRef.id,
      namaTugas: task.namaTugas,
      tanggal: task.tanggal,
      jamMulai: task.jamMulai,
      jamSelesai: task.jamSelesai,
      namaPM: task.namaPM,
      pic: task.pic,
      vendor: task.vendor,
      status: 'waiting approval',
    );

    final taskNotificationService = TaskNotificationService();
    // Hanya kirim notifikasi approval, notifikasi task baru akan dikirim setelah approval
    await taskNotificationService.notifyNeedApprovalPM(createdTask);

    return docRef.id;
  } catch (e) {
    print('Error adding task: $e');
    return null;
  }
}

Future<void> setStatus(
  String taskId,
  String status, {
  String? previousStatus,
}) async {
  try {
    // Ambil task terlebih dahulu untuk validasi
    final taskDoc =
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

    if (!taskDoc.exists) {
      print('Task tidak ditemukan');
      return;
    }

    final currentTask = Task.fromFirestore(taskDoc);

    // Validasi: Task yang sudah "done" tidak bisa diubah statusnya
    if (currentTask.status == 'done') {
      print('Task yang sudah selesai tidak dapat diubah statusnya');
      return;
    }

    // Update status
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': status,
    });

    // Ambil task yang sudah diupdate untuk notifikasi
    final updatedTaskDoc =
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

    if (updatedTaskDoc.exists) {
      final task = Task.fromFirestore(updatedTaskDoc);
      final taskNotificationService = TaskNotificationService();

      // Trigger notifikasi hanya untuk status tertentu
      if (status == 'done') {
        await taskNotificationService.notifyTaskValidatedByPM(task);
      } else if (status == 'waiting approval') {
        await taskNotificationService.notifyNeedApprovalPM(task);
      } else if (status == 'not complete' &&
          previousStatus == 'waiting approval') {
        // Notifikasi task siap dikerjakan setelah PM approve
        await taskNotificationService.notifyTaskApprovedByPM(task);
      } else if (status == 'not complete' && previousStatus == 'pending') {
        // Notifikasi saat PM menolak task (dari pending ke not complete)
        await taskNotificationService.notifyTaskRejectedByPM(task);
      }
      // Tidak ada notifikasi untuk status 'pending' (upload bukti)
    }
  } catch (e) {
    print('Error setting status: $e');
  }
}

Stream<List<Task>> getTasksStream(DateTime selectedDate) {
  final startOfDay = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    0,
    0,
    0,
  );

  final endOfDay = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day + 1,
    0,
    0,
    0,
  );

  return FirebaseFirestore.instance
      .collection('tasks')
      .where('tanggal', isGreaterThanOrEqualTo: startOfDay)
      .where('tanggal', isLessThan: endOfDay)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
      );
}

Future<void> updateTaskBukti(
  String taskId,
  String imageUrl,
  String keterangan,
) async {
  try {
    // Ambil task terlebih dahulu untuk validasi
    final taskDoc =
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

    if (!taskDoc.exists) {
      print('Task tidak ditemukan');
      return;
    }

    final currentTask = Task.fromFirestore(taskDoc);

    // Validasi: Task yang sudah "done" tidak bisa diubah buktinya
    if (currentTask.status == 'done') {
      print('Task yang sudah selesai tidak dapat diubah buktinya');
      return;
    }

    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'bukti': imageUrl,
      'keterangan': keterangan,
    });
    final taskNotificationService = TaskNotificationService();
    final taskSnapshot =
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
    if (taskSnapshot.exists) {
      final updatedTask = Task.fromFirestore(taskSnapshot);
      await taskNotificationService.notifyUploadBukti(updatedTask, imageUrl);
    }
  } catch (e) {
    rethrow;
  }
}

Future<void> updateTaskKeterangan(String taskId, String keterangan) async {
  try {
    // Ambil task terlebih dahulu untuk validasi
    final taskDoc =
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

    if (!taskDoc.exists) {
      print('Task tidak ditemukan');
      return;
    }

    final currentTask = Task.fromFirestore(taskDoc);

    // Validasi: Task yang sudah "done" tidak bisa diubah keterangannya
    if (currentTask.status == 'done') {
      return;
    }

    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'keterangan': keterangan,
    });

    // Trigger notifikasi penambahan keterangan
    final taskNotificationService = TaskNotificationService();
    final taskSnapshot =
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
    if (taskSnapshot.exists) {
      final updatedTask = Task.fromFirestore(taskSnapshot);
      await taskNotificationService.notifyAddKeterangan(
        updatedTask,
        keterangan,
      );
    }
  } catch (e) {
    rethrow;
  }
}

// Fungsi-fungsi helper untuk update status dan notifikasi sudah tidak diperlukan
// PM dan PIC menggunakan setStatus biasa untuk mengubah status
