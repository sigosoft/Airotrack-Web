import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';

class PlaceSearchResult {
  final String name;
  final String address;
  final LatLng location;

  const PlaceSearchResult({
    required this.name,
    required this.address,
    required this.location,
  });
}

/// Place text -> coordinates (Mapbox Geocoding), as the mobile app's
/// geofence "Search Location" does.
class PlaceSearchService {
  PlaceSearchService._();
  static final PlaceSearchService instance = PlaceSearchService._();

  // Own Dio: no app bearer token is sent to Mapbox.
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<List<PlaceSearchResult>> search(
    String query, {
    LatLng? proximity,
    int limit = 6,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/'
        '${Uri.encodeComponent(q)}.json',
        queryParameters: {
          'access_token': ApiConfig.mapboxAccessToken,
          'autocomplete': 'true',
          'limit': '$limit',
          'language': 'en',
          'types': 'address,poi,neighborhood,locality,place,district,region',
          if (proximity != null)
            'proximity': '${proximity.longitude},${proximity.latitude}',
        },
      );
      final features = response.data?['features'];
      if (features is! List) return const [];
      final results = <PlaceSearchResult>[];
      for (final f in features.whereType<Map>()) {
        final center = f['center'];
        if (center is! List || center.length < 2) continue;
        final lng = (center[0] as num?)?.toDouble();
        final lat = (center[1] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final placeName = (f['place_name'] ?? '').toString().trim();
        final text = (f['text'] ?? '').toString().trim();
        final address = _withoutPincode(placeName.isNotEmpty ? placeName : text);
        if (address.isEmpty && text.isEmpty) continue;
        results.add(
          PlaceSearchResult(
            name: text.isNotEmpty ? text : address,
            address: address.isNotEmpty ? address : text,
            location: LatLng(lat, lng),
          ),
        );
      }
      return results;
    } catch (e) {
      debugPrint('[PlaceSearch] failed: $e');
      return const [];
    }
  }

  /// Drops a 6-digit PIN code ("Kochi, Kerala 682001, India").
  static String _withoutPincode(String s) => s
      .replaceAll(RegExp(r'\s*\b\d{6}\b'), '')
      .replaceAll(RegExp(r'\s+,'), ',')
      .trim();
}
