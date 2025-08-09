class VenueImageHelper {
  // Default placeholder images berdasarkan jenis olahraga
  static const Map<String, String> _sportImageMap = {
    'futsal': 'assets/images/venues/futsal.jpg',
    'football': 'assets/images/venues/football.jpg',
    'sepakbola': 'assets/images/venues/football.jpg',
    'basket': 'assets/images/venues/basketball.jpg',
    'basketball': 'assets/images/venues/basketball.jpg',
    'bola basket': 'assets/images/venues/basketball.jpg',
    'badminton': 'assets/images/venues/badminton.jpg',
    'bulutangkis': 'assets/images/venues/badminton.jpg',
    'tenis': 'assets/images/venues/tennis.jpg',
    'tennis': 'assets/images/venues/tennis.jpg',
    'voli': 'assets/images/venues/volleyball.jpg',
    'volleyball': 'assets/images/venues/volleyball.jpg',
    'bola voli': 'assets/images/venues/volleyball.jpg',
    'renang': 'assets/images/venues/swimming.jpg',
    'swimming': 'assets/images/venues/swimming.jpg',
    'kolam renang': 'assets/images/venues/swimming.jpg',
    'atletik': 'assets/images/venues/athletics.jpg',
    'athletics': 'assets/images/venues/athletics.jpg',
    'lari': 'assets/images/venues/athletics.jpg',
    'gym': 'assets/images/venues/gym.jpg',
    'fitness': 'assets/images/venues/gym.jpg',
    'senam': 'assets/images/venues/gym.jpg',
    'default': 'assets/images/venues/default.jpg',
  };

  /// Mendapatkan path gambar berdasarkan cabang olahraga
  static String getVenueImage(String? cabangOlahraga) {
    if (cabangOlahraga == null || cabangOlahraga.isEmpty) {
      return _sportImageMap['default']!;
    }

    final sport = cabangOlahraga.toLowerCase().trim();

    // Mapping khusus untuk data CSV Bandung
    if (sport.contains('futsal')) {
      return _sportImageMap['futsal']!;
    } else if (sport.contains('sepakbola')) {
      return _sportImageMap['football']!;
    } else if (sport.contains('basket')) {
      return _sportImageMap['basketball']!;
    } else if (sport.contains('badminton') || sport.contains('bulutangkis')) {
      return _sportImageMap['badminton']!;
    } else if (sport.contains('tenis')) {
      return _sportImageMap['tennis']!;
    } else if (sport.contains('voli')) {
      return _sportImageMap['volleyball']!;
    } else if (sport.contains('renang')) {
      return _sportImageMap['swimming']!;
    } else if (sport.contains('atletik') || sport.contains('lari')) {
      return _sportImageMap['athletics']!;
    } else if (sport.contains('gym') ||
        sport.contains('fitness') ||
        sport.contains('senam')) {
      return _sportImageMap['gym']!;
    } else if (sport.contains('softball')) {
      return _sportImageMap['athletics']!; // Use athletics for softball
    } else if (sport.contains('squash')) {
      return _sportImageMap['tennis']!; // Use tennis for squash
    } else if (sport.contains('takraw')) {
      return _sportImageMap['volleyball']!; // Use volleyball for takraw
    } else if (sport.contains('tembak')) {
      return _sportImageMap['athletics']!; // Use athletics for shooting
    } else if (sport.contains('beladiri')) {
      return _sportImageMap['gym']!; // Use gym for martial arts
    }

    // Cari exact match
    if (_sportImageMap.containsKey(sport)) {
      return _sportImageMap[sport]!;
    }

    // Cari partial match
    for (final entry in _sportImageMap.entries) {
      if (sport.contains(entry.key) || entry.key.contains(sport)) {
        return entry.value;
      }
    }

    // Return default jika tidak ditemukan
    return _sportImageMap['default']!;
  }

  /// Mendapatkan semua jenis olahraga yang tersedia
  static List<String> getSupportedSports() {
    return _sportImageMap.keys.where((key) => key != 'default').toList();
  }

  /// Mendapatkan icon berdasarkan cabang olahraga
  static String getSportIcon(String? cabangOlahraga) {
    if (cabangOlahraga == null || cabangOlahraga.isEmpty) {
      return '⚽';
    }

    final sport = cabangOlahraga.toLowerCase().trim();

    if (sport.contains('futsal')) {
      return '⚽';
    } else if (sport.contains('sepakbola') || sport.contains('football')) {
      return '🏈';
    } else if (sport.contains('basket')) {
      return '🏀';
    } else if (sport.contains('badminton') || sport.contains('bulutangkis')) {
      return '🏸';
    } else if (sport.contains('tenis') || sport.contains('tennis')) {
      return '🎾';
    } else if (sport.contains('voli') || sport.contains('volleyball')) {
      return '🏐';
    } else if (sport.contains('renang') || sport.contains('swimming')) {
      return '🏊‍♂️';
    } else if (sport.contains('atletik') || sport.contains('lari')) {
      return '🏃‍♂️';
    } else if (sport.contains('gym') ||
        sport.contains('fitness') ||
        sport.contains('senam')) {
      return '💪';
    } else if (sport.contains('softball')) {
      return '🥎';
    } else if (sport.contains('squash')) {
      return '🎾';
    } else if (sport.contains('takraw')) {
      return '🏐';
    } else if (sport.contains('tembak')) {
      return '🎯';
    } else if (sport.contains('beladiri')) {
      return '🥋';
    }

    return '🏟️'; // stadium default
  }

  /// Mendapatkan nama sport yang sudah di-format
  static String getFormattedSportName(String? cabangOlahraga) {
    if (cabangOlahraga == null || cabangOlahraga.isEmpty) {
      return 'Sport Venue';
    }

    final sport = cabangOlahraga.toLowerCase().trim();

    if (sport.contains('futsal')) {
      return 'Futsal Court';
    } else if (sport.contains('sepakbola') || sport.contains('football')) {
      return 'Football Field';
    } else if (sport.contains('basket')) {
      return 'Basketball Court';
    } else if (sport.contains('badminton') || sport.contains('bulutangkis')) {
      return 'Badminton Court';
    } else if (sport.contains('tenis') || sport.contains('tennis')) {
      return 'Tennis Court';
    } else if (sport.contains('voli') || sport.contains('volleyball')) {
      return 'Volleyball Court';
    } else if (sport.contains('renang') || sport.contains('swimming')) {
      return 'Swimming Pool';
    } else if (sport.contains('atletik') || sport.contains('lari')) {
      return 'Athletics Track';
    } else if (sport.contains('gym') ||
        sport.contains('fitness') ||
        sport.contains('senam')) {
      return 'Gym & Fitness';
    }

    return cabangOlahraga; // return original
  }

  /// Mendapatkan warna tema berdasarkan cabang olahraga
  static int getSportColor(String? cabangOlahraga) {
    if (cabangOlahraga == null || cabangOlahraga.isEmpty) {
      return 0xFF2196F3; // Blue
    }

    final sport = cabangOlahraga.toLowerCase().trim();

    if (sport.contains('futsal') ||
        sport.contains('sepakbola') ||
        sport.contains('football')) {
      return 0xFF4CAF50; // Green
    } else if (sport.contains('basket')) {
      return 0xFFFF9800; // Orange
    } else if (sport.contains('badminton') || sport.contains('bulutangkis')) {
      return 0xFFE91E63; // Pink
    } else if (sport.contains('tenis') || sport.contains('tennis')) {
      return 0xFFFFEB3B; // Yellow
    } else if (sport.contains('voli') || sport.contains('volleyball')) {
      return 0xFF9C27B0; // Purple
    } else if (sport.contains('renang') || sport.contains('swimming')) {
      return 0xFF00BCD4; // Cyan
    } else if (sport.contains('atletik') || sport.contains('lari')) {
      return 0xFFFF5722; // Deep Orange
    } else if (sport.contains('gym') ||
        sport.contains('fitness') ||
        sport.contains('senam')) {
      return 0xFF795548; // Brown
    }

    return 0xFF2196F3; // Blue default
  }
}
