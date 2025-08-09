import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  FirestoreService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Venues with optimized caching
  Stream<List<Map<String, dynamic>>> streamVenues({int limit = 50}) {
    return _db
        .collection('venues')
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots(
          includeMetadataChanges: false,
        ) // Optimize: exclude metadata changes
        .map(
          (snap) => snap.docs
              .map(
                (d) => {
                  ...d.data(),
                  'docId': d.id, // Store docId without overwriting numeric 'id'
                },
              )
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> searchVenues(String query) async {
    final snap = await _db
        .collection('venues')
        .where('keywords', arrayContains: query.toLowerCase())
        .limit(20) // Optimize: limit search results
        .get(const GetOptions(source: Source.cache)) // Try cache first
        .catchError(
          (_) => _db
              .collection('venues')
              .where('keywords', arrayContains: query.toLowerCase())
              .limit(20)
              .get(),
        ); // Fallback to server if cache fails
    return snap.docs.map((d) => {...d.data(), 'docId': d.id}).toList();
  }

  // Utility: cek apakah koleksi venues sudah berisi data
  Future<bool> hasVenues() async {
    try {
      final snap = await _db.collection('venues').limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking venues: $e');
      return false;
    }
  }

  // Bookings
  Future<String> addBooking(Map<String, dynamic> data) async {
    try {
      print('🔄 [Firestore] Adding booking to collection...');
      final ref = await _db
          .collection('bookings')
          .add({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));
      print('✅ [Firestore] Booking added successfully: ${ref.id}');
      return ref.id;
    } catch (e) {
      print('❌ [Firestore] Failed to add booking: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> streamUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final docs = s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
          // Sort manually to avoid index requirement
          docs.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            DateTime aDate = aTime is DateTime
                ? aTime
                : (aTime as dynamic).toDate();
            DateTime bDate = bTime is DateTime
                ? bTime
                : (bTime as dynamic).toDate();
            return bDate.compareTo(aDate); // descending
          });
          return docs;
        });
  }

  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) {
    return _db.collection('bookings').doc(bookingId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Payments
  Future<void> setPayment(String id, Map<String, dynamic> data) {
    return _db
        .collection('payments')
        .doc(id)
        .set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> streamPayment(String id) {
    return _db.collection('payments').doc(id).snapshots().map((d) => d.data());
  }
}
