import 'package:flutter/material.dart';
import 'package:kenongotask2/models/task.dart';
import '../data/dummy_tasks.dart';
import 'login_page.dart';
import 'create_task_page.dart';
import '../data/dummy_data_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
import '../models/notification.dart';
import 'package:intl/intl.dart';
import '../services/task_notification_service.dart';
import 'completed_tasks_page.dart';

class PMHomePage extends StatefulWidget {
  final String role;

  const PMHomePage({super.key, required this.role});

  @override
  _PMHomePageState createState() => _PMHomePageState();
}

class _PMHomePageState extends State<PMHomePage> {
  List<DataClient> _realClient = [];
  String? _fcmToken;
  bool _isTokenLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _currentPage = 'menu';
  final Map<int, TextEditingController> _keteranganControllers = {};
  final ImagePicker _picker = ImagePicker();
  final Map<String, bool> _isEditingNotes = {};
  final Map<String, bool> _isUploading = {};
  int _selectedIndex = 0;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isDateRangeMode = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String _selectedNotificationFilter = 'Task baru dibuat';

  @override
  void initState() {
    super.initState();
    _loadDataClients();
    _getFCMToken();
    _currentUser = _auth.currentUser;
  }

  void _loadDataClients() async {
    final dataClients = await getDataClients();
    setState(() {
      _realClient = dataClients;
    });
  }

  Future<void> _getFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          setState(() {
            _fcmToken = userDoc.data()?['fcmToken'] as String?;
            _isTokenLoading = false;
          });
        } else {
          setState(() {
            _isTokenLoading = false;
          });
        }
      } else {
        setState(() {
          _isTokenLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isTokenLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _currentPage = 'menu';
      } else if (index == 2) {
        _currentPage = 'task';
      } else if (index == 3) {
        _currentPage = 'notifications';
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 33, 83, 36),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    final int daysSinceMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysSinceMonday));
  }

  Widget _buildDateSelector() {
    final DateTime startOfWeek = _getStartOfWeek(_selectedDate);
    final List<DateTime> weekDates = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(_selectedDate.month)}, ${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 33, 83, 36),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.calendar_today,
                  color: Color.fromARGB(255, 33, 83, 36),
                ),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekDates.length,
            itemBuilder: (context, index) {
              final date = weekDates[index];
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  width: 65,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Card(
                    color:
                        isSelected
                            ? const Color.fromARGB(255, 33, 83, 36)
                            : Colors.white,
                    elevation: isSelected ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getWeekdayName(date.weekday),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color.fromARGB(255, 33, 83, 36),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
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
        const SizedBox(height: 16),
      ],
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return '';
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'SEN';
      case 2:
        return 'SEL';
      case 3:
        return 'RAB';
      case 4:
        return 'KAM';
      case 5:
        return 'JUM';
      case 6:
        return 'SAB';
      case 7:
        return 'MIN';
      default:
        return '';
    }
  }

  Widget _buildMenuUtama() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Project Manager',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentPage = 'task'),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(vertical: 25),
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
                                Icons.assignment,
                                size: 35,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentPage = 'client'),
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(vertical: 25),
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
                                Icons.person,
                                size: 35,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Data Client',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateTaskPage(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(vertical: 25),
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
                                Icons.add_task,
                                size: 35,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Buat Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentPage = 'recap';
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(vertical: 25),
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
                                Icons.analytics,
                                size: 35,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Recap',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 33, 83, 36),
                              ),
                            ),
                          ],
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
    );
  }

  // ======= TASK PAGE =======
  // Halaman ini menampilkan daftar task untuk tanggal yang dipilih
  // Fitur:
  // 1. Pemilihan tanggal dengan calendar picker
  // 2. Tampilan task dalam bentuk card dengan status dan detail
  // 3. Update status task (not complete, pending, done)
  // 4. Tambah keterangan untuk task
  // 5. Upload bukti untuk task
  List<Widget> _buildTaskList() {
    return [
      StreamBuilder<List<Task>>(
        stream: getTasksStream(_selectedDate),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          tasks.sort((b, a) => a.jamMulai.compareTo(b.jamMulai));

          // Tampilkan pesan jika tidak ada task
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.fromSize(size: const Size.fromHeight(150)),
                  const Text(
                    "Waw kamu bisa santai hari ini",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 33, 83, 36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Tampilkan daftar task
          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children:
                tasks.map((task) {
                  task.status =
                      task.status.isEmpty ? 'not complete' : task.status;

                  if (!_keteranganControllers.containsKey(task.hashCode)) {
                    _keteranganControllers[task.hashCode] =
                        TextEditingController();
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              _getStatusColor(task.status).withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _getStatusIcon(task.status),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.namaTugas,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                              255,
                                              33,
                                              83,
                                              36,
                                            ),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${task.jamMulai} - ${task.jamSelesai}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Nama PIC : ${getNamaPICFromVendor(task.pic)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.business,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Vendor : ${task.pic}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.assignment,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Status: ${task.status}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _getStatusColor(
                                                task.status,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tampilkan tombol approval jika status waiting approval
                              if (task.status == 'waiting approval')
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          if (task.uid != null) {
                                            await setStatus(
                                              task.uid!,
                                              'not complete',
                                              previousStatus: task.status,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.approval,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Approve',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            33,
                                            83,
                                            36,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              // Tampilkan tombol status untuk task yang sudah diapprove
                              else if (task.status != 'done') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children:
                                      ['not complete', 'pending', 'done'].map((
                                        status,
                                      ) {
                                        final isTaskDone =
                                            task.status == 'done';
                                        final isCurrentStatus =
                                            task.status == status;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  isTaskDone
                                                      ? null
                                                      : () async {
                                                        if (task.uid != null) {
                                                          await setStatus(
                                                            task.uid!,
                                                            status,
                                                            previousStatus:
                                                                task.status,
                                                          );
                                                        }
                                                      },
                                              icon: Icon(
                                                status == 'done'
                                                    ? Icons.check_circle
                                                    : status == 'pending'
                                                    ? Icons.hourglass_empty
                                                    : Icons.cancel_outlined,
                                                size: 16,
                                              ),
                                              label: Text(
                                                status,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    isTaskDone
                                                        ? Colors.grey[300]
                                                        : task.status == status
                                                        ? _getStatusColor(
                                                          status,
                                                        )
                                                        : Colors.grey[200],
                                                foregroundColor:
                                                    isTaskDone
                                                        ? Colors.grey[500]
                                                        : task.status == status
                                                        ? Colors.white
                                                        : Colors.grey[600],
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Tombol validasi khusus untuk PM ketika task pending
                              if (task.status == 'pending')
                                Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          219,
                                          172,
                                          30,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            255,
                                            219,
                                            172,
                                            30,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.hourglass_empty,
                                            color: Color.fromARGB(
                                              255,
                                              219,
                                              172,
                                              30,
                                            ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'PIC telah mengupload bukti. Silakan lakukan validasi atau penolakan.',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color.fromARGB(
                                                  255,
                                                  219,
                                                  172,
                                                  30,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              // Konfirmasi validasi dengan format adminhome
                                              final confirmed = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                barrierDismissible: false,
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
                                                            "Konfirmasi",
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
                                                              color:
                                                                  Color.fromARGB(
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
                                                                  .help_outline,
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
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Apakah Anda yakin ingin memvalidasi task "${task.namaTugas}"?',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
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
                                                              color:
                                                                  Color.fromARGB(
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
                                                                color:
                                                                    Color.fromARGB(
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
                                                                  color:
                                                                      Color.fromARGB(
                                                                        255,
                                                                        33,
                                                                        83,
                                                                        36,
                                                                      ),
                                                                  size: 24,
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Task akan dianggap selesai dan divalidasi oleh Project Manager.',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color:
                                                                          Color.fromARGB(
                                                                            255,
                                                                            33,
                                                                            83,
                                                                            36,
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
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: OutlinedButton(
                                                                  style: OutlinedButton.styleFrom(
                                                                    side: const BorderSide(
                                                                      color:
                                                                          Color.fromARGB(
                                                                            255,
                                                                            33,
                                                                            83,
                                                                            36,
                                                                          ),
                                                                    ),
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        false,
                                                                      ),
                                                                  child: const Text(
                                                                    "Batal",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16,
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
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Expanded(
                                                                child: ElevatedButton(
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
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        true,
                                                                      ),
                                                                  child: const Text(
                                                                    "Validasi",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
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
                                              if (confirmed == true &&
                                                  task.uid != null) {
                                                final scaffoldMessenger =
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    );
                                                await setStatus(
                                                  task.uid!,
                                                  'done',
                                                  previousStatus: task.status,
                                                );
                                                if (mounted) {
                                                  scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.check_circle,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          const Text(
                                                            'Task berhasil divalidasi',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            33,
                                                            83,
                                                            36,
                                                          ),
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      margin:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.check_circle,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Validasi',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    33,
                                                    83,
                                                    36,
                                                  ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              // Konfirmasi penolakan dengan format adminhome
                                              final confirmed = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                barrierDismissible: false,
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
                                                            "Konfirmasi",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .red
                                                                      .withOpacity(
                                                                        0.1,
                                                                      ),
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                ),
                                                            child: const Icon(
                                                              Icons
                                                                  .help_outline,
                                                              color: Colors.red,
                                                              size: 28,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Apakah Anda yakin ingin menolak task "${task.namaTugas}"?',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
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
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              border: Border.all(
                                                                color: Colors
                                                                    .red
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .info_outline,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                  size: 24,
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Task akan dikembalikan ke PIC untuk upload bukti ulang.',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color:
                                                                          Colors
                                                                              .red[700],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 20,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: OutlinedButton(
                                                                  style: OutlinedButton.styleFrom(
                                                                    side: const BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        false,
                                                                      ),
                                                                  child: const Text(
                                                                    "Batal",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Expanded(
                                                                child: ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        true,
                                                                      ),
                                                                  child: const Text(
                                                                    "Tolak",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
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
                                              if (confirmed == true &&
                                                  task.uid != null) {
                                                final scaffoldMessenger =
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    );
                                                await setStatus(
                                                  task.uid!,
                                                  'not complete',
                                                  previousStatus: task.status,
                                                );
                                                if (mounted) {
                                                  scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.cancel,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          const Text(
                                                            'Task ditolak. PIC diminta upload ulang.',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      margin:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      duration: const Duration(
                                                        seconds: 3,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.cancel,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Tolak',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),

                              // Tampilkan pesan jika task sudah done
                              if (task.status == 'done')
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      33,
                                      83,
                                      36,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
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
                                      Icon(
                                        Icons.lock,
                                        color: const Color.fromARGB(
                                          255,
                                          33,
                                          83,
                                          36,
                                        ),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Task telah selesai dan divalidasi. Status tidak dapat diubah lagi.',
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              33,
                                              83,
                                              36,
                                            ),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 8),

                              if (task.keterangan != null &&
                                  task.keterangan!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Keterangan:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Text(
                                        task.keterangan!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                )
                              else if (_isEditingNotes[task.uid!] == true)
                                Column(
                                  children: [
                                    TextField(
                                      controller:
                                          _keteranganControllers[task.hashCode],
                                      decoration: InputDecoration(
                                        hintText: 'Tulis keterangan di sini...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isEditingNotes[task.uid!] =
                                                  false;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          label: const Text('Batal'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                            foregroundColor: Colors.grey[800],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final keterangan =
                                                _keteranganControllers[task
                                                        .hashCode]
                                                    ?.text ??
                                                '';
                                            if (keterangan.isNotEmpty) {
                                              await updateTaskKeterangan(
                                                task.uid!,
                                                keterangan,
                                              );
                                              setState(() {
                                                _isEditingNotes[task.uid!] =
                                                    false;
                                              });
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Keterangan berhasil disimpan',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                        255,
                                                        33,
                                                        83,
                                                        36,
                                                      ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  margin: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.check,
                                            size: 18,
                                          ),
                                          label: const Text('Simpan'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  33,
                                                  83,
                                                  36,
                                                ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingNotes[task.uid!] = true;
                                      });
                                    },
                                    icon: const Icon(Icons.note_add),
                                    label: const Text('Tambah Keterangan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        33,
                                        83,
                                        36,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),

                              if (task.bukti != null && task.bukti!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bukti:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        task.bukti!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 200,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 200,
                                            color: Colors.grey[200],
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                                const SizedBox(height: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Gagal memuat gambar\n${error.toString()}',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                )
                              else if (task.bukti == null ||
                                  task.bukti!.isEmpty)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isUploading[task.uid!] == true
                                            ? null
                                            : () => _uploadEvidence(task),
                                    icon:
                                        _isUploading[task.uid!] == true
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                            : const Icon(Icons.upload_file),
                                    label: Text(
                                      _isUploading[task.uid!] == true
                                          ? 'Mengupload...'
                                          : 'Upload Bukti',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        33,
                                        83,
                                        36,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          );
        },
      ),
    ];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return const Color.fromARGB(255, 33, 83, 36);
      case 'waiting approval':
        return Colors.orange;
      case 'not complete':
        return Colors.red;
      case 'pending':
        return const Color.fromARGB(255, 219, 172, 30);
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    IconData iconData;
    Color color = _getStatusColor(status);

    switch (status) {
      case 'done':
        iconData = Icons.check_circle;
        break;
      case 'waiting approval':
        iconData = Icons.pending_actions;
        break;
      case 'not complete':
        iconData = Icons.cancel;
        break;
      case 'pending':
        iconData = Icons.hourglass_empty;
        break;
      default:
        iconData = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color),
    );
  }

  Widget _buildDataClientPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
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
            child: ListView.builder(
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
                                  color: Color.fromARGB(255, 33, 83, 36),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CPW: ${client.cpw}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 33, 83, 36),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'CPP: ${client.cpp}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 33, 83, 36),
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
                                _buildVendorInfo('MUA', client.mua, Icons.face),
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
                                _buildVendorInfo('MC', client.mc, Icons.mic),
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

  Widget _buildRecapPage() {
    return StreamBuilder<List<Task>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        final totalTasks = tasks.length;
        final notCompleteTasks =
            tasks.where((t) => t.status == 'not complete').length;
        final pendingTasks = tasks.where((t) => t.status == 'pending').length;
        final doneTasks = tasks.where((t) => t.status == 'done').length;

        final completionRate =
            totalTasks > 0 ? (doneTasks / totalTasks * 100) : 0;

        // Hitung rata-rata task per hari berdasarkan tanggal pertama dan terakhir
        DateTime? firstDate;
        DateTime? lastDate;
        for (var task in tasks) {
          if (firstDate == null || task.tanggal.isBefore(firstDate)) {
            firstDate = task.tanggal;
          }
          if (lastDate == null || task.tanggal.isAfter(lastDate)) {
            lastDate = task.tanggal;
          }
        }

        final daysDiff =
            firstDate != null && lastDate != null
                ? lastDate.difference(firstDate).inDays + 1
                : 1;
        final avgTasksPerDay = totalTasks / daysDiff;

        final completedTasks =
            tasks.where((task) => task.status == 'done').toList();

        final tasksByPIC = <String, int>{};
        for (var task in tasks) {
          tasksByPIC[task.pic] = (tasksByPIC[task.pic] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.analytics,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Task Recap',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Task',
                    totalTasks.toString(),
                    Icons.assignment,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Completion Rate',
                    '${completionRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Avg Tasks/Day',
                    avgTasksPerDay.toStringAsFixed(1),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Task Selesai',
                    '${completedTasks.length}',
                    Icons.task_alt,
                    Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CompletedTasksPage(
                                completedTasks: completedTasks,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Status Distribution',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 33, 83, 36),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message:
                                'Menampilkan distribusi status task (Not Complete, Pending, Done) dalam bentuk pie chart',
                            child: Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: notCompleteTasks.toDouble(),
                                title: 'Not Complete',
                                color: Colors.red,
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: pendingTasks.toDouble(),
                                title: 'Pending',
                                color: const Color.fromARGB(255, 219, 172, 30),
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: doneTasks.toDouble(),
                                title: 'Done',
                                color: const Color.fromARGB(255, 33, 83, 36),
                                radius: 50,
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendItem('Not Complete', Colors.red),
                          _buildLegendItem(
                            'Pending',
                            const Color.fromARGB(255, 219, 172, 30),
                          ),
                          _buildLegendItem(
                            'Done',
                            const Color.fromARGB(255, 33, 83, 36),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Tasks by PIC',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 33, 83, 36),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message:
                                'Menampilkan jumlah task yang ditangani oleh setiap PIC (Person In Charge)',
                            child: Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: tasksByPIC.values.fold(0, max).toDouble(),
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final pic = tasksByPIC.keys.elementAt(
                                      value.toInt(),
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        pic,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups:
                                tasksByPIC.entries.map((entry) {
                                  return BarChartGroupData(
                                    x: tasksByPIC.keys.toList().indexOf(
                                      entry.key,
                                    ),
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.toDouble(),
                                        color: const Color.fromARGB(
                                          255,
                                          33,
                                          83,
                                          36,
                                        ),
                                        width: 20,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ======= NOTIFICATION PAGE =======
  // Halaman ini menampilkan daftar notifikasi yang diterima user
  // Fitur:
  // 1. Filter notifikasi berdasarkan tipe (Task Baru, Pengingat, Status Berubah, dll)
  // 2. Menampilkan notifikasi dalam bentuk card dengan icon dan warna yang sesuai
  // 3. Dapat menghapus notifikasi dengan swipe
  // 4. Menampilkan timestamp notifikasi
  Widget _buildNotificationsPage() {
    return Column(
      children: [
        // Filter dropdown untuk memfilter notifikasi
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedNotificationFilter,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items:
                        [
                          'Task baru dibuat',
                          'Task Pengingat',
                          'Task pending',
                          'Task ditolak',
                          'Task Selesai',
                          'Semua',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedNotificationFilter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Stream builder untuk menampilkan notifikasi real-time dari Firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userIds')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Terjadi kesalahan'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada notifikasi',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              // Filter notifikasi berdasarkan tipe yang dipilih
              var filteredDocs =
                  snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] as String? ?? '';

                    if (_selectedNotificationFilter == 'Semua') return true;

                    switch (_selectedNotificationFilter) {
                      case 'Task baru dibuat':
                        return type == 'task_created_admin' ||
                            type == 'task_approved_by_pm';
                      case 'Task Pengingat':
                        return type == 'reminder';
                      case 'Task pending':
                        return type == 'need_pm_validation' ||
                            type == 'upload_bukti' ||
                            type == 'need_pm_approval';
                      case 'Task ditolak':
                        return type == 'task_rejected_by_pm';
                      case 'Task Selesai':
                        return type == 'task_selesai' ||
                            type == 'task_validated_by_pm';
                      default:
                        return true;
                    }
                  }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada notifikasi untuk filter: $_selectedNotificationFilter',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }

              // Tampilkan daftar notifikasi yang sudah difilter
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final notification = NotificationModel.fromFirestore(
                    filteredDocs[index],
                  );
                  return _buildNotificationCard(notification);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget untuk menampilkan card notifikasi
  // Menampilkan:
  // 1. Icon sesuai tipe notifikasi
  // 2. Judul notifikasi
  // 3. Isi notifikasi
  // 4. Waktu notifikasi
  // 5. Opsi untuk menghapus notifikasi dengan swipe
  Widget _buildNotificationCard(NotificationModel notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'task_created':
        iconData = Icons.add_task;
        iconColor = Colors.green;
        break;
      case 'reminder':
        iconData = Icons.alarm;
        iconColor = Colors.orange;
        break;
      case 'status_changed':
        iconData = Icons.update;
        iconColor = Colors.blue;
        break;
      case 'upload_bukti':
        iconData = Icons.upload_file;
        iconColor = Colors.purple;
        break;
      case 'task_selesai':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'task_created_admin':
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.indigo;
        break;
      case 'need_pm_approval':
        iconData = Icons.pending_actions;
        iconColor = Colors.orange;
        break;
      case 'task_approved_by_pm':
        iconData = Icons.approval;
        iconColor = Colors.blue;
        break;
      case 'need_pm_validation':
        iconData = Icons.verified_user;
        iconColor = Colors.purple;
        break;
      case 'task_validated_by_pm':
        iconData = Icons.verified;
        iconColor = Colors.green;
        break;
      case 'task_rejected_by_pm':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'task_rekap':
        iconData = Icons.analytics;
        iconColor = Colors.indigo;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        try {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notification.id)
              .delete();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifikasi berhasil dihapus'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(notification.timestamp),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

  Widget _buildCustomBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      clipBehavior: Clip.antiAlias,
      color: const Color.fromARGB(255, 33, 83, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.home,
              color: _selectedIndex == 0 ? Colors.white : Colors.white54,
            ),
            onPressed: () => _onItemTapped(0),
            tooltip: 'Menu Utama',
          ),
          const SizedBox(width: 48),
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: _selectedIndex == 3 ? Colors.white : Colors.white54,
            ),
            onPressed: () => _onItemTapped(3),
            tooltip: 'Notifikasi',
          ),
        ],
      ),
    );
  }

  Future<void> _uploadEvidence(Task task) async {
    try {
      setState(() {
        _isUploading[task.uid!] = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isUploading[task.uid!] = false;
        });
        return;
      }

      final imageUrl = await ImageService.uploadImage(File(image.path));

      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(task.uid!)
            .update({'bukti': imageUrl});

        setState(() {
          _isEditingNotes[task.uid!] = false;
        });

        final taskNotificationService = TaskNotificationService();
        await taskNotificationService.notifyUploadBukti(task, imageUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Bukti berhasil disimpan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 33, 83, 36),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Gagal mengupload bukti',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Terjadi kesalahan saat mengupload bukti',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading[task.uid!] = false;
      });
    }
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2024, 1, 1, hour, minute);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String getNamaPICFromVendor(String vendor) {
    switch (vendor) {
      case 'ACARA':
        return 'Kenongo';
      case 'Souvenir':
        return 'Elfiana Elza';
      case 'CPW':
        return 'Lutfi';
      case 'CPP':
        return 'Zidane';
      case 'Registrasi':
        return 'Lurry';
      case 'Dekorasi':
        return 'Septiana';
      case 'Catering':
        return 'Fadhilla Agustin';
      case 'FOH':
        return 'Ryan';
      case 'Runner':
        return 'Maldi Ramdani Fahrian';
      case 'Talent':
        return 'Septianati Talia';
      default:
        return vendor;
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

    // Query untuk PM - tampilkan semua status task termasuk yang menunggu approval
    var query = FirebaseFirestore.instance
        .collection('tasks')
        .where(
          'tanggal',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay));

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    String appBarTitle;

    switch (_currentPage) {
      case 'task':
        bodyContent = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDateSelector(),
              Expanded(
                child:
                    _buildTaskList().isNotEmpty
                        ? ListView(children: _buildTaskList())
                        : const Center(
                          child: Text("Waw kamu bisa santai hari ini"),
                        ),
              ),
            ],
          ),
        );
        appBarTitle = 'Task List';
        break;
      case 'client':
        bodyContent = _buildDataClientPage();
        appBarTitle = 'Data Client';
        break;
      case 'notifications':
        bodyContent = _buildNotificationsPage();
        appBarTitle = 'Notifikasi';
        break;
      case 'recap':
        bodyContent = _buildRecapPage();
        appBarTitle = 'Task Recap';
        break;
      default:
        bodyContent = _buildMenuUtama();
        appBarTitle = 'PM Task Scheduling';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color.fromARGB(255, 33, 83, 36),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        leading:
            (_currentPage == 'task' ||
                    _currentPage == 'client' ||
                    _currentPage == 'recap')
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back to Menu',
                  onPressed: () {
                    setState(() {
                      _currentPage = 'menu';
                      _selectedIndex = 0;
                    });
                  },
                )
                : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            color: const Color.fromARGB(255, 216, 233, 217),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: bodyContent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(1),
        backgroundColor: Colors.white,
        elevation: 10.0,
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/kenongo_icon.png', width: 40, height: 40),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    String tooltipText = '';
    switch (title) {
      case 'Total Task':
        tooltipText = 'Jumlah keseluruhan task yang ada dalam sistem';
        break;
      case 'Completion Rate':
        tooltipText =
            'Persentase task yang sudah selesai (status done) dari total task';
        break;
      case 'Avg Tasks/Day':
        tooltipText =
            'Rata-rata jumlah task per hari, dihitung dari rentang waktu antara task pertama dan terakhir';
        break;
      case 'Task Selesai':
        tooltipText =
            'Jumlah task yang sudah selesai dan memiliki keterangan serta bukti lengkap';
        break;
    }

    return Tooltip(
      message: tooltipText,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, color: color, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
