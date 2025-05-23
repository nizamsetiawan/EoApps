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
  int _selectedIndex =
      0; // 0: Menu, 1: Create Task (Placeholder), 2: Notifications
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isDateRangeMode = false;

  @override
  void initState() {
    super.initState();
    _loadDataClients();
    _getFCMToken();
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
      // Map index to page
      if (index == 0) {
        _currentPage = 'menu';
      } else if (index == 1) {
        // Central icon - no navigation, remains on current page or default
        // For now, let's keep it on the current page or default to menu
        _currentPage = 'menu'; // Or handle specific action if needed
      } else if (index == 2) {
        // Task list view - corresponds to the second icon slot in the new bar logic
        _currentPage = 'task';
      } else if (index == 3) {
        // Placeholder for notifications page
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

  // Helper function to get the start of the week
  DateTime _getStartOfWeek(DateTime date) {
    final int daysSinceMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysSinceMonday));
  }

  // Date Selector Widget
  Widget _buildDateSelector() {
    final DateTime startOfWeek = _getStartOfWeek(_selectedDate);
    final List<DateTime> weekDates = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month and Year Header
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
        // Horizontal list of days
        SizedBox(
          height: 100, // Adjust height as needed
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
                  width: 65, // Adjust width as needed
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

  // Helper to get Month Name
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

  // Helper to get Weekday Name
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
              // Header Section
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

              // Menu Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Task Menu
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

                  // Data Client Menu
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

              // Additional Menu Items
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Create Task Menu
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

                  // Recap Menu
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

  // Task List View
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

          if (tasks.isEmpty) {
            return const Center(child: Text("Waw kamu bisa santai hari ini"));
          }

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
                              // Task Header
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
                                            Text(
                                              '${task.jamMulai} - ${task.jamSelesai}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
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

                              // Task Details
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
                                        Text(
                                          'PIC: ${task.pic}',
                                          style: const TextStyle(fontSize: 16),
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
                                        Text(
                                          'Status: ${task.status}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _getStatusColor(task.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Status Buttons
                              Row(
                                children:
                                    ['not complete', 'pending', 'done'].map((
                                      status,
                                    ) {
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              if (task.uid != null) {
                                                await setStatus(
                                                  task.uid!,
                                                  status,
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
                                                  task.status == status
                                                      ? _getStatusColor(status)
                                                      : Colors.grey[200],
                                              foregroundColor:
                                                  task.status == status
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

                              // Notes Section
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

                              // Evidence Section
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
                                          print('Error loading image: $error');
                                          print('Image URL: ${task.bukti}');
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
                                                Text(
                                                  'Gagal memuat gambar\n${error.toString()}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.red,
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
                                ),

                              // Upload Button - Only show if no evidence exists
                              if (task.bukti == null || task.bukti!.isEmpty)
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
        return Color.fromARGB(255, 33, 83, 36);
      case 'not complete':
        return Colors.red;
      case 'pending':
        return Color.fromARGB(255, 219, 172, 30);
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'done':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 30),
        );
      case 'not complete':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 30),
        );
      case 'pending':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 219, 172, 30).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_empty,
            color: Color.fromARGB(255, 219, 172, 30),
            size: 30,
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.circle_outlined,
            color: Colors.grey,
            size: 30,
          ),
        );
    }
  }

  //====================================== Page Data Client ====================
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

  //====================================== Recap =================
  Widget _buildRecapPage() {
    return StreamBuilder<List<Task>>(
      stream:
          _isDateRangeMode
              ? FirebaseFirestore.instance
                  .collection('tasks')
                  .where('tanggal', isGreaterThanOrEqualTo: _startDate)
                  .where(
                    'tanggal',
                    isLessThan: _endDate.add(const Duration(days: 1)),
                  )
                  .snapshots()
                  .map(
                    (snapshot) =>
                        snapshot.docs
                            .map((doc) => Task.fromFirestore(doc))
                            .toList(),
                  )
              : getTasksStream(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;

        // Calculate statistics
        final totalTasks = tasks.length;
        final notCompleteTasks =
            tasks.where((t) => t.status == 'not complete').length;
        final pendingTasks = tasks.where((t) => t.status == 'pending').length;
        final doneTasks = tasks.where((t) => t.status == 'done').length;

        // Calculate completion rate
        final completionRate =
            totalTasks > 0 ? (doneTasks / totalTasks * 100) : 0;

        // Calculate average tasks per day
        final daysDiff =
            _isDateRangeMode ? _endDate.difference(_startDate).inDays + 1 : 1;
        final avgTasksPerDay = totalTasks / daysDiff;

        // Calculate average completion time (in hours)
        double totalCompletionTime = 0;
        int completedTasksCount = 0;
        for (var task in tasks) {
          if (task.status == 'done') {
            final startTime = _parseTime(task.jamMulai);
            final endTime = _parseTime(task.jamSelesai);
            if (startTime != null && endTime != null) {
              totalCompletionTime +=
                  endTime.difference(startTime).inHours.toDouble();
              completedTasksCount++;
            }
          }
        }
        final avgCompletionTime =
            completedTasksCount > 0
                ? totalCompletionTime / completedTasksCount
                : 0;

        // Group tasks by PIC
        final tasksByPIC = <String, int>{};
        for (var task in tasks) {
          tasksByPIC[task.pic] = (tasksByPIC[task.pic] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                    const Icon(Icons.analytics, size: 50, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Task Recap',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isDateRangeMode
                          ? 'Range: ${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}'
                          : 'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isDateRangeMode = !_isDateRangeMode;
                            });
                          },
                          icon: Icon(
                            _isDateRangeMode
                                ? Icons.calendar_today
                                : Icons.date_range,
                          ),
                          label: Text(
                            _isDateRangeMode ? 'Single Date' : 'Date Range',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color.fromARGB(
                              255,
                              33,
                              83,
                              36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isDateRangeMode)
                          ElevatedButton.icon(
                            onPressed: () => _selectDateRange(context),
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text('Select Range'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color.fromARGB(
                                255,
                                33,
                                83,
                                36,
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Select Date'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color.fromARGB(
                                255,
                                33,
                                83,
                                36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Stats Grid
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
                    'Avg Completion Time',
                    '${avgCompletionTime.toStringAsFixed(1)}h',
                    Icons.timer,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Status Distribution
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
                      const Text(
                        'Status Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 33, 83, 36),
                        ),
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

              // Tasks by PIC
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
                      const Text(
                        'Tasks by PIC',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 33, 83, 36),
                        ),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
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

  //====================================== Notifications Page Placeholder ====
  Widget _buildNotificationsPage() {
    if (_isTokenLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fcmToken == null) {
      return const Center(
        child: Text('FCM Token not available. Cannot load notifications.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('notifications')
              .where('token', isEqualTo: _fcmToken)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading notifications: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada notifikasi.'));
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification =
                notifications[index].data() as Map<String, dynamic>;
            final title = notification['title'] ?? 'No Title';
            final body = notification['body'] ?? 'No Body';
            final timestamp = notification['timestamp'] as Timestamp?;
            final formattedTime =
                timestamp != null
                    ? '${timestamp.toDate().toLocal()}'.split('.')[0]
                    : 'Unknown time';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              elevation: 2.0,
              child: ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Color.fromARGB(255, 33, 83, 36),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body),
                    const SizedBox(height: 4.0),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Custom Bottom Navigation Bar
  Widget _buildCustomBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      clipBehavior: Clip.antiAlias,
      color: const Color.fromARGB(255, 33, 83, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          // Home Button
          IconButton(
            icon: Icon(
              Icons.home,
              color: _selectedIndex == 0 ? Colors.white : Colors.white54,
            ),
            onPressed: () => _onItemTapped(0),
            tooltip: 'Menu Utama',
          ),
          // Spacer for the center floating button
          const SizedBox(width: 48),
          // Notifications Button
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
      } else {
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
    } catch (e) {
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
    } finally {
      setState(() {
        _isUploading[task.uid!] = false;
      });
    }
  }

  // Helper method to parse time string to DateTime
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

  // =========== BUILD =============
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
}
