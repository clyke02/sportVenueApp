import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/venue.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../models/payment.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'sportvenue.db');

    return await openDatabase(
      path,
      version: 4, // Updated version - removed default John Doe user
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // Optimisasi: Enable WAL mode untuk performa read yang lebih baik
      onConfigure: (db) async {
        try {
          // Gunakan rawQuery untuk PRAGMA karena sebagian mengembalikan row
          await db.rawQuery('PRAGMA journal_mode=WAL');
          await db.rawQuery('PRAGMA synchronous=NORMAL');
          await db.rawQuery('PRAGMA temp_store=MEMORY');
        } catch (e) {
          if (kDebugMode) {
            debugPrint('SQLite PRAGMA setup skipped: $e');
          }
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create venues table
    await db.execute('''
      CREATE TABLE venues(
        id INTEGER PRIMARY KEY,
        kode_provinsi TEXT,
        nama_provinsi TEXT,
        bps_kode_kabupaten_kota TEXT,
        bps_nama_kabupaten_kota TEXT,
        bps_kode_kecamatan TEXT,
        bps_nama_kecamatan TEXT,
        bps_kode_desa_kelurahan TEXT,
        bps_desa_kelurahan TEXT,
        kemendagri_kode_kecamatan TEXT,
        kemendagri_nama_kecamatan TEXT,
        kemendagri_kode_desa_kelurahan TEXT,
        kemendagri_nama_desa_kelurahan TEXT,
        nama_prasarana_olahraga TEXT,
        alamat TEXT,
        cabang_olahraga TEXT,
        luas_lahan INTEGER,
        satuan TEXT,
        tahun INTEGER,
        rating REAL,
        price INTEGER,
        image_url TEXT
      )
    ''');

    // Create indexes untuk optimisasi query
    await db.execute('''
      CREATE INDEX idx_venues_cabang_olahraga ON venues(cabang_olahraga)
    ''');
    await db.execute('''
      CREATE INDEX idx_venues_rating ON venues(rating DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_venues_search ON venues(nama_prasarana_olahraga, alamat, cabang_olahraga)
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        profile_image_url TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create user_passwords table for storing hashed passwords
    await db.execute('''
      CREATE TABLE user_passwords(
        user_id INTEGER PRIMARY KEY,
        password_hash TEXT NOT NULL,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Create bookings table
    await db.execute('''
      CREATE TABLE bookings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        venue_id INTEGER,
        booking_date TEXT,
        time_slot TEXT,
        duration INTEGER,
        total_price INTEGER,
        status INTEGER,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (venue_id) REFERENCES venues (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id TEXT PRIMARY KEY,
        booking_id INTEGER,
        amount INTEGER,
        method INTEGER,
        status INTEGER,
        qr_code_data TEXT,
        created_at TEXT,
        expires_at TEXT,
        completed_at TEXT,
        transaction_id TEXT,
        notes TEXT,
        FOREIGN KEY (booking_id) REFERENCES bookings (id)
      )
    ''');

    // Don't insert default user anymore - will be created via createTestUsers()
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add payments table in version 2
      await db.execute('''
        CREATE TABLE payments(
          id TEXT PRIMARY KEY,
          booking_id INTEGER,
          amount INTEGER,
          method INTEGER,
          status INTEGER,
          qr_code_data TEXT,
          created_at TEXT,
          expires_at TEXT,
          completed_at TEXT,
          transaction_id TEXT,
          notes TEXT,
          FOREIGN KEY (booking_id) REFERENCES bookings (id)
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add user_passwords table in version 3
      await db.execute('''
        CREATE TABLE user_passwords(
          user_id INTEGER PRIMARY KEY,
          password_hash TEXT NOT NULL,
          created_at TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    }

    if (oldVersion < 4) {
      // Remove default John Doe user in version 4
      await db.delete(
        'users',
        where: 'email = ?',
        whereArgs: ['john@example.com'],
      );
      await db.delete(
        'user_passwords',
        where: 'user_id IN (SELECT id FROM users WHERE email = ?)',
        whereArgs: ['john@example.com'],
      );
    }
  }

  // Venue operations
  Future<int> insertVenue(Venue venue) async {
    final db = await database;
    return await db.insert('venues', venue.toMap());
  }

  Future<List<Venue>> getAllVenues() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('venues');
    return List.generate(maps.length, (i) => Venue.fromMap(maps[i]));
  }

  Future<List<Venue>> getVenuesBySport(String sport) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'venues',
      where: 'cabang_olahraga LIKE ?',
      whereArgs: ['%$sport%'],
    );
    return List.generate(maps.length, (i) => Venue.fromMap(maps[i]));
  }

  Future<List<Venue>> searchVenues(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'venues',
      where:
          'nama_prasarana_olahraga LIKE ? OR alamat LIKE ? OR cabang_olahraga LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Venue.fromMap(maps[i]));
  }

  Future<Venue?> getVenueById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'venues',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Venue.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Venue>> getPopularVenues({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'venues',
      orderBy: 'rating DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Venue.fromMap(maps[i]));
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Booking operations
  Future<int> insertBooking(Booking booking) async {
    final db = await database;
    try {
      // Create a map without the id field for insertion
      final bookingMap = booking.toMap();
      bookingMap.remove('id'); // Remove id to let AUTOINCREMENT handle it

      final id = await db.insert('bookings', bookingMap);
      return id;
    } catch (e) {
      debugPrint('Error inserting booking: $e');
      throw Exception('Failed to insert booking: $e');
    }
  }

  Future<List<Booking>> getBookingsByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'booking_date DESC',
    );
    return List.generate(maps.length, (i) => Booking.fromMap(maps[i]));
  }

  Future<List<Booking>> getBookingsWithVenues(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT b.*, v.nama_prasarana_olahraga, v.alamat, v.cabang_olahraga, v.rating, v.price
      FROM bookings b
      LEFT JOIN venues v ON b.venue_id = v.id
      WHERE b.user_id = ?
      ORDER BY b.booking_date DESC
    ''',
      [userId],
    );

    List<Booking> bookings = [];
    for (var map in maps) {
      Booking booking = Booking.fromMap(map);
      if (map['nama_prasarana_olahraga'] != null) {
        Venue venue = Venue(
          id: booking.venueId,
          kodeProvinsi: '',
          namaProvinsi: '',
          bpsKodeKabupatenKota: '',
          bpsNamaKabupatenKota: '',
          bpsKodeKecamatan: '',
          bpsNamaKecamatan: '',
          bpsKodeDesaKelurahan: '',
          bpsDesaKelurahan: '',
          kemendagriKodeKecamatan: '',
          kemendagriNamaKecamatan: '',
          kemendagriKodeDesaKelurahan: '',
          kemendagriNamaDesaKelurahan: '',
          namaPrasaranaOlahraga: map['nama_prasarana_olahraga'] ?? '',
          alamat: map['alamat'] ?? '',
          cabangOlahraga: map['cabang_olahraga'] ?? '',
          luasLahan: 0,
          satuan: '',
          tahun: 2022,
          rating: map['rating']?.toDouble() ?? 4.0,
          price: map['price'] ?? 0,
        );
        booking = booking.copyWith(venue: venue);
      }
      bookings.add(booking);
    }
    return bookings;
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await database;
    return await db.update(
      'bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  // Utility methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('venues');
    await db.delete('bookings');
    await db.delete('payments');
    await db.delete('user_passwords');
    // Don't delete users table to keep registered users
  }

  // Payment CRUD operations
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toMap());
    return 1; // Return success
  }

  Future<Payment?> getPayment(String paymentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [paymentId],
    );

    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<Payment?> getPaymentByBookingId(int bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Payment>> getPaymentsByStatus(PaymentStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(String paymentId) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
  }

  // Update expired payments
  Future<void> updateExpiredPayments() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'payments',
      {'status': PaymentStatus.expired.index},
      where: 'status = ? AND expires_at < ?',
      whereArgs: [PaymentStatus.pending.index, now],
    );
  }

  // Reset database (for development/testing)
  Future<void> resetDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'sportvenue.db');

    await deleteDatabase(path);
    _database = null; // Reset instance

    // Reinitialize
    await database;
  }

  // Password management methods
  Future<void> storeUserPassword(int userId, String hashedPassword) async {
    final db = await database;
    await db.insert('user_passwords', {
      'user_id': userId,
      'password_hash': hashedPassword,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getUserPasswordHash(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_passwords',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first['password_hash'] as String?;
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
