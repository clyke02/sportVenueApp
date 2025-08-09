import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/booking.dart';
import '../models/venue.dart';
import '../services/firestore_service.dart';

class BookingProvider with ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  // Cache venues for booking display
  Map<int, Venue> _venueCache = {};

  // Getters
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _bookingSub;

  // Load user bookings (realtime)
  Future<void> loadUserBookings(int userId, {List<Venue>? venues}) async {
    _setLoading(true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _bookings = [];
        _setLoading(false);
        return;
      }

      // Update venue cache if provided
      if (venues != null) {
        _venueCache = {for (var v in venues) v.id: v};
      }

      _bookingSub?.cancel();
      _bookingSub = _fs
          .streamUserBookings(uid)
          .listen(
            (list) {
              _bookings = list.map((m) {
                final booking = Booking.fromMap(m);
                // Enrich with venue data if available
                final venue = _venueCache[booking.venueId];
                return venue != null ? booking.copyWith(venue: venue) : booking;
              }).toList();
              _error = null;
              _setLoading(false);
            },
            onError: (e) {
              // Firestore dapat meminta composite index untuk query ini.
              // Jangan crash; simpan error untuk ditampilkan opsional.
              _error = e.toString();
              _setLoading(false);
            },
          );
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Update venue cache (called by VenueProvider when venues are loaded)
  void updateVenueCache(List<Venue> venues) {
    _venueCache = {for (var v in venues) v.id: v};

    // Re-enrich existing bookings with venue data
    _bookings = _bookings.map((booking) {
      final venue = _venueCache[booking.venueId];
      return venue != null ? booking.copyWith(venue: venue) : booking;
    }).toList();

    notifyListeners();
  }

  // Create new booking
  Future<bool> createBooking({
    required int userId,
    required int venueId,
    required DateTime bookingDate,
    required String timeSlot,
    required int duration,
    required int totalPrice,
    String? notes,
  }) async {
    _setLoading(true);

    try {
      final uid = _auth.currentUser?.uid;
      print(
        '🔄 DEBUG: Creating booking for user ID: $userId, Firebase UID: $uid',
      );
      if (uid == null) {
        print('❌ DEBUG: User not authenticated!');
        _error = 'User not authenticated';
        notifyListeners();
        return false;
      }

      final data = {
        'userId': uid,
        'venueId': venueId,
        'bookingDate': bookingDate.toIso8601String(),
        'timeSlot': timeSlot,
        'duration': duration,
        'totalPrice': totalPrice,
        'status': BookingStatus.pending.index,
        'notes': notes,
      };

      await _fs
          .addBooking(data)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Booking timeout - please check your connection');
            },
          );

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create booking and return the booking object
  Future<Booking?> createBookingWithReturn({
    required int userId,
    required int venueId,
    required DateTime bookingDate,
    required String timeSlot,
    required int duration,
    required int totalPrice,
    String? notes,
  }) async {
    _setLoading(true);

    try {
      final now = DateTime.now();
      final uid = _auth.currentUser?.uid;
      final data = {
        'userId': uid,
        'venueId': venueId,
        'bookingDate': bookingDate.toIso8601String(),
        'timeSlot': timeSlot,
        'duration': duration,
        'totalPrice': totalPrice,
        'status': BookingStatus.pending.index,
        'notes': notes,
      };

      await _fs
          .addBooking(data)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Booking timeout - please check your connection');
            },
          );

      final createdBooking = Booking(
        id: 0,
        userId: userId,
        venueId: venueId,
        bookingDate: bookingDate,
        timeSlot: timeSlot,
        duration: duration,
        totalPrice: totalPrice,
        status: BookingStatus.pending,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      _error = null;
      return createdBooking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(
    int bookingId,
    BookingStatus status,
    int userId,
  ) async {
    // Find booking to get firestoreId
    final booking = _bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => throw Exception('Booking not found'),
    );

    if (booking.firestoreId == null) {
      _error = 'Booking ID not found';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      await _fs.updateBooking(booking.firestoreId!, {'status': status.index});
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get bookings by status
  List<Booking> getBookingsByStatus(BookingStatus status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  // Get upcoming bookings
  List<Booking> getUpcomingBookings() {
    final now = DateTime.now();
    return _bookings
        .where(
          (b) =>
              b.bookingDate.isAfter(now) &&
              (b.status == BookingStatus.pending ||
                  b.status == BookingStatus.confirmed),
        )
        .toList();
  }

  // Get past bookings
  List<Booking> getPastBookings() {
    final now = DateTime.now();
    return _bookings
        .where(
          (b) =>
              b.bookingDate.isBefore(now) ||
              b.status == BookingStatus.cancelled ||
              b.status == BookingStatus.completed,
        )
        .toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
