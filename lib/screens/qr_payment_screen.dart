import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/payment.dart';
import '../models/booking.dart';
import '../models/venue.dart';
import '../services/payment_service.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class QRPaymentScreen extends StatefulWidget {
  final Payment payment;
  final Booking booking;
  final Venue venue;

  const QRPaymentScreen({
    super.key,
    required this.payment,
    required this.booking,
    required this.venue,
  });

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  late Timer _statusTimer;
  late Timer _countdownTimer;
  Payment? _currentPayment;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentPayment = widget.payment;
    _calculateTimeRemaining();
    _startStatusPolling();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _statusTimer.cancel();
    _countdownTimer.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    if (_currentPayment?.expiresAt != null) {
      final now = DateTime.now();
      final expiresAt = _currentPayment!.expiresAt!;
      if (now.isBefore(expiresAt)) {
        _timeRemaining = expiresAt.difference(now);
      } else {
        _timeRemaining = Duration.zero;
      }
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentPayment != null) {
        try {
          final status = await _paymentService.checkPaymentStatus(
            _currentPayment!.id,
          );
          if (status == PaymentStatus.success) {
            _showPaymentSuccess();
            timer.cancel();
          } else if (status == PaymentStatus.failed ||
              status == PaymentStatus.expired) {
            _showPaymentFailed(status);
            timer.cancel();
          }
        } catch (e) {
          debugPrint('Error checking payment status: $e');
        }
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining.inSeconds > 0) {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        } else {
          timer.cancel();
          _showPaymentExpired();
        }
      });
    });
  }

  void _showPaymentSuccess() {
    // Update booking status to confirmed
    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (authProvider.currentUser != null) {
      bookingProvider.updateBookingStatus(
        widget.booking.id,
        BookingStatus.confirmed,
        authProvider.currentUser!.id,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Pembayaran Berhasil!',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: const Text(
          'Terima kasih! Pembayaran Anda telah berhasil diproses. Status booking telah diperbarui.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to main screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailed(PaymentStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              status == PaymentStatus.expired
                  ? 'Pembayaran Kadaluarsa'
                  : 'Pembayaran Gagal',
            ),
          ],
        ),
        content: Text(
          status == PaymentStatus.expired
              ? 'Waktu pembayaran telah habis. Silakan buat pesanan baru.'
              : 'Pembayaran gagal diproses. Silakan coba lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentExpired() {
    _showPaymentFailed(PaymentStatus.expired);
  }

  void _simulatePayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulasi Pembayaran'),
        content: const Text(
          'Apakah Anda ingin mensimulasikan pembayaran berhasil? (Hanya untuk testing)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _paymentService.simulatePaymentSuccess(
                _currentPayment!.id,
              );
              if (success) {
                _showPaymentSuccess();
              }
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }

  void _copyQRData() {
    if (_currentPayment?.qrCodeData != null) {
      Clipboard.setData(ClipboardData(text: _currentPayment!.qrCodeData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR data disalin ke clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pembayaran QR'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Countdown Timer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _timeRemaining.inMinutes < 5
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _timeRemaining.inMinutes < 5
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timer,
                    color: _timeRemaining.inMinutes < 5
                        ? Colors.red
                        : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sisa Waktu Pembayaran',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_timeRemaining),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _timeRemaining.inMinutes < 5
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan QR Code untuk Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // QR Code Widget
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: QrImageView(
                      data: _currentPayment?.qrCodeData ?? '',
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Copy QR Data Button
                  TextButton.icon(
                    onPressed: _copyQRData,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Salin Data QR'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow('Venue', widget.venue.displayName),
                  _buildDetailRow(
                    'Tanggal',
                    '${widget.booking.bookingDate.day}/${widget.booking.bookingDate.month}/${widget.booking.bookingDate.year}',
                  ),
                  _buildDetailRow('Waktu', widget.booking.timeSlot),
                  _buildDetailRow('Durasi', '${widget.booking.duration} jam'),
                  _buildDetailRow('Metode', _currentPayment?.methodText ?? ''),

                  const Divider(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentPayment?.formattedAmount ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cara Pembayaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Buka aplikasi mobile banking atau e-wallet\n'
                    '2. Pilih fitur scan QR atau QRIS\n'
                    '3. Arahkan kamera ke QR code di atas\n'
                    '4. Konfirmasi pembayaran di aplikasi Anda\n'
                    '5. Tunggu notifikasi pembayaran berhasil',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Debug: Simulate Payment Button (remove in production)
            if (true) // Set to false in production
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _simulatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Simulasi Pembayaran Berhasil (Testing)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
