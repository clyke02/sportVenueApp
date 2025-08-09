class SportCategory {
  final String id;
  final String name;
  final String icon;
  final String displayName;

  SportCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.displayName,
  });

  static List<SportCategory> getDefaultCategories() {
    return [
      SportCategory(
        id: 'football',
        name: 'SEPAKBOLA',
        icon: '⚽',
        displayName: 'Football',
      ),
      SportCategory(
        id: 'basketball',
        name: 'BASKET',
        icon: '🏀',
        displayName: 'Basketball',
      ),
      SportCategory(
        id: 'volleyball',
        name: 'VOLI',
        icon: '🏐',
        displayName: 'Volleyball',
      ),
      SportCategory(
        id: 'badminton',
        name: 'BULUTANGKIS',
        icon: '🏸',
        displayName: 'Badminton',
      ),
      SportCategory(
        id: 'tennis',
        name: 'TENIS LAPANG',
        icon: '🎾',
        displayName: 'Tennis',
      ),
      SportCategory(
        id: 'futsal',
        name: 'FUTSAL',
        icon: '⚽',
        displayName: 'Futsal',
      ),
    ];
  }
}
