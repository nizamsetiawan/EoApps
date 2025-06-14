import 'package:workmanager/workmanager.dart';
import 'package:kenongotask2/models/task.dart';

/// Kelas untuk mengelola penjadwalan notifikasi task
/// Menggunakan Workmanager untuk menjadwalkan notifikasi di background
class TaskScheduler {
  final Workmanager workmanager;

  TaskScheduler(this.workmanager);

  /// Jadwalkan pengingat dan notifikasi untuk task
  ///
  /// Menjadwalkan 4 notifikasi:
  /// 1. 6 menit sebelum task dimulai
  /// 2. 4 menit sebelum task dimulai
  /// 3. 2 menit sebelum task dimulai
  /// 4. Saat task dimulai
  ///
  /// Jika waktu task sudah lewat, tidak ada notifikasi yang dijadwalkan
  Future<void> scheduleTaskReminders(Task task) async {
    final DateTime? taskStartTime = _parseTaskTime(task.tanggal, task.jamMulai);
    if (taskStartTime == null) return;

    final now = DateTime.now();
    if (taskStartTime.isBefore(now)) return;

    // Jadwalkan pengingat 6 menit sebelum task
    final sixMinutesBefore = taskStartTime.subtract(const Duration(minutes: 6));
    if (sixMinutesBefore.isAfter(now)) {
      await workmanager.registerOneOffTask(
        'task_reminder_6m',
        'task_reminder_6m',
        initialDelay: sixMinutesBefore.difference(now),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'type': 'reminder',
          'taskId': task.uid,
          'taskName': task.namaTugas,
          'time': '6 menit',
        },
      );
    }

    // Jadwalkan pengingat 4 menit sebelum task
    final fourMinutesBefore = taskStartTime.subtract(
      const Duration(minutes: 4),
    );
    if (fourMinutesBefore.isAfter(now)) {
      await workmanager.registerOneOffTask(
        'task_reminder_4m',
        'task_reminder_4m',
        initialDelay: fourMinutesBefore.difference(now),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'type': 'reminder',
          'taskId': task.uid,
          'taskName': task.namaTugas,
          'time': '4 menit',
        },
      );
    }

    // Jadwalkan pengingat 2 menit sebelum task
    final twoMinutesBefore = taskStartTime.subtract(const Duration(minutes: 2));
    if (twoMinutesBefore.isAfter(now)) {
      await workmanager.registerOneOffTask(
        'task_reminder_2m',
        'task_reminder_2m',
        initialDelay: twoMinutesBefore.difference(now),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'type': 'reminder',
          'taskId': task.uid,
          'taskName': task.namaTugas,
          'time': '2 menit',
        },
      );
    }

    // Jadwalkan notifikasi saat task dimulai
    await workmanager.registerOneOffTask(
      'task_started',
      'task_started',
      initialDelay: taskStartTime.difference(now),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'task_started',
        'taskId': task.uid,
        'taskName': task.namaTugas,
      },
    );
  }

  /// Parse waktu task dari string jam
  ///
  /// Format waktu yang diharapkan: "HH:mm"
  /// Contoh: "10:00", "14:30"
  ///
  /// Returns null jika format waktu tidak valid
  DateTime? _parseTaskTime(DateTime date, String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Notifikasi untuk berbagai event task
  ///
  /// Mengirim notifikasi ke:
  /// - PM (Project Manager)
  /// - PIC (Person In Charge)
  /// - Admin
  Future<void> notifyNewTask(Task task) async {
    await workmanager.registerOneOffTask(
      'task_created',
      'task_created',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'task_created',
        'taskId': task.uid,
        'taskName': task.namaTugas,
        'pm': task.namaPM,
        'pic': task.pic,
      },
    );
  }

  /// Notifikasi untuk perubahan status task
  ///
  /// Mengirim notifikasi ke:
  /// - PM (Project Manager)
  /// - PIC (Person In Charge)
  /// - Admin
  ///
  /// Status yang valid:
  /// - pending: Task baru dibuat
  /// - in_progress: Task sedang dikerjakan
  /// - completed: Task selesai
  /// - cancelled: Task dibatalkan
  Future<void> notifyStatusChanged(Task task, String newStatus) async {
    await workmanager.registerOneOffTask(
      'status_changed',
      'status_changed',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'status_changed',
        'taskId': task.uid,
        'taskName': task.namaTugas,
        'oldStatus': task.status,
        'newStatus': newStatus,
        'pm': task.namaPM,
        'pic': task.pic,
      },
    );
  }

  /// Notifikasi untuk task selesai
  ///
  /// Mengirim notifikasi ke:
  /// - PM (Project Manager)
  /// - PIC (Person In Charge)
  /// - Admin
  Future<void> notifyTaskSelesai(Task task) async {
    await workmanager.registerOneOffTask(
      'task_selesai',
      'task_selesai',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'task_selesai',
        'taskId': task.uid,
        'taskName': task.namaTugas,
        'pm': task.namaPM,
        'pic': task.pic,
      },
    );
  }

  /// Notifikasi untuk upload bukti
  ///
  /// Mengirim notifikasi ke:
  /// - PM (Project Manager)
  /// - Admin
  ///
  /// [buktiUrl] adalah URL dari bukti yang diupload
  Future<void> notifyUploadBukti(Task task, String buktiUrl) async {
    await workmanager.registerOneOffTask(
      'upload_bukti',
      'upload_bukti',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'upload_bukti',
        'taskId': task.uid,
        'taskName': task.namaTugas,
        'buktiUrl': buktiUrl,
        'pm': task.namaPM,
      },
    );
  }

  /// Notifikasi untuk penambahan keterangan
  ///
  /// Mengirim notifikasi ke:
  /// - PM (Project Manager)
  /// - PIC (Person In Charge)
  /// - Admin
  ///
  /// [keterangan] adalah teks keterangan yang ditambahkan
  Future<void> notifyAddKeterangan(Task task, String keterangan) async {
    await workmanager.registerOneOffTask(
      'add_keterangan',
      'add_keterangan',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'add_keterangan',
        'taskId': task.uid,
        'taskName': task.namaTugas,
        'keterangan': keterangan,
        'pm': task.namaPM,
        'pic': task.pic,
      },
    );
  }
}
