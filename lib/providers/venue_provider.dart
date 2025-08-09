import 'package:flutter/foundation.dart';
import '../models/venue.dart';
import '../models/sport_category.dart';
import 'dart:async';
import '../services/firestore_service.dart';

class VenueProvider with ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  List<Venue> _allVenues = [];
  List<Venue> _filteredVenues = [];
  List<Venue> _popularVenues = [];
  final List<SportCategory> _sportCategories =
      SportCategory.getDefaultCategories();

  // Callback untuk update booking provider
  Function(List<Venue>)? _onVenuesUpdated;

  bool _isLoading = false;
  String? _error;
  String _selectedSport = '';
  String _searchQuery = '';

  // Getters
  List<Venue> get allVenues => _allVenues;
  List<Venue> get filteredVenues => _filteredVenues;
  List<Venue> get popularVenues => _popularVenues;
  List<SportCategory> get sportCategories => _sportCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedSport => _selectedSport;
  String get searchQuery => _searchQuery;

  // Set callback for venue updates
  void setVenuesUpdatedCallback(Function(List<Venue>) callback) {
    _onVenuesUpdated = callback;
  }

  // Initialize data dari Firestore (realtime)
  StreamSubscription? _venueSub;

  Future<void> initializeData() async {
    _setLoading(true);
    try {
      _venueSub?.cancel();
      _venueSub = _fs.streamVenues(limit: 50).listen((list) async {
        // Process venues from stream (no auto-import here, handled by SplashScreen)
        final venues = list.map((m) => Venue.fromMap(m)).toList();

        // Optimize: Remove duplicates and sort in single pass
        final Map<String, Venue> uniqueVenues = {};
        for (final venue in venues) {
          final key =
              '${venue.namaPrasaranaOlahraga}_${venue.bpsNamaKecamatan}';
          if (!uniqueVenues.containsKey(key) ||
              venue.rating > uniqueVenues[key]!.rating) {
            uniqueVenues[key] = venue;
          }
        }

        _allVenues = uniqueVenues.values.toList()
          ..sort((a, b) => b.rating.compareTo(a.rating)); // Sort once

        // Take top venues for popular list (already sorted)
        _popularVenues = _allVenues.take(5).toList();

        _filteredVenues = List.from(_allVenues);
        _error = null;
        _setLoading(false);

        // Notify booking provider about venue updates
        _onVenuesUpdated?.call(_allVenues);
      });
    } catch (e) {
      debugPrint('VenueProvider initialization error: $e');
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Background loading tidak diperlukan untuk Firestore realtime

  // Load all venues
  Future<void> loadAllVenues() async {
    try {
      // Sudah realtime via initializeData
      _filteredVenues = List.from(_allVenues);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load popular venues
  Future<void> loadPopularVenues() async {
    try {
      _popularVenues = List.from(_allVenues.take(5));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Filter venues by sport
  Future<void> filterBySport(String sportId) async {
    _selectedSport = sportId;
    _setLoading(true);

    try {
      if (sportId.isEmpty) {
        _filteredVenues = List.from(_allVenues);
      } else {
        // Find the sport category
        SportCategory? category = _sportCategories.firstWhere(
          (cat) => cat.id == sportId,
          orElse: () => SportCategory(
            id: sportId,
            name: sportId,
            icon: '🏃',
            displayName: sportId,
          ),
        );

        _filteredVenues = _allVenues
            .where(
              (v) => v.cabangOlahraga.toLowerCase().contains(
                category.name.toLowerCase(),
              ),
            )
            .toList();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Optimized search venues - no async needed for in-memory filtering
  void searchVenues(String query) {
    _searchQuery = query;
    _setLoading(true);

    try {
      if (query.isEmpty) {
        if (_selectedSport.isEmpty) {
          _filteredVenues = List.from(_allVenues);
        } else {
          _filterBySportSync(_selectedSport);
          return;
        }
      } else {
        final q = query.toLowerCase();
        // Optimize: Use single where clause with OR conditions
        _filteredVenues = _allVenues.where((v) {
          final name = v.displayName.toLowerCase();
          final address = v.alamat.toLowerCase();
          final sport = v.cabangOlahraga.toLowerCase();
          return name.contains(q) || address.contains(q) || sport.contains(q);
        }).toList();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Helper method for synchronous sport filtering
  void _filterBySportSync(String sportId) {
    final category = _sportCategories.firstWhere(
      (c) => c.id == sportId,
      orElse: () => SportCategory(
        id: sportId,
        name: sportId,
        icon: '🏃',
        displayName: sportId,
      ),
    );

    _filteredVenues = _allVenues
        .where(
          (v) => v.cabangOlahraga.toLowerCase().contains(
            category.name.toLowerCase(),
          ),
        )
        .toList();
  }

  // Get venue by ID
  Future<Venue?> getVenueById(int id) async {
    try {
      return _allVenues.firstWhere((v) => v.id == id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _venueSub?.cancel();
    super.dispose();
  }

  // Clear filters
  void clearFilters() {
    _selectedSport = '';
    _searchQuery = '';
    _filteredVenues = List.from(_allVenues);
    notifyListeners();
  }

  // Get venues by category for home screen
  List<Venue> getVenuesByCategory(String category) {
    return _allVenues
        .where(
          (venue) => venue.cabangOlahraga.toUpperCase().contains(
            category.toUpperCase(),
          ),
        )
        .take(5)
        .toList();
  }

  // Get nearby venues (mock implementation)
  List<Venue> getNearbyVenues() {
    // For now, return random venues
    List<Venue> shuffled = List.from(_allVenues);
    shuffled.shuffle();
    return shuffled.take(3).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clean up resources when provider is disposed
  void cleanUp() {
    _venueSub?.cancel();
  }
}
