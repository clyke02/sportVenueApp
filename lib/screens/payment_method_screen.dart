import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/venue.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import 'qr_payment_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Booking booking;
  final Venue venue;

  const PaymentMethodScreen({
    super.key,
    required this.booking,
    required this.venue,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final PaymentService _paymentService = PaymentService();
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final paymentMethods = _paymentService.getAvailablePaymentMethods();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pilih Metode Pembayaran'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Booking Summary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Pesanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                _buildSummaryRow('Venue', widget.venue.displayName),
                _buildSummaryRow(
                  'Tanggal',
                  '${widget.booking.bookingDate.day}/${widget.booking.bookingDate.month}/${widget.booking.bookingDate.year}',
                ),
                _buildSummaryRow('Waktu', widget.booking.timeSlot),
                _buildSummaryRow('Durasi', '${widget.booking.duration} jam'),

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
                      widget.booking.formattedPrice,
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

          // Payment Methods
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = paymentMethods[index];
                        final isSelected = _selectedMethod == method.method;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFF2196F3,
                                      ).withValues(alpha: 0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  method.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            title: Text(
                              method.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF2196F3)
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  method.description,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      method.processingTime,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.local_offer,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      method.formattedFee,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: method.fee == 0
                                            ? Colors.green
                                            : Colors.grey[600],
                                        fontWeight: method.fee == 0
                                            ? FontWeight.w500
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Radio<PaymentMethod>(
                              value: method.method,
                              groupValue: _selectedMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedMethod = value;
                                });
                              },
                              activeColor: const Color(0xFF2196F3),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedMethod = method.method;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Continue Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _selectedMethod != null && !_isProcessing
                  ? _processPayment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _selectedMethod != null
                          ? 'Lanjutkan Pembayaran'
                          : 'Pilih Metode Pembayaran',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Generate payment with QR code
      final payment = await _paymentService.generateQRPayment(
        booking: widget.booking,
        method: _selectedMethod!,
        notes: 'Pembayaran booking venue ${widget.venue.displayName}',
      );

      if (mounted) {
        // Navigate to QR payment screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QRPaymentScreen(
              payment: payment,
              booking: widget.booking,
              venue: widget.venue,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

