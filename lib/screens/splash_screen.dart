import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/venue_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/firestore_csv_import_service.dart';

import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start animations
    _scaleController.forward();
    _rotationController.repeat();

    // Initialize data and navigate after delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Check if user is already logged in (Firebase Auth persistence)
      await context.read<AuthProvider>().checkAuthState();

      // Initialize venue data (Firestore)
      await context.read<VenueProvider>().initializeData();

      // Wait a bit to ensure stream is set up
      await Future.delayed(const Duration(milliseconds: 500));

      // Auto-import CSV ke Firestore sekali jika koleksi venues masih kosong
      final fs = FirestoreService();
      final hasData = await fs.hasVenues();

      if (!hasData) {
        try {
          final csvService = FirestoreCsvImportService();
          await csvService.importVenuesFromCsvAsset();
        } catch (e) {
          // abaikan error import agar tidak menghalangi boot
          debugPrint('CSV import failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }

    // Wait for minimum splash duration
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Check if user is already logged in
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        // User sudah login, langsung ke MainScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // User belum login, ke LoginScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF00C851), Color(0xFFFF9800)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with rotating border
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Trophy icon (top left)
                        Positioned(
                          left: -30,
                          top: -30,
                          child: Icon(
                            Icons.emoji_events,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        // Main logo container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        // Rotating border
                        Positioned(
                          bottom: -24,
                          right: -30,
                          child: AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value * 2 * 3.14159,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.transparent,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // App title and subtitle
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Column(
                              children: [
                                const Text(
                                  'SportVenue',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Book your perfect sports venue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    // Loading indicator
                    Consumer<VenueProvider>(
                      builder: (context, venueProvider, child) {
                        return Column(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              venueProvider.isLoading
                                  ? 'Loading venues...'
                                  : 'Ready to explore!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
