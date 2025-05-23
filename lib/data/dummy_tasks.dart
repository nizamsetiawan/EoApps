import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenongotask2/models/task.dart';
import 'package:kenongotask2/services/task_notification_service.dart';
import 'package:kenongotask2/services/image_service.dart';
import 'dart:io';

// List dummyTasks untuk menyimpan tugas-tugas
List<Task> dummyTasks = [];

final taskNotificationService = TaskNotificationService();

// Fungsi untuk menambah tugas baru
// void addTask(Task task) {
//   dummyTasks.add(task);
// }

Future<String?> addTask(Task task) async {
  try {
    final docRef = await FirebaseFirestore.instance.collection('tasks').add({
      'namaTugas': task.namaTugas,
      'tanggal': Timestamp.fromDate(task.tanggal),
      'jamMulai': task.jamMulai,
      'jamSelesai': task.jamSelesai,
      'namaPM': task.namaPM,
      'pic': task.pic,
      'status': task.status,
    });

    return docRef.id;
  } catch (e) {
    return null;
  }
}

// Future<List<Task>> getTasks(DateTime selectedDate) async {
//   try {
//     final querySnapshot =
//         await FirebaseFirestore.instance
//             .collection('tasks')
//             .where(
//               'tanggal',
//               isGreaterThanOrEqualTo: DateTime(
//                 selectedDate.year,
//                 selectedDate.month,
//                 selectedDate.day,
//                 0,
//                 0,
//                 0,
//               ),
//             )
//             .where(
//               'tanggal',
//               isLessThan: DateTime(
//                 selectedDate.year,
//                 selectedDate.month,
//                 selectedDate.day + 1,
//                 0,
//                 0,
//                 0,
//               ),
//             )
//             .get();

//     return querySnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
//   } catch (e) {
//     print("Error saat mengambil task: $e");
//     return [];
//   }
// }

Future<void> setStatus(String selectedTask, String newStatus) async {
  try {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(selectedTask)
        .update({'status': newStatus});

    final taskNotificationService = TaskNotificationService();
    final taskSnapshot =
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(selectedTask)
            .get();
    if (taskSnapshot.exists) {
      final updatedTask = Task.fromFirestore(taskSnapshot);
      await taskNotificationService.notifyStatusChanged(updatedTask, newStatus);
      if (newStatus == 'done') {
        await taskNotificationService.notifyTaskSelesai(updatedTask);
      }
    }
  } catch (e) {
    rethrow;
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
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'keterangan': keterangan,
    });
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
