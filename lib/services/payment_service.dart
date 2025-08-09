import 'dart:math';
import '../models/payment.dart';
import '../models/booking.dart';
import 'firestore_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // Mock API endpoints - dalam implementasi nyata akan menggunakan API payment gateway
  // static const String _baseUrl = 'https://api.sportvenue.com/v1';
  // static const String _apiKey = 'mock_api_key_sportvenue';

  /// Generate QR code untuk pembayaran
  Future<Payment> generateQRPayment({
    required Booking booking,
    required PaymentMethod method,
    String? notes,
  }) async {
    try {
      // Create payment record
      final payment = Payment.create(
        bookingId: booking.id,
        amount: booking.totalPrice,
        method: method,
        notes: notes,
      );

      // Generate QR data
      final qrData = payment.generateQRData();
      final updatedPayment = payment.copyWith(qrCodeData: qrData);

      // Save to Firestore
      await _firestoreService.setPayment(
        updatedPayment.id,
        updatedPayment.toMap(),
      );

      // Mock API call untuk register payment ke payment gateway
      await _registerPaymentToGateway(updatedPayment);

      return updatedPayment;
    } catch (e) {
      throw PaymentException('Failed to generate QR payment: $e');
    }
  }

  /// Check status pembayaran dari API (Optimized - Mock only)
  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    try {
      // Simplified mock: return random status for demo
      await Future.delayed(const Duration(milliseconds: 500));
      final statuses = [
        PaymentStatus.pending,
        PaymentStatus.success,
        PaymentStatus.failed,
      ];
      final randomStatus = statuses[Random().nextInt(statuses.length)];
      return randomStatus;
    } catch (e) {
      throw PaymentException('Error checking payment status: $e');
    }
  }

  /// Simulasi pembayaran berhasil (untuk testing) - Optimized
  Future<bool> simulatePaymentSuccess(String paymentId) async {
    try {
      // Mock success - in real app would update Firestore
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get payment by booking ID - Optimized Mock
  Future<Payment?> getPaymentByBookingId(int bookingId) async {
    // Mock implementation - would query Firestore in real app
    return null;
  }

  /// Cancel payment - Optimized Mock
  Future<bool> cancelPayment(String paymentId) async {
    try {
      // Mock cancellation
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get available payment methods
  List<PaymentMethodInfo> getAvailablePaymentMethods() {
    return [
      PaymentMethodInfo(
        method: PaymentMethod.qris,
        name: 'QRIS',
        description: 'Bayar dengan scan QR code',
        icon: '📱',
        processingTime: 'Instant',
        fee: 0,
      ),
      PaymentMethodInfo(
        method: PaymentMethod.bankTransfer,
        name: 'Transfer Bank',
        description: 'Transfer ke rekening virtual',
        icon: '🏦',
        processingTime: '1-10 menit',
        fee: 2500,
      ),
      PaymentMethodInfo(
        method: PaymentMethod.eWallet,
        name: 'E-Wallet',
        description: 'OVO, GoPay, Dana, ShopeePay',
        icon: '💳',
        processingTime: 'Instant',
        fee: 0,
      ),
      PaymentMethodInfo(
        method: PaymentMethod.creditCard,
        name: 'Kartu Kredit',
        description: 'Visa, MasterCard, JCB',
        icon: '💳',
        processingTime: 'Instant',
        fee: 0,
      ),
    ];
  }

  // Private methods

  Future<Map<String, dynamic>> _registerPaymentToGateway(
    Payment payment,
  ) async {
    // Mock API registration
    return await _mockApiCall(
      '/payments/register',
      body: {
        'payment_id': payment.id,
        'amount': payment.amount,
        'method': payment.method.name,
        'booking_id': payment.bookingId,
        'expires_at': payment.expiresAt?.toIso8601String(),
      },
    );
  }

  Future<Map<String, dynamic>> _mockApiCall(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: Random().nextInt(1000) + 500));

    // Mock different responses based on endpoint
    if (endpoint.contains('/status')) {
      // For status check, simulate payment progression over time
      final random = Random().nextInt(100);
      String status;

      // Simulate more realistic payment flow - higher success rate after some time
      if (random < 10) {
        status = 'pending'; // 10% still pending
      } else if (random < 20) {
        status = 'processing'; // 10% processing
      } else if (random < 85) {
        status = 'success'; // 65% success - much higher!
      } else {
        status = 'failed'; // 15% failed
      }

      return {
        'success': true,
        'data': {
          'status': status,
          'transaction_id': _generateTransactionId(),
          'payment_url':
              'https://payment.gateway.com/pay/${Random().nextInt(100000)}',
        },
        'message': 'Status retrieved successfully',
      };
    } else {
      // For initial registration, always return pending
      return {
        'success': true,
        'data': {
          'status': 'pending',
          'transaction_id': _generateTransactionId(),
          'payment_url':
              'https://payment.gateway.com/pay/${Random().nextInt(100000)}',
        },
        'message': 'Payment registered successfully',
      };
    }
  }

  // Removed unused _parsePaymentStatus method

  String _generateTransactionId() {
    final now = DateTime.now();
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'TXN${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$random';
  }
}

// Helper class untuk payment method info
class PaymentMethodInfo {
  final PaymentMethod method;
  final String name;
  final String description;
  final String icon;
  final String processingTime;
  final int fee;

  PaymentMethodInfo({
    required this.method,
    required this.name,
    required this.description,
    required this.icon,
    required this.processingTime,
    required this.fee,
  });

  String get formattedFee {
    if (fee == 0) return 'Gratis';
    return 'Rp ${fee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}

// Custom exception untuk payment errors
class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}
