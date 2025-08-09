import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking.dart';
import 'payment_method_screen.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Consumer2<BookingProvider, AuthProvider>(
        builder: (context, bookingProvider, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(child: Text('Please login to view bookings'));
          }

          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming bookings
              _buildBookingsList(bookingProvider.getUpcomingBookings()),
              // Past bookings
              _buildBookingsList(bookingProvider.getPastBookings()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a venue to see it here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return GestureDetector(
      onTap: () => _showBookingDetails(booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.venue?.displayName ?? 'Unknown Venue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),

              const SizedBox(height: 8),

              // Venue details
              if (booking.venue != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.venue!.sport,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.venue!.location,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],

              // Booking details
              Row(
                children: [
                  Expanded(
                    child: _buildBookingDetail(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                    ),
                  ),
                  Expanded(
                    child: _buildBookingDetail(
                      Icons.access_time,
                      'Time',
                      booking.timeSlot,
                    ),
                  ),
                  Expanded(
                    child: _buildBookingDetail(
                      Icons.schedule,
                      'Duration',
                      '${booking.duration}h',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Price and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.formattedPrice,
                    style: const TextStyle(
                      color: Color(0xFF00C851),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildActionButtons(booking),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  Widget _buildBookingDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Booking booking) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.status == BookingStatus.pending) ...[
          TextButton(
            onPressed: () {
              _navigateToPayment(booking);
            },
            child: const Text('Pay Now', style: TextStyle(color: Colors.green)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              _cancelBooking(booking);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ] else if (booking.status == BookingStatus.confirmed) ...[
          TextButton(
            onPressed: () {
              _showBookingDetails(booking);
            },
            child: const Text('Details'),
          ),
        ] else if (booking.status == BookingStatus.completed) ...[
          TextButton(
            onPressed: () {
              _showReviewDialog(booking);
            },
            child: const Text('Review'),
          ),
        ],
      ],
    );
  }

  void _navigateToPayment(Booking booking) {
    if (booking.venue != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              PaymentMethodScreen(booking: booking, venue: booking.venue!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venue information not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider = context.read<AuthProvider>();
                context.read<BookingProvider>().updateBookingStatus(
                  booking.id,
                  BookingStatus.cancelled,
                  authProvider.currentUser!.id,
                );
              },
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Booking Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Add more booking details here
                  Text('Booking ID: #${booking.id}'),
                  const SizedBox(height: 8),
                  Text('Venue: ${booking.venue?.displayName ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(booking.bookingDate)}',
                  ),
                  const SizedBox(height: 8),
                  Text('Time: ${booking.timeSlot}'),
                  const SizedBox(height: 8),
                  Text('Duration: ${booking.duration} hours'),
                  const SizedBox(height: 8),
                  Text('Total Price: ${booking.formattedPrice}'),

                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(booking.notes!),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate Your Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your experience at ${booking.venue?.displayName}?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      // Handle rating
                    },
                    icon: const Icon(Icons.star_border, color: Colors.amber),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle review submission
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
