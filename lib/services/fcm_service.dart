import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'dart:async';

class FCMService {
  static const String _serverUrl =
      'https://fcm-server-production-3ca1.up.railway.app';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _processedMessageIds = {};

  // Inisialisasi FC
  Future<void> initialize() async {
    try {
      print('Memulai inisialisasi FCM..');

      // Request permission dengan opsi yang lebih lengkap
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
        announcement: true,
      );

      print('Status permission FCM: ${settings.authorizationStatus}');
      print('Alert permission: ${settings.alert}');
      print('Badge permission: ${settings.badge}');
      print('Sound permission: ${settings.sound}');

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Set foreground notification presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Menerima pesan saat aplikasi di foreground:');
        print('- Message ID: ${message.messageId}');
        print('- Data: ${message.data}');
        print('- Notification: ${message.notification?.title}');
        print('- Notification Body: ${message.notification?.body}');

        // Check if message was already processed
        if (message.messageId != null &&
            _processedMessageIds.contains(message.messageId)) {
          print(
            'Pesan dengan ID ${message.messageId} sudah diproses sebelumnya, mengabaikan...',
          );
          return;
        }

        // Show notification even in foreground
        if (message.notification != null) {
          // Add message ID to processed set
          if (message.messageId != null) {
            _processedMessageIds.add(message.messageId!);
          }

          // Cancel any existing notification with the same ID
          final NotificationService notificationService = NotificationService();
          notificationService.cancelNotification(message.hashCode);

          notificationService.showNotification(
            id: message.hashCode,
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
            payload: message.data['taskId'] ?? '',
            channelId: 'high_importance_channel',
            channelName: 'High Importance Notifications',
          );
          print('Foreground notification displayed');
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notifikasi di-tap saat aplikasi di background:');
        print('- Message ID: ${message.messageId}');
        print('- Data: ${message.data}');
        _handleNotificationTap(message);
      });

      // Get FCM token
      String? token = await _messaging.getToken();
      print('Token FCM baru: $token');

      if (token != null) {
        print('Mencoba menyimpan token ke Firestore...');
        await _saveTokenToFirestore(token);
      } else {
        print('Error: Tidak berhasil mendapatkan token FCM');
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('Token FCM diperbarui: $newToken');
        _saveTokenToFirestore(newToken);
      });

      // Check token validity periodically
      Timer.periodic(const Duration(hours: 1), (timer) async {
        final currentToken = await _messaging.getToken();
        if (currentToken != null) {
          print('Memeriksa validitas token FCM...');
          await _saveTokenToFirestore(currentToken);
        }
      });

      print('Inisialisasi FCM selesai');
    } catch (e) {
      print('Error saat inisialisasi FCM: $e');
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Handling background message: ${message.messageId}');
    print('Background message data: ${message.data}');
    print('Background message notification: ${message.notification?.title}');
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Handling foreground message: ${message.messageId}');
    print('Foreground message data: ${message.data}');
    print('Foreground message notification: ${message.notification?.title}');
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Notificatio data: ${message.data}');
    // Handle navigation or other actions when notification is tapped
  }

  // Simpan token ke Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('Mencoba menyimpan token untuk user: ${user.uid}');

        // Get user role and email
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'] as String?;
        final email = userDoc.data()?['email'] as String?;

        print('Data user - Role: $role, Email: $email');

        if (role != null) {
          // Create new token data
          final newTokenData = {
            'token': token,
            'role': role,
            'email': email,
            'lastUpdate': FieldValue.serverTimestamp(),
            'deviceInfo': {
              'platform': 'mobile',
              'lastActive': FieldValue.serverTimestamp(),
            },
          };

          // Update Firestore dengan struktur yang benar
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token, // Simpan token tunggal
            'lastLogin': FieldValue.serverTimestamp(),
            'role': role,
            'email': email,
          });

          print('Token berhasil disimpan:');
          print('- User ID: ${user.uid}');
          print('- Role: $role');
          print('- Email: $email');
          print('- Token: $token');
        } else {
          print('Error: Role user tidak ditemukan untuk ${user.uid}');
        }
      } else {
        print('Error: Tidak ada user yang sedang login');
      }
    } catch (e) {
      print('Error saat menyimpan token: $e');
    }
  }

  // Kirim notifikasi
  static Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('Sending FCM notification:');
      print('Token: $token');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');

      final response = await http.post(
        Uri.parse('$_serverUrl/send-fcm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': data,
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
              'priority': 'high',
              'default_sound': true,
              'default_vibrate_timings': true,
              'default_light_settings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'badge': 1, 'content-available': 1},
            },
          },
        }),
      );

      print('FCM Server Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        print('Error data: $errorData');

        // Check if token is invalid
        if (errorData['error']?.toString().contains(
                  'registration-token-not-registered',
                ) ==
                true ||
            errorData['error']?.toString().contains(
                  'Requested entity was not found',
                ) ==
                true) {
          print('Invalid FCM token detected, updating Firestore...');
          await _handleInvalidToken(token);
          return false;
        }

        throw Exception('Failed to send FCM notification: ${response.body}');
      }

      print('FCM notification sent successfully');
      return true;
    } catch (e) {
      print('Error sending FCM notification: $e');
      return false;
    }
  }

  // Handle invalid token
  static Future<void> _handleInvalidToken(String token) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Find all users with this token
      final usersQuery =
          await firestore
              .collection('users')
              .where('fcmTokens', arrayContains: {'token': token})
              .get();

      for (var doc in usersQuery.docs) {
        final tokens = doc.data()['fcmTokens'] as List<dynamic>;
        final updatedTokens = tokens.where((t) => t['token'] != token).toList();

        await doc.reference.update({
          'fcmTokens': updatedTokens,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        print('Successfully removed invalid token for user ${doc.id}');
      }
    } catch (e) {
      print('Error handling invalid token: $e');
    }
  }

  // Get all valid tokens for all roles
  Future<Map<String, List<Map<String, dynamic>>>> getAllTokens() async {
    try {
      print('Mengambil semua token dari Firestore...');
      final usersQuery = await _firestore.collection('users').get();
      Map<String, List<Map<String, dynamic>>> roleTokens = {
        'pm': [],
        'pic': [],
        'admin': [],
      };

      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        final role = userData['role'] as String?;
        final token =
            userData['fcmToken'] as String?; // Menggunakan fcmToken tunggal
        final email = userData['email'] as String?;

        print('Memproses user:');
        print('- ID: ${doc.id}');
        print('- Role: $role');
        print('- Email: $email');
        print('- Token: $token');

        if (role != null && token != null && roleTokens.containsKey(role)) {
          roleTokens[role]!.add({
            'token': token,
            'email': email,
            'userId': doc.id,
            'lastUpdate': userData['lastLogin'],
          });
        }
      }

      // Log tokens for debugging
      print('\nRingkasan token per role:');
      for (var role in roleTokens.keys) {
        print('\nRole $role:');
        if (roleTokens[role]!.isEmpty) {
          print('- Tidak ada token');
        } else {
          for (var tokenData in roleTokens[role]!) {
            print('- Email: ${tokenData['email']}');
            print('  Token: ${tokenData['token']}');
            print('  User ID: ${tokenData['userId']}');
          }
        }
      }

      return roleTokens;
    } catch (e) {
      print('Error saat mengambil token: $e');
      return {'pm': [], 'pic': [], 'admin': []};
    }
  }
}
