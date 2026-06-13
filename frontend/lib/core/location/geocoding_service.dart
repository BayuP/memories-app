import 'package:dio/dio.dart';

// ---------------------------------------------------------------------------
// PlaceSuggestion — value object returned by GeocodingService
// ---------------------------------------------------------------------------

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  /// Full display name from Nominatim (e.g. "Bali, East Nusa Tenggara, Indonesia").
  final String displayName;

  /// WGS-84 latitude.
  final double lat;

  /// WGS-84 longitude.
  final double lng;

  /// Shortened label: first 3 comma-separated parts of displayName — mirrors
  /// the label truncation used in create_trip_page.dart's _DestinationField.
  String get shortLabel {
    final parts = displayName.split(',');
    return parts.take(3).join(',').trim();
  }
}

// ---------------------------------------------------------------------------
// GeocodingService — thin Nominatim/OSM search wrapper
//
// Usage policy compliance:
//   - User-Agent: "memories-app/1.0 bayupabisa@gmail.com" sent on every request.
//   - Callers MUST debounce (~400 ms) before calling search().
//   - Queries shorter than 3 characters should not be forwarded by the caller.
//   - Returns [] on any error so callers never need to handle exceptions.
// ---------------------------------------------------------------------------

class GeocodingService {
  GeocodingService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      headers: {
        'User-Agent': 'memories-app/1.0 bayupabisa@gmail.com',
        'Accept-Language': 'en',
      },
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));
  }

  late final Dio _dio;

  /// Search Nominatim for [query] and return up to 5 place suggestions.
  ///
  /// The caller is responsible for:
  ///   - Skipping calls when [query].trim().length < 3
  ///   - Debouncing (400–500 ms) to avoid hammering the free API
  Future<List<PlaceSuggestion>> search(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final response = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'limit': 5,
          'addressdetails': 1,
        },
      );
      final data = response.data;
      if (data == null || data.isEmpty) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final displayName = item['display_name'] as String? ?? '';
            final latStr = item['lat'] as String? ?? '';
            final lonStr = item['lon'] as String? ?? ''; // Note: Nominatim uses 'lon'
            final lat = double.tryParse(latStr);
            final lng = double.tryParse(lonStr);
            if (lat == null || lng == null) return null;
            return PlaceSuggestion(
              displayName: displayName,
              lat: lat,
              lng: lng,
            );
          })
          .whereType<PlaceSuggestion>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
