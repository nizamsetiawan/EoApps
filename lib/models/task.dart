import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? uid;
  final String namaTugas;
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String namaPM;
  final String pic;
  final String? vendor;
  String status;
  String? keterangan;
  String? bukti;

  Task({
    required this.uid,
    required this.namaTugas,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.namaPM,
    required this.pic,
    this.vendor,
    required this.status,
    this.keterangan,
    this.bukti,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      uid: doc.id,
      namaTugas: data['namaTugas'] ?? '',
      jamSelesai: data['jamSelesai'] ?? '',
      namaPM: data['namaPM'] ?? '',
      pic: data['pic'],
      vendor: data['vendor'],
      tanggal: (data['tanggal'] as Timestamp).toDate(),
      jamMulai: data['jamMulai'] ?? '',
      status: data['status'] ?? '',
      keterangan: data['keterangan'],
      bukti: data['bukti'],
    );
  }
}
