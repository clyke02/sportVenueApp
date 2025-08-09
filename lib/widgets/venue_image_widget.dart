import 'package:flutter/material.dart';
import '../models/venue.dart';

class VenueImageWidget extends StatelessWidget {
  final Venue venue;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool showSportLabel;

  const VenueImageWidget({
    super.key,
    required this.venue,
    required this.width,
    required this.height,
    this.borderRadius,
    this.showSportLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final int? computedCacheWidth = (width.isFinite && width > 0)
        ? width.round()
        : null;
    final int? computedCacheHeight = (height.isFinite && height > 0)
        ? height.round()
        : null;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(0),
      child: Image.asset(
        venue.imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Optimisasi caching
        cacheWidth: computedCacheWidth,
        cacheHeight: computedCacheHeight,
        errorBuilder: (context, error, stackTrace) {
          // Show simple icon fallback
          return _buildSimpleFallback();
        },
      ),
    );
  }

  Widget _buildSimpleFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(venue.sportColor),
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          // Main sport icon
          Center(
            child: Text(
              venue.sportIcon,
              style: TextStyle(fontSize: height * 0.25, color: Colors.white),
            ),
          ),

          // Sport label di pojok
          if (showSportLabel)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  venue.sport,
                  style: TextStyle(
                    color: Color(venue.sportColor),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Removed unused _buildFallbackImage method
}
