import 'user.dart';
import 'venue.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }

class Booking {
  final int id;
  final int userId;
  final int venueId;
  final DateTime bookingDate;
  final String timeSlot;
  final int duration; // in hours
  final int totalPrice;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Navigation properties (not stored in database)
  final User? user;
  final Venue? venue;

  // Firestore document ID (string)
  final String? firestoreId;

  Booking({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.bookingDate,
    required this.timeSlot,
    required this.duration,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.venue,
    this.firestoreId,
  });

  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Menunggu Konfirmasi';
      case BookingStatus.confirmed:
        return 'Dikonfirmasi';
      case BookingStatus.cancelled:
        return 'Dibatalkan';
      case BookingStatus.completed:
        return 'Selesai';
    }
  }

  String get formattedPrice => 'Rp ${_formatPrice(totalPrice)}';

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'venue_id': venueId,
      'booking_date': bookingDate.toIso8601String(),
      'time_slot': timeSlot,
      'duration': duration,
      'total_price': totalPrice,
      'status': status.index,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert from Map (database) - compatible with both SQLite and Firestore
  factory Booking.fromMap(Map<String, dynamic> map) {
    // For Firestore, use a hash of the document ID as numeric ID
    int numericId = 0;
    String? firestoreId;

    if (map['id'] is String) {
      firestoreId = map['id'];
      // Generate consistent numeric ID from string
      numericId = map['id'].hashCode.abs();
    } else {
      numericId = _parseInt(map['id']) ?? 0;
    }

    return Booking(
      id: numericId,
      userId: _parseInt(map['userId'] ?? map['user_id']) ?? 0,
      venueId: _parseInt(map['venueId'] ?? map['venue_id']) ?? 0,
      bookingDate: _parseDateTime(map['bookingDate'] ?? map['booking_date']),
      timeSlot: map['timeSlot'] ?? map['time_slot'] ?? '',
      duration: _parseInt(map['duration']) ?? 1,
      totalPrice: _parseInt(map['totalPrice'] ?? map['total_price']) ?? 0,
      status: BookingStatus.values[_parseInt(map['status']) ?? 0],
      notes: map['notes'],
      createdAt: _parseDateTime(map['createdAt'] ?? map['created_at']),
      updatedAt: _parseDateTime(map['updatedAt'] ?? map['updated_at']),
      firestoreId: firestoreId,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Handle Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate();
    }
    return DateTime.now();
  }

  // Create copy with updated fields
  Booking copyWith({
    int? id,
    int? userId,
    int? venueId,
    DateTime? bookingDate,
    String? timeSlot,
    int? duration,
    int? totalPrice,
    BookingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? user,
    Venue? venue,
    String? firestoreId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      venueId: venueId ?? this.venueId,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      duration: duration ?? this.duration,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      venue: venue ?? this.venue,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }
}
