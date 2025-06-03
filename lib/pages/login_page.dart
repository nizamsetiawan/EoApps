// ======= LOGIN PAGE =======
// Halaman ini menangani proses autentikasi pengguna
// Fitur:
// 1. Form login dengan validasi email dan password
// 2. Integrasi dengan Firebase Authentication
// 3. Penyimpanan FCM token untuk notifikasi
// 4. Redirect ke halaman sesuai role pengguna (Admin, PM, dan 10 PIC)
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import '../data/dummy_users.dart';
import 'admin_home.dart';
import 'pm_home.dart';
import 'pic_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller untuk input email dan password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailErrorText;
  String? _passwordErrorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ======= HANDLE LOGIN =======
  // Fungsi ini menangani proses login pengguna
  // 1. Validasi input email dan password
  // 2. Autentikasi dengan Firebase
  // 3. Menyimpan FCM token untuk notifikasi
  // 4. Mendapatkan role pengguna
  // 5. Redirect ke halaman sesuai role
  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Validasi input kosong
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _emailErrorText = email.isEmpty ? "Email tidak boleh kosong" : null;
          _passwordErrorText =
              password.isEmpty ? "Password tidak boleh kosong" : null;
          _isLoading = false;
        });
        return;
      }

      // Autentikasi dengan Firebase
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Mendapatkan dan menyimpan FCM token
      // menambnhakan firebase ma
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        // Cari user berdasarkan email
        final userQuery =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: email)
                .get();

        if (userQuery.docs.isNotEmpty) {
          // Update fcmToken dan lastLogin untuk user yang ditemukan
          await userQuery.docs.first.reference.update({
            'fcmToken': fcmToken,
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }

      // Mendapatkan role pengguna
      final role = await getUserRole();

      if (!mounted) return;

      // Redirect ke halaman sesuai role
      Widget nextPage;
      if (role == null) {
        throw Exception('Role not found');
      }

      switch (role) {
        case 'admin':
          nextPage = const AdminHomePage();
          break;
        case 'pm':
          nextPage = PMHomePage(role: 'pm');
          break;
        case 'ACARA':
          nextPage = PICHomePage(role: role);
          break;
        case 'Souvenir':
        case 'CPW':
        case 'CPP':
        case 'Registrasi':
        case 'Dekorasi':
        case 'Catering':
        case 'FOH':
        case 'Runner':
        case 'Talent':
          nextPage = PICHomePage(role: role);
          break;
        default:
          throw Exception('Invalid role: $role');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } on FirebaseAuthException catch (e) {
      // Handle error autentikasi
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _emailErrorText = 'Email tidak terdaftar';
            break;
          case 'wrong-password':
            _passwordErrorText = 'Password salah';
            break;
          case 'invalid-email':
            _emailErrorText = 'Format email tidak valid';
            break;
          case 'user-disabled':
            _emailErrorText = 'Akun telah dinonaktifkan';
            break;
          default:
            _emailErrorText = 'Terjadi kesalahan: ${e.message}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _emailErrorText = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  // ======= GET USER ROLE =======
  // Fungsi ini mengambil role pengguna dari Firestore
  // 1. Mendapatkan email pengguna yang sedang login
  // 2. Mencari dokumen user di Firestore
  // 3. Mengembalikan role pengguna
  Future<String?> getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final email = user.email;
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final data = userDoc.data();

        if (data.containsKey('role')) {
          return data['role'] as String;
        }
      }
      throw Exception('Role not fund for user: $email');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 247, 245, 245),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Kenongo
                Center(
                  child: Image.asset('assets/kenongo_logos.png', height: 120),
                ),
                // Welcome Text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hallo!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 33, 83, 36),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome to Kenongo',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color.fromARGB(255, 33, 83, 36),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Login Form Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Email Input Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _emailErrorText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Password Input Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _passwordErrorText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              33,
                              83,
                              36,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
                                  : const Text('Login'),
                        ),
                      ),
                    ],
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
