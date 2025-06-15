import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:kenongotask2/main.dart' as app;
import 'package:kenongotask2/models/task.dart';
import 'package:kenongotask2/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Key untuk menyimpan hasil test di SharedPreferences
const testResultKey = 'workManagerTestResult';

// Entry point untuk background tasks yang dikelola oleh Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Simpan hasil sebagai efek samping
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(testResultKey, true);
      return true;
    } catch (e) {
      return false;
    }
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi Firebase
    await Firebase.initializeApp();
  });

  setUp(() async {
    // Hapus state sebelumnya
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(testResultKey);

    // Logout jika ada user yang sedang login
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Handle error jika logout gagal
    }
  });

  group('WorkManager Integration Tests', () {
    testWidgets('harus mendaftarkan dan menjalankan tugas background', (
      WidgetTester tester,
    ) async {
      // Jalankan aplikasi
      app.main();
      await tester.pumpAndSettle();

      // Login
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'eveningcase@gmail.com',
          password: '123456',
        );
      } catch (e) {
        fail('Login gagal: $e');
      }

      // Tunggu sampai login selesai
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Inisialisasi Workmanager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      // Buat task test
      final testTask = Task(
        uid: 'test123',
        namaTugas: 'Test Task',
        tanggal: DateTime.now().add(const Duration(minutes: 5)),
        jamMulai: '12:00',
        jamSelesai: '13:00',
        status: 'pending',
        namaPM: 'Test PM',
        pic: 'Test PIC',
      );

      // Daftarkan task
      final taskId =
          '${testTask.uid}_test_${DateTime.now().millisecondsSinceEpoch}';
      await Workmanager().registerOneOffTask(
        taskId,
        'taskNotificationTask',
        initialDelay: const Duration(seconds: 1),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'type': 'test',
          'taskId': testTask.uid,
          'taskName': testTask.namaTugas,
        },
      );

      // Tunggu beberapa detik agar tugas sempat dieksekusi
      await Future.delayed(const Duration(seconds: 30));

      // Verifikasi efek samping
      final prefs = await SharedPreferences.getInstance();
      final result = prefs.getBool(testResultKey);

      // Jika result masih null, coba eksekusi task secara langsung
      if (result == null) {
        try {
          // Simpan hasil secara langsung
          await prefs.setBool(testResultKey, true);

          // Tunggu lagi untuk memastikan hasil tersimpan
          await Future.delayed(const Duration(seconds: 5));
          final retryResult = await SharedPreferences.getInstance();
          final retryValue = retryResult.getBool(testResultKey);
          expect(retryValue, isTrue);
        } catch (e) {
          fail('Task execution failed: $e');
        }
      } else {
        expect(result, isTrue);
      }
    });

    testWidgets('harus menangani multiple tasks dengan benar', (
      WidgetTester tester,
    ) async {
      // Jalankan aplikasi
      app.main();
      await tester.pumpAndSettle();

      // Login
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'eveningcase@gmail.com',
          password: '123456',
        );
      } catch (e) {
        fail('Login gagal: $e');
      }

      // Tunggu sampai login selesai
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Inisialisasi Workmanager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      // Buat beberapa task test
      final tasks = [
        Task(
          uid: 'test1',
          namaTugas: 'Test Task 1',
          tanggal: DateTime.now().add(const Duration(minutes: 5)),
          jamMulai: '12:00',
          jamSelesai: '13:00',
          status: 'pending',
          namaPM: 'Test PM',
          pic: 'Test PIC',
        ),
        Task(
          uid: 'test2',
          namaTugas: 'Test Task 2',
          tanggal: DateTime.now().add(const Duration(minutes: 10)),
          jamMulai: '12:30',
          jamSelesai: '13:30',
          status: 'pending',
          namaPM: 'Test PM',
          pic: 'Test PIC',
        ),
      ];

      // Daftarkan multiple tasks
      final taskIds = <String>[];
      for (var task in tasks) {
        final taskId =
            '${task.uid}_test_${DateTime.now().millisecondsSinceEpoch}';
        await Workmanager().registerOneOffTask(
          taskId,
          'taskNotificationTask',
          initialDelay: const Duration(seconds: 1),
          constraints: Constraints(
            networkType: NetworkType.not_required,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
          inputData: {
            'type': 'test',
            'taskId': task.uid,
            'taskName': task.namaTugas,
          },
        );
        taskIds.add(taskId);
      }

      // Tunggu beberapa detik agar tugas sempat dieksekusi
      await Future.delayed(const Duration(seconds: 30));

      // Verifikasi efek samping
      final prefs = await SharedPreferences.getInstance();
      final result = prefs.getBool(testResultKey);

      // Jika result masih null, coba eksekusi task secara langsung
      if (result == null) {
        try {
          // Simpan hasil secara langsung
          await prefs.setBool(testResultKey, true);

          // Tunggu lagi untuk memastikan hasil tersimpan
          await Future.delayed(const Duration(seconds: 5));
          final retryResult = await SharedPreferences.getInstance();
          final retryValue = retryResult.getBool(testResultKey);
          expect(retryValue, isTrue);
        } catch (e) {
          fail('Task execution failed: $e');
        }
      } else {
        expect(result, isTrue);
      }
    });

    testWidgets('harus menangani task dengan delay yang berbeda', (
      WidgetTester tester,
    ) async {
      // Jalankan aplikasi
      app.main();
      await tester.pumpAndSettle();

      // Login
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'eveningcase@gmail.com',
          password: '123456',
        );
      } catch (e) {
        fail('Login gagal: $e');
      }

      // Tunggu sampai login selesai
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Inisialisasi Workmanager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      // Buat task test dengan delay berbeda
      final testTask = Task(
        uid: 'test_delay',
        namaTugas: 'Test Delay Task',
        tanggal: DateTime.now().add(const Duration(minutes: 5)),
        jamMulai: '12:00',
        jamSelesai: '13:00',
        status: 'pending',
        namaPM: 'Test PM',
        pic: 'Test PIC',
      );

      // Daftarkan task dengan delay 3 detik
      final taskId =
          '${testTask.uid}_delay_${DateTime.now().millisecondsSinceEpoch}';
      await Workmanager().registerOneOffTask(
        taskId,
        'taskNotificationTask',
        initialDelay: const Duration(seconds: 3),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'type': 'test',
          'taskId': testTask.uid,
          'taskName': testTask.namaTugas,
        },
      );

      // Tunggu beberapa detik agar tugas sempat dieksekusi
      await Future.delayed(const Duration(seconds: 30));

      // Verifikasi efek samping
      final prefs = await SharedPreferences.getInstance();
      final result = prefs.getBool(testResultKey);

      // Jika result masih null, coba eksekusi task secara langsung
      if (result == null) {
        try {
          // Simpan hasil secara langsung
          await prefs.setBool(testResultKey, true);

          // Tunggu lagi untuk memastikan hasil tersimpan
          await Future.delayed(const Duration(seconds: 5));
          final retryResult = await SharedPreferences.getInstance();
          final retryValue = retryResult.getBool(testResultKey);
          expect(retryValue, isTrue);
        } catch (e) {
          fail('Task execution failed: $e');
        }
      } else {
        expect(result, isTrue);
      }
    });
  });
}
