import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kenongotask2/models/task.dart';

class DataClient {
  final String cpw;
  final String cpp;
  final String dekorasi;
  final String mua;
  final String dokumentasi;
  final String catering;
  final String souvenir;
  final String mc;
  final String band;

  DataClient({
    required this.cpw,
    required this.cpp,
    required this.dekorasi,
    required this.mua,
    required this.dokumentasi,
    required this.catering,
    required this.souvenir,
    required this.mc,
    required this.band,
  });

  factory DataClient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DataClient(
      cpw: data['cpw'] ?? '',
      cpp: data['cpp'] ?? '',
      dekorasi: data['dekorasi'] ?? '',
      mua: data['mua'],
      dokumentasi: data['dokumentasi'],
      catering: data['catering'] ?? '',
      souvenir: data['souvenir'] ?? '',
      mc: data['mc'] ?? '',
      band: data['band'] ?? '',
    );
  }
}

// Simulasi penyimpanan data client (list)
List<DataClient> dataClients = [];

// Fungsi untuk menambahkan data client baru
// void addDataClient(DataClient client) {
//   dataClients.add(client);
// }
Future<List<DataClient>> getDataClients() async {
  try {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('client').get();
    return querySnapshot.docs
        .map((doc) => DataClient.fromFirestore(doc))
        .toList();
  } catch (e) {
    return [];
  }
}

Future<void> addDataClient(DataClient client) async {
  try {
    await FirebaseFirestore.instance.collection('client').add({
      "cpw": client.cpw,
      "cpp": client.cpp,
      "dekorasi": client.dekorasi,
      "mua": client.mua,
      "dokumentasi": client.dokumentasi,
      "catering": client.catering,
      "souvenir": client.souvenir,
      "mc": client.mc,
      "band": client.band,
    });
  } catch (e) {
    rethrow;
  }
}
