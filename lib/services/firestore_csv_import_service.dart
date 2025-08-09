import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/venue.dart';

class FirestoreCsvImportService {
  FirestoreCsvImportService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> importVenuesFromCsvAsset({
    String assetPath = 'assets/data/sarana_olahraga_di_kota_bandung_2.csv',
    int batchSize = 400,
  }) async {
    try {
      // Load CSV
      final csvString = await rootBundle.loadString(assetPath);
      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isNotEmpty) {
        rows.removeAt(0); // header
      }

      int inserted = 0;
      WriteBatch batch = _db.batch();
      int ops = 0;

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 19) {
          print(
            '⚠️ [CSV Import] Row $i skipped: insufficient columns (${row.length})',
          );
          continue;
        }

        try {
          final venue = Venue.fromCsvRow(row);

          // Build keywords sederhana untuk pencarian
          final keywords = <String>{};
          void addWords(String s) {
            for (final w in s.toString().toLowerCase().split(
              RegExp(r'[^a-z0-9]+'),
            )) {
              if (w.isNotEmpty) keywords.add(w);
            }
          }

          addWords(venue.namaPrasaranaOlahraga);
          addWords(venue.alamat);
          addWords(venue.cabangOlahraga);

          // Use deterministic doc ID to prevent duplicates
          final doc = _db.collection('venues').doc('csv_${venue.id}');
          batch.set(doc, {
            'id': venue.id,
            'nama_prasarana_olahraga': venue.namaPrasaranaOlahraga,
            'alamat': venue.alamat,
            'cabang_olahraga': venue.cabangOlahraga,
            'kode_provinsi': venue.kodeProvinsi,
            'nama_provinsi': venue.namaProvinsi,
            'bps_kode_kabupaten_kota': venue.bpsKodeKabupatenKota,
            'bps_nama_kabupaten_kota': venue.bpsNamaKabupatenKota,
            'bps_kode_kecamatan': venue.bpsKodeKecamatan,
            'bps_nama_kecamatan': venue.bpsNamaKecamatan,
            'rating': venue.rating,
            'price': venue.price,
            'image_url': venue.imageUrl,
            'keywords': keywords.toList(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          inserted++;
          ops++;

          if (ops >= batchSize) {
            await batch.commit();
            batch = _db.batch();
            ops = 0;
          }
        } catch (e) {
          debugPrint('Error processing CSV row $i: $e');
        }
      }

      if (ops > 0) {
        await batch.commit();
      }

      return inserted;
    } catch (e) {
      debugPrint('CSV import error: $e');
      rethrow;
    }
  }
}
