import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  // Mendapatkan user yang sedang login
  User? get currentUser => _auth.currentUser;

  // Stream perubahan status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login dengan email dan password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Login user
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Inisialisasi FCM dan dapatkan token baru
      await _fcmService.initialize();

      // Update status user
      await _updateUserStatus(true);

      // Verifikasi token FCM setelah login
      await FirebaseMessaging.instance.getToken();

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      // Update status user sebelum logout
      await _updateUserStatus(false);

      // Logout
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Update status user
  Future<void> _updateUserStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': isOnline,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Abaikan error
    }
  }

  // Mendapatkan role user
  Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        return userDoc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mendapatkan data user
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        return userDoc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update profil user
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update data user di Firestore
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cek apakah user sudah login
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Mendapatkan ID user
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // Mendapatkan email user
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Mendapatkan nama tampilan user
  String? getUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  // Mendapatkan URL foto user
  String? getUserPhotoURL() {
    return _auth.currentUser?.photoURL;
  }
}
