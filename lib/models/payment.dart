import 'package:uuid/uuid.dart';

enum PaymentStatus { pending, processing, success, failed, expired }

enum PaymentMethod { qris, bankTransfer, eWallet, creditCard }

class Payment {
  final String id;
  final int bookingId;
  final int amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? qrCodeData;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? notes;

  Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    this.qrCodeData,
    required this.createdAt,
    this.expiresAt,
    this.completedAt,
    this.transactionId,
    this.notes,
  });

  // Generate new payment with unique ID
  factory Payment.create({
    required int bookingId,
    required int amount,
    required PaymentMethod method,
    String? notes,
  }) {
    const uuid = Uuid();
    final now = DateTime.now();

    return Payment(
      id: uuid.v4(),
      bookingId: bookingId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)), // 15 menit expired
      notes: notes,
    );
  }

  // Generate QR code data for payment
  String generateQRData() {
    // Format QR data untuk QRIS (Indonesian QR Payment Standard)
    // Ini adalah format sederhana, dalam implementasi nyata akan lebih kompleks

    // Convert to JSON-like string for QR
    return 'SPORTVENUE://payment?'
        'id=$id&'
        'amount=$amount&'
        'booking=$bookingId&'
        'expires=${expiresAt?.millisecondsSinceEpoch}&'
        'merchant=SPORTVENUE_001';
  }

  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Menunggu Pembayaran';
      case PaymentStatus.processing:
        return 'Memproses Pembayaran';
      case PaymentStatus.success:
        return 'Pembayaran Berhasil';
      case PaymentStatus.failed:
        return 'Pembayaran Gagal';
      case PaymentStatus.expired:
        return 'Pembayaran Kadaluarsa';
    }
  }

  String get methodText {
    switch (method) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
      case PaymentMethod.creditCard:
        return 'Kartu Kredit';
    }
  }

  String get formattedAmount => 'Rp ${_formatPrice(amount)}';

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get canBePaid {
    return status == PaymentStatus.pending && !isExpired;
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'amount': amount,
      'method': method.index,
      'status': status.index,
      'qr_code_data': qrCodeData,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'transaction_id': transactionId,
      'notes': notes,
    };
  }

  // Convert from Map (database)
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      bookingId: map['booking_id'] ?? 0,
      amount: map['amount'] ?? 0,
      method: PaymentMethod.values[map['method'] ?? 0],
      status: PaymentStatus.values[map['status'] ?? 0],
      qrCodeData: map['qr_code_data'],
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      transactionId: map['transaction_id'],
      notes: map['notes'],
    );
  }

  // Create copy with updated fields
  Payment copyWith({
    String? id,
    int? bookingId,
    int? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? qrCodeData,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    String? transactionId,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
    );
  }
}
