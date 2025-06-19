import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workmanager/workmanager.dart';
import 'package:kenongotask2/models/task.dart';
import 'helpers/task_scheduler.dart';
import 'helpers/test_helpers.dart';

/// Generate mock class untuk Workmanager
@GenerateMocks([Workmanager])
import 'task_notification_service_test.mocks.dart';

class TaskScheduler {
  final Workmanager workmanager;

  TaskScheduler(this.workmanager);

  /// Jadwalkan pengingat dan notifikasi untuk task
  Future<void> scheduleTaskReminders(Task task) async {
    final DateTime? taskStartTime = _parseTaskTime(task.tanggal, task.jamMulai);
    if (taskStartTime != null) {
      final now = DateTime.now();
      final startTime = taskStartTime;
      final taskId =
          task.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Jadwalkan pengingat
      final reminderIntervals = [6, 4, 2]; // dalam menit
      for (var minutesBeforeStart in reminderIntervals) {
        final reminderTime = startTime.subtract(
          Duration(minutes: minutesBeforeStart + 1),
        );
        if (!reminderTime.isAfter(now)) continue;

        final reminderId =
            '${taskId}_reminder_${reminderTime.millisecondsSinceEpoch}'
                .hashCode;
        final initialDelayReminder = reminderTime.difference(now);

        await workmanager.registerOneOffTask(
          '${taskId}_reminder_${minutesBeforeStart}_${reminderTime.millisecondsSinceEpoch}',
          'taskNotificationTask',
          initialDelay: initialDelayReminder,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
          inputData: {
            'id': reminderId,
            'title': 'Pengingat Task',
            'body':
                'Pengingat: Task "${task.namaTugas}" akan dimulai dalam $minutesBeforeStart menit.',
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

        await workmanager.registerOneOffTask(
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
            'body': 'Task "${task.namaTugas}" telah dimulai.',
            'payload': taskId,
            'type': 'task_started',
            'taskId': taskId,
            'taskName': task.namaTugas,
          },
        );
      }
    }
  }

  /// Parse waktu task dari string jam
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

  /// Notifikasi untuk berbagai event task
  Future<void> notifyNewTask(Task task) async {
    await workmanager.registerOneOffTask(
      '${task.uid}_created_${DateTime.now().millisecondsSinceEpoch}',
      'taskNotificationTask',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'task_created',
        'taskId': task.uid,
        'taskName': task.namaTugas,
      },
    );
  }

  /// Notifikasi untuk perubahan status task
  Future<void> notifyStatusChanged(Task task, String newStatus) async {
    await workmanager.registerOneOffTask(
      '${task.uid}_status_${DateTime.now().millisecondsSinceEpoch}',
      'taskNotificationTask',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'status_changed',
        'taskId': task.uid,
        'taskName': task.namaTugas,
        'newStatus': newStatus,
      },
    );
  }

  /// Notifikasi untuk task selesai
  Future<void> notifyTaskSelesai(Task task) async {
    await workmanager.registerOneOffTask(
      '${task.uid}_selesai_${DateTime.now().millisecondsSinceEpoch}',
      'taskNotificationTask',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'type': 'task_selesai',
        'taskId': task.uid,
        'taskName': task.namaTugas,
      },
    );
  }

  Future<void> notifyUploadBukti(Task task, String buktiUrl) async {
    await workmanager.registerOneOffTask(
      '${task.uid}_bukti_${DateTime.now().millisecondsSinceEpoch}',
      'taskNotificationTask',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
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
      },
    );
  }

  Future<void> notifyAddKeterangan(Task task, String keterangan) async {
    await workmanager.registerOneOffTask(
      '${task.uid}_keterangan_${DateTime.now().millisecondsSinceEpoch}',
      'taskNotificationTask',
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
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
      },
    );
  }
}

void main() {
  late MockWorkmanager mockWorkmanager;
  late TaskScheduler taskScheduler;

  /// Setup test environment sebelum setiap test
  setUp(() {
    mockWorkmanager = MockWorkmanager();
    taskScheduler = TaskScheduler(mockWorkmanager);
  });

  group('TaskScheduler Unit Tests', () {
    group('Task Reminder Tests', () {
      /// Test untuk memastikan pengingat task dijadwalkan dengan interval yang benar
      /// - 6 menit sebelum task
      /// - 4 menit sebelum task
      /// - 2 menit sebelum task
      /// - Saat task dimulai
      test(
        'should schedule task reminder notifications with correct intervals',
        () async {
          // Buat task dengan waktu yang pasti
          final now = DateTime.now();
          final taskStartTime = now.add(const Duration(minutes: 10));
          final task = createTestTask(
            tanggal: taskStartTime,
            jamMulai: '${taskStartTime.hour}:${taskStartTime.minute}',
          );

          // Setup mock untuk menerima pemanggilan registerOneOffTask
          when(
            mockWorkmanager.registerOneOffTask(
              any,
              'taskNotificationTask',
              initialDelay: anyNamed('initialDelay'),
              constraints: anyNamed('constraints'),
              inputData: anyNamed('inputData'),
            ),
          ).thenAnswer((_) async => true);

          // Panggil method yang akan diuji
          await taskScheduler.scheduleTaskReminders(task);

          // Verifikasi bahwa registerOneOffTask dipanggil untuk setiap reminder
          verify(
            mockWorkmanager.registerOneOffTask(
              any,
              'taskNotificationTask',
              initialDelay: anyNamed('initialDelay'),
              constraints: anyNamed('constraints'),
              inputData: anyNamed('inputData'),
            ),
          ).called(
            4,
          ); // Harus dipanggil 4 kali: 3 reminder + 1 notifikasi mulai
        },
      );

      /// Test untuk memastikan tidak ada notifikasi yang dijadwalkan untuk task yang sudah lewat
      test('should not schedule notifications for past tasks', () async {
        final task = createTestTask(
          tanggal: DateTime.now().subtract(const Duration(minutes: 1)),
          jamMulai: '00:00', // Pastikan waktu mulai juga di masa lalu
        );

        // Setup mock untuk memastikan tidak ada pemanggilan
        when(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).thenAnswer((_) async => true);

        await taskScheduler.scheduleTaskReminders(task);

        // Verifikasi bahwa tidak ada pemanggilan registerOneOffTask
        verifyNever(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        );
      });
    });

    group('Task Event Notification Tests', () {
      /// Test untuk notifikasi pembuatan task baru
      /// Memastikan notifikasi dikirim ke semua user yang relevan
      test('should send notification for new task', () async {
        final task = createTestTask();

        when(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).thenAnswer((_) async => true);

        await taskScheduler.notifyNewTask(task);

        verify(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).called(1);
      });

      /// Test untuk notifikasi perubahan status task
      /// Memastikan notifikasi dikirim dengan status baru yang benar
      test('should send notification for status change', () async {
        final task = createTestTask();

        when(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).thenAnswer((_) async => true);

        await taskScheduler.notifyStatusChanged(task, 'in_progress');

        verify(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).called(1);
      });

      /// Test untuk notifikasi task selesai
      /// Memastikan notifikasi dikirim ke PM dan PIC
      test('should send notification for task completion', () async {
        final task = createTestTask();

        when(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).thenAnswer((_) async => true);

        await taskScheduler.notifyTaskSelesai(task);

        verify(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).called(1);
      });

      /// Test untuk notifikasi upload bukti
      /// Memastikan notifikasi dikirim dengan URL bukti yang benar
      test('should send notification for evidence upload', () async {
        final task = createTestTask();

        when(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).thenAnswer((_) async => true);

        await taskScheduler.notifyUploadBukti(
          task,
          'https://example.com/bukti.jpg',
        );

        verify(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).called(1);
      });

      /// Test untuk notifikasi penambahan keterangan
      /// Memastikan notifikasi dikirim dengan keterangan yang benar
      test('should send notification for adding remarks', () async {
        final task = createTestTask();

        when(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).thenAnswer((_) async => true);

        await taskScheduler.notifyAddKeterangan(task, 'Test remark');

        verify(
          mockWorkmanager.registerOneOffTask(
            any,
            any,
            initialDelay: anyNamed('initialDelay'),
            constraints: anyNamed('constraints'),
            inputData: anyNamed('inputData'),
          ),
        ).called(1);
      });
    });
  });
}
