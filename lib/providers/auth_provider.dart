import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Check if user is already logged in (Firebase Auth persistence)
  Future<void> checkAuthState() async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // User is already logged in via Firebase
        final snap = await _firestore.collection('users').doc(user.uid).get();
        final data = snap.data();
        if (data != null) {
          _currentUser = User(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch,
            name: data['name'] ?? user.email ?? 'User',
            email: user.email ?? '',
            phone: data['phone'],
            profileImageUrl: data['profileImageUrl'],
            createdAt: (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: (data['updatedAt'] is Timestamp)
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
          );
          _error = null;
        }
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      _error = 'Error checking login state';
    } finally {
      _setLoading(false);
    }
    notifyListeners(); // Penting: notify UI bahwa state sudah diupdate
  }

  // Login with FirebaseAuth + Firestore
  Future<bool> login(String email, String password) async {
    _setLoading(true);

    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        _error = 'Email dan password tidak boleh kosong';
        return false;
      }

      if (!_isValidEmail(email)) {
        _error = 'Format email tidak valid';
        return false;
      }

      if (password.length < 6) {
        _error = 'Password minimal 6 karakter';
        return false;
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil profil user dari Firestore
      final uid = credential.user!.uid;
      final snap = await _firestore.collection('users').doc(uid).get();
      final data = snap.data();
      if (data == null) {
        _error = 'Profil pengguna tidak ditemukan di Firestore';
        return false;
      }

      _currentUser = User(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch,
        name: data['name'] ?? credential.user!.email ?? 'User',
        email: credential.user!.email ?? email,
        phone: data['phone'],
        profileImageUrl: data['profileImageUrl'],
        createdAt: (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: (data['updatedAt'] is Timestamp)
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
      _error = null;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors using error codes
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          _error = 'Email atau password salah. Silakan coba lagi.';
          break;
        case 'invalid-email':
          _error = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          _error = 'Akun ini telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          _error = 'Terlalu banyak percobaan login. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          _error = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
          break;
        default:
          _error = 'Email atau password salah. Silakan coba lagi.';
      }

      // Debug: print actual error for development
      debugPrint('Login error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      // Handle other errors
      _error = 'Terjadi kesalahan. Silakan coba lagi.';
      debugPrint('Unexpected login error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register dengan FirebaseAuth + simpan profil di Firestore
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    _setLoading(true);

    try {
      // Validate input
      if (name.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        _error = 'Semua field harus diisi';
        return false;
      }

      if (name.length < 2) {
        _error = 'Nama minimal 2 karakter';
        return false;
      }

      if (!_isValidEmail(email)) {
        _error = 'Format email tidak valid';
        return false;
      }

      if (password.length < 6) {
        _error = 'Password minimal 6 karakter';
        return false;
      }

      if (password != confirmPassword) {
        _error = 'Password dan konfirmasi password tidak sama';
        return false;
      }
      // Buat akun di Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan profil dasar di Firestore
      final uid = credential.user!.uid;
      final now = DateTime.now();
      await _firestore.collection('users').doc(uid).set({
        'id': now.millisecondsSinceEpoch,
        'name': name,
        'email': email,
        'phone': null,
        'profileImageUrl': null,
        'createdAt': now,
        'updatedAt': now,
      });

      _currentUser = User(
        id: now.millisecondsSinceEpoch,
        name: name,
        email: email,
        createdAt: now,
        updatedAt: now,
      );
      _error = null;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors for registration
      switch (e.code) {
        case 'email-already-in-use':
          _error =
              'Email sudah terdaftar. Silakan gunakan email lain atau login.';
          break;
        case 'weak-password':
          _error =
              'Password terlalu lemah. Gunakan kombinasi huruf, angka, dan simbol.';
          break;
        case 'invalid-email':
          _error = 'Format email tidak valid.';
          break;
        case 'operation-not-allowed':
          _error = 'Pendaftaran dengan email tidak diizinkan.';
          break;
        case 'network-request-failed':
          _error = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
          break;
        default:
          _error = 'Pendaftaran gagal. Silakan coba lagi.';
      }

      debugPrint('Register error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan. Silakan coba lagi.';
      debugPrint('Unexpected register error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    _setLoading(true);

    try {
      // In real app, you would update user in database
      _currentUser = updatedUser.copyWith(updatedAt: DateTime.now());
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper methods
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Legacy password helpers (tidak terpakai setelah migrasi ke FirebaseAuth)

  // Tetap dibiarkan jika masih ada kode lama yang memanggilnya, namun tidak digunakan.

  // Tidak perlu lagi createTestUsers jika memakai Firebase
}
