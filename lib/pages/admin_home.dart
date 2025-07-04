// =========== IMPORT =============
// Import library yang diperlukan untuk halaman admin
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../data/dummy_tasks.dart';
import 'login_page.dart'; // pastikan ini sesuai struktur project kamu
import '../data/dummy_data_client.dart';
import '../services/task_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =========== ADMIN HOME PAGE CLASS =============
// Kelas utama untuk halaman admin yang menangani semua fungsionalitas admin
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  AdminHomePageState createState() => AdminHomePageState();
}

class AdminHomePageState extends State<AdminHomePage> {
  // =========== VARIABEL =============
  // Variabel untuk mengontrol halaman yang sedang aktif
  String _currentPage = 'menu';
  // Key untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // Variabel untuk menyimpan data form tugas
  String _namaTugas = '';
  DateTime _tanggal = DateTime.now();
  String _jamMulai = '';
  String _jamSelesai = '';
  String _namaPM = '';
  String _pic = '';
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();
  bool _isLoading = false;
  List<DataClient> _realClient = [];

  // Controller untuk input data client
  final _cpwController = TextEditingController();
  final _cppController = TextEditingController();
  final _dekorasiController = TextEditingController();
  final _muaController = TextEditingController();
  final _dokumentasiController = TextEditingController();
  final _cateringController = TextEditingController();
  final _souvenirController = TextEditingController();
  final _mcController = TextEditingController();
  final _bandController = TextEditingController();

  // Daftar opsi PIC yang tersedia
  final List<String> _picOptions = [
    'Registrasi',
    'Runner',
    'Dekorasi',
    'Catering',
    'Souvenir',
    'CPW',
    'CPP',
    'FOH',
    'Talent',
  ];

  @override
  void initState() {
    super.initState();
    _loadDataClients(); // Memuat data client saat halaman dibuka
  }

  @override
  void dispose() {
    // Membersihkan controller saat widget dihapus
    _cpwController.dispose();
    _cppController.dispose();
    _dekorasiController.dispose();
    _muaController.dispose();
    _dokumentasiController.dispose();
    _cateringController.dispose();
    _souvenirController.dispose();
    _mcController.dispose();
    _bandController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat data client dari Firestore
  void _loadDataClients() async {
    final dataClients = await getDataClients();
    setState(() {
      _realClient = dataClients;
    });
  }

  // Fungsi untuk mereset field form client
  void _resetClientForm() {
    _cpwController.clear();
    _cppController.clear();
    _dekorasiController.clear();
    _muaController.clear();
    _dokumentasiController.clear();
    _cateringController.clear();
    _souvenirController.clear();
    _mcController.clear();
    _bandController.clear();
  }

  // Fungsi untuk mereset field form task
  void _resetTaskForm() {
    _namaTugas = '';
    _tanggal = DateTime.now();
    _jamMulai = '';
    _jamSelesai = '';
    _namaPM = '';
    _pic = '';
    _selectedStartTime = TimeOfDay.now();
    _selectedEndTime = TimeOfDay.now();
    _formKey.currentState?.reset();
  }

  // =========== SUBMIT FORM =============
  // Fungsi untuk menangani submit form pembuatan tugas
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Validasi input form
      if (_namaTugas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama tugas wajib diisi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_jamMulai.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam mulai wajib dipilih'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_jamSelesai.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam selesai wajib dipilih'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_namaPM.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama PM wajib diisi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_pic.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIC wajib dipilih'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Tampilkan dialog konfirmasi
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Konfirmasi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Apakah data task yang dimasukkan sudah benar?",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pastikan semua data task yang dimasukkan sudah benar sebelum disimpan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.amber[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amber),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Batal",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                // Membuat objek tugas baru
                                final task = Task(
                                  uid: null,
                                  namaTugas: _namaTugas,
                                  tanggal: _tanggal,
                                  jamMulai: _jamMulai,
                                  jamSelesai: _jamSelesai,
                                  namaPM: _namaPM,
                                  pic: _pic,
                                  status: 'pending',
                                );

                                // Menyimpan tugas ke Firestore
                                final taskId = await addTask(task);

                                if (taskId != null) {
                                  // Mengirim notifikasi tugas baru
                                  final taskNotificationService =
                                      TaskNotificationService();
                                  await taskNotificationService.notifyNewTask(
                                    task,
                                  );

                                  // Tampilkan dialog sukses
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder:
                                          (_) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Sukses",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                      255,
                                                      33,
                                                      83,
                                                      36,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      33,
                                                      83,
                                                      36,
                                                    ).withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_circle,
                                                    color: Color.fromARGB(
                                                      255,
                                                      33,
                                                      83,
                                                      36,
                                                    ),
                                                    size: 28,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  "Task berhasil dibuat!",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      33,
                                                      83,
                                                      36,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          const Color.fromARGB(
                                                            255,
                                                            33,
                                                            83,
                                                            36,
                                                          ).withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.info_outline,
                                                        color: Color.fromARGB(
                                                          255,
                                                          33,
                                                          83,
                                                          36,
                                                        ),
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Task telah berhasil dibuat dan dapat dilihat di menu Task',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                const Color.fromARGB(
                                                                  255,
                                                                  33,
                                                                  83,
                                                                  36,
                                                                ).withOpacity(
                                                                  0.7,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                          255,
                                                          33,
                                                          83,
                                                          36,
                                                        ),
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize: const Size(
                                                      double.infinity,
                                                      45,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _resetTaskForm(); // Reset form fields
                                                    setState(() {
                                                      _currentPage = 'menu';
                                                    });
                                                  },
                                                  child: const Text(
                                                    "Kembali ke Menu",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    );
                                  }
                                } else {
                                  throw Exception(
                                    'Failed to create task - no taskId returned',
                                  );
                                }
                              } catch (e) {
                                // Menampilkan pesan error jika terjadi kesalahan
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Terjadi kesalahan: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            },
                            child: const Text(
                              "Ya, Simpan",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        );
      }
    }
  }

  // =========== DATE PICKER =============
  // Fungsi untuk memilih tanggal tugas
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 33, 83, 36),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _tanggal) {
      setState(() {
        _tanggal = picked;
      });
    }
  }

  // Fungsi untuk memilih waktu mulai/selesai
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _selectedStartTime : _selectedEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 33, 83, 36),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          _jamMulai =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        } else {
          _selectedEndTime = picked;
          _jamSelesai =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  // =========== SUBMIT CLIENT FORM =============
  // Fungsi untuk menangani submit form data client
  Future<void> _submitClientForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Cek status task dan kelengkapan data
        final tasksSnapshot =
            await FirebaseFirestore.instance
                .collection('tasks')
                .where('status', isNotEqualTo: 'done')
                .get();

        if (tasksSnapshot.docs.isNotEmpty) {
          // Ada task yang belum selesai
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tidak dapat menabahkan data client karena masih ada task yang belum selesai',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        // Cek kelengkapan keterangan dan bukti
        final tasksWithIncompleteData =
            await FirebaseFirestore.instance
                .collection('tasks')
                .where('status', isEqualTo: 'done')
                .get();

        for (var doc in tasksWithIncompleteData.docs) {
          final data = doc.data();
          if (data['keterangan'] == null ||
              data['keterangan'].toString().isEmpty ||
              data['bukti'] == null ||
              data['bukti'].toString().isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Tidak dapat menambahkan data client karena masih ada task yang belum memiliki keterangan dan bukti lengkap',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
          }
        }

        // Membuat objek client baru
        final client = DataClient(
          cpw: _cpwController.text,
          cpp: _cppController.text,
          dekorasi: _dekorasiController.text,
          mua: _muaController.text,
          dokumentasi: _dokumentasiController.text,
          catering: _cateringController.text,
          souvenir: _souvenirController.text,
          mc: _mcController.text,
          band: _bandController.text,
        );

        // Menyimpan data client ke Firestore
        await addDataClient(client);

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sukses",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 33, 83, 36),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            33,
                            83,
                            36,
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color.fromARGB(255, 33, 83, 36),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Data client berhasil ditambahkan!",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            33,
                            83,
                            36,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(
                              255,
                              33,
                              83,
                              36,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color.fromARGB(255, 33, 83, 36),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data client telah tersimpan dan dapat dilihat di menu Data Client',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(
                                    255,
                                    33,
                                    83,
                                    36,
                                  ).withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            33,
                            83,
                            36,
                          ),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _resetClientForm(); // Reset form fields
                          setState(() {
                            _currentPage = 'menu';
                            _loadDataClients(); // Reload client data
                          });
                        },
                        child: const Text(
                          "Kembali ke Menu",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          );
        }
      } catch (e) {
        // Menampilkan pesan error jika terjadi kesalahan
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // =========== MENU UTAMA ============
  // Widget untuk menampilkan menu utama admin
  Widget _buildMenuUtama() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header Section - Menampilkan judul dan ikon admin
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 33, 83, 36),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Administraor',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Menu Grid - Menampilkan menu-menu yang tersedia
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // First Row - Task and Data Client
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildMenuCard(
                            icon: Icons.assignment,
                            title: 'Task',
                            onTap: () => setState(() => _currentPage = 'task'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildMenuCard(
                            icon: Icons.person,
                            title: 'Data Client',
                            onTap:
                                () => setState(() => _currentPage = 'client'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Second Row - Create Data Client
                    _buildMenuCard(
                      icon: Icons.person_add,
                      title: 'Tambah Data Client',
                      onTap: () async {
                        // Cek status task dan kelengkapan data
                        final tasksSnapshot =
                            await FirebaseFirestore.instance
                                .collection('tasks')
                                .get();

                        bool canAddClient = true;
                        String errorMessage = '';

                        for (var doc in tasksSnapshot.docs) {
                          final data = doc.data();
                          if (data['status'] != 'done') {
                            canAddClient = false;
                            errorMessage =
                                'Tidak dapat menambahkan data client karena masih ada task yang belum selesai';
                            break;
                          }
                          if (data['keterangan'] == null ||
                              data['keterangan'].toString().isEmpty ||
                              data['bukti'] == null ||
                              data['bukti'].toString().isEmpty) {
                            canAddClient = false;
                            errorMessage =
                                'Tidak dapat menambahkan data client karena masih ada task yang belum memiliki keterangan dan bukti lengkap';
                            break;
                          }
                        }

                        if (!canAddClient) {
                          if (mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Peringatan",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.red,
                                          size: 28,
                                        ),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          errorMessage,
                                          style: const TextStyle(fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.info_outline,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Pastikan semua task sudah selesai dan memiliki keterangan serta bukti yang lengkap',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.red[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(
                                              double.infinity,
                                              45,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "OK",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            );
                            return;
                          }
                        }

                        // Jika semua pengecekan berhasil, buka form tambah client
                        setState(() => _currentPage = 'create_client');
                      },
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk membuat card menu
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 33, 83, 36).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color.fromARGB(255, 33, 83, 36),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 33, 83, 36),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========== FORM TUGAS ============
  Widget _buildTugasForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // ========== TANGGAL ==========
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Tugas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Pilih Tanggal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color.fromARGB(255, 33, 83, 36),
                          ),
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color.fromARGB(255, 33, 83, 36),
                          ),
                        ),
                        child: Text(
                          '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-${_tanggal.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 33, 83, 36),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ========== NAMA TUGAS ==========
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Tugas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama tugas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onSaved: (value) => _namaTugas = value ?? '',
                      validator:
                          (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ========== JAM MULAI & SELESAI ==========
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jam Mulai & Selesai',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Jam Mulai',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                errorText:
                                    _jamMulai.isEmpty ? 'Wajib dipilih' : null,
                              ),
                              child: Text(
                                _jamMulai.isEmpty
                                    ? 'Pilih Jam Mulai'
                                    : _jamMulai,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Jam Selesai',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                errorText:
                                    _jamSelesai.isEmpty
                                        ? 'Wajib dipilih'
                                        : null,
                              ),
                              child: Text(
                                _jamSelesai.isEmpty
                                    ? 'Pilih Jam Selesai'
                                    : _jamSelesai,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ========== NAMA PM ==========
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama PM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama PM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onSaved: (value) => _namaPM = value ?? '',
                      validator:
                          (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ========== PILIH PIC ==========
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih PIC',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _picOptions.map((pic) {
                            final bool isSelected = _pic == pic;
                            return ChoiceChip(
                              label: Text(pic),
                              selected: isSelected,
                              selectedColor: const Color.fromARGB(
                                255,
                                33,
                                83,
                                36,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _pic = pic;
                                });
                              },
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: Colors.grey[200],
                            );
                          }).toList(),
                    ),
                    if (_pic.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'PIC wajib dipilih',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ========== BUTTON ==========
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 83, 36),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isLoading ? null : _submitForm,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Create Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () => setState(() => _currentPage = 'menu'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color.fromARGB(255, 33, 83, 36)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Back to menu',
                style: TextStyle(
                  color: Color.fromARGB(255, 33, 83, 36),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========== DATA CLIENT PAGE ============
  Widget _buildDataClientPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 83, 36),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.people, size: 50, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Data Client',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daftar client yang terdaftar',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                _realClient.isEmpty
                    ? const Center(
                      child: Text(
                        'Belum ada data client yang tersedia',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _realClient.length,
                      itemBuilder: (context, index) {
                        final client = _realClient[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  const Color.fromARGB(
                                    255,
                                    33,
                                    83,
                                    36,
                                  ).withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Client Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            33,
                                            83,
                                            36,
                                          ).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Color.fromARGB(
                                            255,
                                            33,
                                            83,
                                            36,
                                          ),
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'CPW: ${client.cpw}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                  255,
                                                  33,
                                                  83,
                                                  36,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'CPP: ${client.cpp}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                  255,
                                                  33,
                                                  83,
                                                  36,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 20),

                                  // Vendor Section
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildVendorInfo(
                                          'Dekorasi',
                                          client.dekorasi,
                                          Icons.celebration,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVendorInfo(
                                          'MUA',
                                          client.mua,
                                          Icons.face,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVendorInfo(
                                          'Dokumentasi',
                                          client.dokumentasi,
                                          Icons.camera_alt,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVendorInfo(
                                          'Catering',
                                          client.catering,
                                          Icons.restaurant,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVendorInfo(
                                          'Souvenir',
                                          client.souvenir,
                                          Icons.card_giftcard,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVendorInfo(
                                          'MC',
                                          client.mc,
                                          Icons.mic,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVendorInfo(
                                          'Band',
                                          client.band,
                                          Icons.music_note,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 83, 36).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 33, 83, 36),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendor $title',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========== CREATE CLIENT FORM ============
  Widget _buildCreateClientForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 33, 83, 36),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_add, size: 50, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Tambah Data Client',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Isi data client dengan lengkap',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Pasangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 33, 83, 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cpwController,
                      decoration: InputDecoration(
                        labelText: 'Nama CPW',
                        hintText: 'Masukkan nama CPW',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama CPW wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cppController,
                      decoration: InputDecoration(
                        labelText: 'Nama CPP',
                        hintText: 'Masukkan nama CPP',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama CPP wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vendor Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Vendor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 33, 83, 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dekorasiController,
                      decoration: InputDecoration(
                        labelText: 'Dekorasi',
                        hintText: 'Masukkan nama vendor dekorasi',
                        prefixIcon: const Icon(Icons.celebration),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _muaController,
                      decoration: InputDecoration(
                        labelText: 'MUA',
                        hintText: 'Masukkan nama MUA',
                        prefixIcon: const Icon(Icons.face),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dokumentasiController,
                      decoration: InputDecoration(
                        labelText: 'Dokumentasi',
                        hintText: 'Masukkan nama vendor dokumentasi',
                        prefixIcon: const Icon(Icons.camera_alt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cateringController,
                      decoration: InputDecoration(
                        labelText: 'Catering',
                        hintText: 'Masukkan nama vendor catering',
                        prefixIcon: const Icon(Icons.restaurant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _souvenirController,
                      decoration: InputDecoration(
                        labelText: 'Souvenir',
                        hintText: 'Masukkan nama vendor souvenir',
                        prefixIcon: const Icon(Icons.card_giftcard),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mcController,
                      decoration: InputDecoration(
                        labelText: 'MC',
                        hintText: 'Masukkan nama MC',
                        prefixIcon: const Icon(Icons.mic),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bandController,
                      decoration: InputDecoration(
                        labelText: 'Band',
                        hintText: 'Masukkan nama band',
                        prefixIcon: const Icon(Icons.music_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 83, 36),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        if (_formKey.currentState!.validate()) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Konfirmasi",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.help_outline,
                                          color: Colors.amber,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Apakah data yang dimasukkan sudah benar?",
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: Colors.amber,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Pastikan semua data yang dimasukkan sudah benar sebelum disimpan',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.amber[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                  color: Colors.amber,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text(
                                                "Batal",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.amber,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                setState(() {
                                                  _isLoading = true;
                                                });

                                                try {
                                                  // Membuat objek tugas baru
                                                  final task = Task(
                                                    uid: null,
                                                    namaTugas: _namaTugas,
                                                    tanggal: _tanggal,
                                                    jamMulai: _jamMulai,
                                                    jamSelesai: _jamSelesai,
                                                    namaPM: _namaPM,
                                                    pic: _pic,
                                                    status: 'pending',
                                                  );

                                                  // Menyimpan tugas ke Firestore
                                                  final taskId = await addTask(
                                                    task,
                                                  );

                                                  if (taskId != null) {
                                                    // Mengirim notifikasi tugas baru
                                                    final taskNotificationService =
                                                        TaskNotificationService();
                                                    await taskNotificationService
                                                        .notifyNewTask(task);

                                                    // Tampilkan dialog sukses
                                                    if (mounted) {
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible:
                                                            false,
                                                        builder:
                                                            (_) => AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      16,
                                                                    ),
                                                              ),
                                                              title: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  const Text(
                                                                    "Sukses",
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          Color.fromARGB(
                                                                            255,
                                                                            33,
                                                                            83,
                                                                            36,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          8,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color.fromARGB(
                                                                        255,
                                                                        33,
                                                                        83,
                                                                        36,
                                                                      ).withOpacity(
                                                                        0.1,
                                                                      ),
                                                                      shape:
                                                                          BoxShape
                                                                              .circle,
                                                                    ),
                                                                    child: const Icon(
                                                                      Icons
                                                                          .check_circle,
                                                                      color:
                                                                          Color.fromARGB(
                                                                            255,
                                                                            33,
                                                                            83,
                                                                            36,
                                                                          ),
                                                                      size: 28,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  const Text(
                                                                    "Task berhasil dibuat!",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 20,
                                                                  ),
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          16,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color.fromARGB(
                                                                        255,
                                                                        33,
                                                                        83,
                                                                        36,
                                                                      ).withOpacity(
                                                                        0.1,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color.fromARGB(
                                                                          255,
                                                                          33,
                                                                          83,
                                                                          36,
                                                                        ).withOpacity(
                                                                          0.3,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        const Icon(
                                                                          Icons
                                                                              .info_outline,
                                                                          color: Color.fromARGB(
                                                                            255,
                                                                            33,
                                                                            83,
                                                                            36,
                                                                          ),
                                                                          size:
                                                                              24,
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              12,
                                                                        ),
                                                                        Expanded(
                                                                          child: Text(
                                                                            'Task telah berhasil dibuat dan dapat dilihat di menu Task',
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  14,
                                                                              color: const Color.fromARGB(
                                                                                255,
                                                                                33,
                                                                                83,
                                                                                36,
                                                                              ).withOpacity(
                                                                                0.7,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 20,
                                                                  ),
                                                                  ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          const Color.fromARGB(
                                                                            255,
                                                                            33,
                                                                            83,
                                                                            36,
                                                                          ),
                                                                      foregroundColor:
                                                                          Colors
                                                                              .white,
                                                                      minimumSize:
                                                                          const Size(
                                                                            double.infinity,
                                                                            45,
                                                                          ),
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    onPressed: () {
                                                                      Navigator.pop(
                                                                        context,
                                                                      );
                                                                      _resetTaskForm(); // Reset form fields
                                                                      setState(() {
                                                                        _currentPage =
                                                                            'menu';
                                                                      });
                                                                    },
                                                                    child: const Text(
                                                                      "Kembali ke Menu",
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                      );
                                                    }
                                                  } else {
                                                    throw Exception(
                                                      'Failed to create task - no taskId returned',
                                                    );
                                                  }
                                                } catch (e) {
                                                  // Menampilkan pesan error jika terjadi kesalahan
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Terjadi kesalahan: $e',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                  }
                                                }
                                              },
                                              child: const Text(
                                                "Ya, Simpan",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                          );
                        }
                      },
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text(
                            'Tambah Client',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () => setState(() => _currentPage = 'menu'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color.fromARGB(255, 33, 83, 36)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 8),
                  Text(
                    'Kembali ke Menu',
                    style: TextStyle(
                      color: Color.fromARGB(255, 33, 83, 36),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========== BUILD =============
  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    switch (_currentPage) {
      case 'task':
        appBarTitle = 'Create Task';
        break;
      case 'client':
        appBarTitle = 'Data Client';
        break;
      case 'create_client':
        appBarTitle = 'Tambah Data Client';
        break;
      default:
        appBarTitle = 'Admin Menu';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 33, 83, 36),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        elevation: 4,
        leading:
            (_currentPage == 'task' ||
                    _currentPage == 'client' ||
                    _currentPage == 'create_client')
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back to Menu',
                  onPressed: () {
                    setState(() {
                      _currentPage = 'menu';
                    });
                  },
                )
                : null,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            color: const Color.fromARGB(255, 216, 233, 217),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[50]!, Colors.grey[100]!],
              ),
            ),
            child:
                _currentPage == 'menu'
                    ? _buildMenuUtama()
                    : _currentPage == 'task'
                    ? _buildTugasForm()
                    : _currentPage == 'client'
                    ? _buildDataClientPage()
                    : _buildCreateClientForm(),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 33, 83, 36),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
