import '../utils/venue_image_helper.dart';

class Venue {
  final int id;
  final String kodeProvinsi;
  final String namaProvinsi;
  final String bpsKodeKabupatenKota;
  final String bpsNamaKabupatenKota;
  final String bpsKodeKecamatan;
  final String bpsNamaKecamatan;
  final String bpsKodeDesaKelurahan;
  final String bpsDesaKelurahan;
  final String kemendagriKodeKecamatan;
  final String kemendagriNamaKecamatan;
  final String kemendagriKodeDesaKelurahan;
  final String kemendagriNamaDesaKelurahan;
  final String namaPrasaranaOlahraga;
  final String alamat;
  final String cabangOlahraga;
  final int luasLahan;
  final String satuan;
  final int tahun;
  final double rating;
  final int price;
  final String? imageUrl;

  Venue({
    required this.id,
    required this.kodeProvinsi,
    required this.namaProvinsi,
    required this.bpsKodeKabupatenKota,
    required this.bpsNamaKabupatenKota,
    required this.bpsKodeKecamatan,
    required this.bpsNamaKecamatan,
    required this.bpsKodeDesaKelurahan,
    required this.bpsDesaKelurahan,
    required this.kemendagriKodeKecamatan,
    required this.kemendagriNamaKecamatan,
    required this.kemendagriKodeDesaKelurahan,
    required this.kemendagriNamaDesaKelurahan,
    required this.namaPrasaranaOlahraga,
    required this.alamat,
    required this.cabangOlahraga,
    required this.luasLahan,
    required this.satuan,
    required this.tahun,
    this.rating = 4.0,
    this.price = 0,
    this.imageUrl,
  });

  // Helper getters for UI
  String get displayName => namaPrasaranaOlahraga;
  String get location => '$bpsNamaKecamatan, $bpsNamaKabupatenKota';
  String get sport => _mapSportName(cabangOlahraga);
  String get formattedPrice => 'Rp ${_formatPrice(price)}';
  String get imagePath => VenueImageHelper.getVenueImage(cabangOlahraga);
  String get sportIcon => VenueImageHelper.getSportIcon(cabangOlahraga);
  int get sportColor => VenueImageHelper.getSportColor(cabangOlahraga);

  // Map sport names from CSV to display names
  String _mapSportName(String sport) {
    final sportMap = {
      'SEPAKBOLA': 'Football',
      'BASKET': 'Basketball',
      'VOLI': 'Volleyball',
      'BULUTANGKIS': 'Badminton',
      'TENIS LAPANG': 'Tennis',
      'FUTSAL': 'Futsal',
      'SOFTBALL': 'Softball',
      'SQUASH': 'Squash',
      'TEMBAK': 'Shooting',
      'TAKRAW': 'Takraw',
      'VOLI PASIR': 'Beach Volleyball',
      'BELADIRI': 'Martial Arts',
      'HOKI OUTDOOR': 'Hockey',
    };

    for (String key in sportMap.keys) {
      if (sport.toUpperCase().contains(key)) {
        return sportMap[key]!;
      }
    }
    return sport;
  }

  // Format price for display
  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toString();
  }

  // Convert from CSV row
  factory Venue.fromCsvRow(List<dynamic> row) {
    return Venue(
      id: int.tryParse(row[0].toString()) ?? 0,
      kodeProvinsi: row[1].toString(),
      namaProvinsi: row[2].toString(),
      bpsKodeKabupatenKota: row[3].toString(),
      bpsNamaKabupatenKota: row[4].toString(),
      bpsKodeKecamatan: row[5].toString(),
      bpsNamaKecamatan: row[6].toString(),
      bpsKodeDesaKelurahan: row[7].toString(),
      bpsDesaKelurahan: row[8].toString(),
      kemendagriKodeKecamatan: row[9].toString(),
      kemendagriNamaKecamatan: row[10].toString(),
      kemendagriKodeDesaKelurahan: row[11].toString(),
      kemendagriNamaDesaKelurahan: row[12].toString(),
      namaPrasaranaOlahraga: row[13].toString(),
      alamat: row[14].toString(),
      cabangOlahraga: row[15].toString(),
      luasLahan: int.tryParse(row[16].toString()) ?? 0,
      satuan: row[17].toString(),
      tahun: int.tryParse(row[18].toString()) ?? 2022,
      rating: _generateRating(row[13].toString()),
      price: _generatePrice(
        row[15].toString(),
        int.tryParse(row[16].toString()) ?? 0,
      ),
    );
  }

  // Generate realistic rating based on venue name
  static double _generateRating(String venueName) {
    final hash = venueName.hashCode.abs();
    return 3.5 + (hash % 15) / 10.0; // Rating between 3.5 - 5.0
  }

  // Generate realistic price based on sport type and area
  static int _generatePrice(String sport, int area) {
    final basePrices = {
      'SEPAKBOLA': 500000,
      'BASKET': 300000,
      'VOLI': 250000,
      'BULUTANGKIS': 120000,
      'TENIS LAPANG': 200000,
      'FUTSAL': 180000,
      'SOFTBALL': 250000,
      'SQUASH': 150000,
      'TEMBAK': 200000,
      'TAKRAW': 100000,
      'VOLI PASIR': 200000,
      'BELADIRI': 150000,
      'HOKI OUTDOOR': 300000,
    };

    int basePrice = 150000; // default price
    for (String key in basePrices.keys) {
      if (sport.toUpperCase().contains(key)) {
        basePrice = basePrices[key]!;
        break;
      }
    }

    // Adjust price based on area
    double multiplier = 1.0;
    if (area > 20000) {
      multiplier = 1.5;
    } else if (area > 10000) {
      multiplier = 1.3;
    } else if (area > 5000) {
      multiplier = 1.1;
    }

    return (basePrice * multiplier).round();
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_provinsi': kodeProvinsi,
      'nama_provinsi': namaProvinsi,
      'bps_kode_kabupaten_kota': bpsKodeKabupatenKota,
      'bps_nama_kabupaten_kota': bpsNamaKabupatenKota,
      'bps_kode_kecamatan': bpsKodeKecamatan,
      'bps_nama_kecamatan': bpsNamaKecamatan,
      'bps_kode_desa_kelurahan': bpsKodeDesaKelurahan,
      'bps_desa_kelurahan': bpsDesaKelurahan,
      'kemendagri_kode_kecamatan': kemendagriKodeKecamatan,
      'kemendagri_nama_kecamatan': kemendagriNamaKecamatan,
      'kemendagri_kode_desa_kelurahan': kemendagriKodeDesaKelurahan,
      'kemendagri_nama_desa_kelurahan': kemendagriNamaDesaKelurahan,
      'nama_prasarana_olahraga': namaPrasaranaOlahraga,
      'alamat': alamat,
      'cabang_olahraga': cabangOlahraga,
      'luas_lahan': luasLahan,
      'satuan': satuan,
      'tahun': tahun,
      'rating': rating,
      'price': price,
      'image_url': imageUrl,
    };
  }

  // Convert from Map (database)
  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      id: map['id'] ?? 0,
      kodeProvinsi: map['kode_provinsi'] ?? '',
      namaProvinsi: map['nama_provinsi'] ?? '',
      bpsKodeKabupatenKota: map['bps_kode_kabupaten_kota'] ?? '',
      bpsNamaKabupatenKota: map['bps_nama_kabupaten_kota'] ?? '',
      bpsKodeKecamatan: map['bps_kode_kecamatan'] ?? '',
      bpsNamaKecamatan: map['bps_nama_kecamatan'] ?? '',
      bpsKodeDesaKelurahan: map['bps_kode_desa_kelurahan'] ?? '',
      bpsDesaKelurahan: map['bps_desa_kelurahan'] ?? '',
      kemendagriKodeKecamatan: map['kemendagri_kode_kecamatan'] ?? '',
      kemendagriNamaKecamatan: map['kemendagri_nama_kecamatan'] ?? '',
      kemendagriKodeDesaKelurahan: map['kemendagri_kode_desa_kelurahan'] ?? '',
      kemendagriNamaDesaKelurahan: map['kemendagri_nama_desa_kelurahan'] ?? '',
      namaPrasaranaOlahraga: map['nama_prasarana_olahraga'] ?? '',
      alamat: map['alamat'] ?? '',
      cabangOlahraga: map['cabang_olahraga'] ?? '',
      luasLahan: map['luas_lahan'] ?? 0,
      satuan: map['satuan'] ?? '',
      tahun: map['tahun'] ?? 2022,
      rating: map['rating']?.toDouble() ?? 4.0,
      price: map['price'] ?? 0,
      imageUrl: map['image_url'],
    );
  }
}
