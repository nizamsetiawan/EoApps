import 'package:kenongotask2/models/task.dart';

/// Helper function untuk membuat objek Task untuk testing
///
/// Parameter yang bisa diatur:
/// - [uid]: ID unik task (default: 'test-uid')
/// - [namaTugas]: Nama task (default: 'Test Task')
/// - [tanggal]: Tanggal task (default: DateTime.now())
/// - [jamMulai]: Waktu mulai task (default: '10:00')
/// - [jamSelesai]: Waktu selesai task (default: '11:00')
/// - [namaPM]: Nama Project Manager (default: 'Test PM')
/// - [pic]: Nama Person In Charge (default: 'Test PIC')
/// - [status]: Status task (default: 'pending')
///
/// Returns Task object dengan nilai default yang bisa digunakan untuk testing
Task createTestTask({
  String? uid,
  String? namaTugas,
  DateTime? tanggal,
  String? jamMulai,
  String? jamSelesai,
  String? namaPM,
  String? pic,
  String? status,
}) {
  return Task(
    uid: uid ?? 'test-uid',
    namaTugas: namaTugas ?? 'Test Task',
    tanggal: tanggal ?? DateTime.now(),
    jamMulai: jamMulai ?? '10:00',
    jamSelesai: jamSelesai ?? '11:00',
    namaPM: namaPM ?? 'Test PM',
    pic: pic ?? 'Test PIC',
    status: status ?? 'pending',
  );
}
