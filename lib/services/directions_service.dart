import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

class DirectionsService {
  final Dio _dio = Dio();

  /// Fetch road driving route between [start] and [end] from Mapbox Directions API.
  Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    bool smooth = false,
  }) async {
    try {
      final token = ApiConfig.mapboxAccessToken;
      if (token.isEmpty) return const [];

      final url =
          'https://api.mapbox.com/directions/v5/mapbox/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?geometries=geojson&overview=full&access_token=$token';

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            return coords.map<LatLng>((c) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[DirectionsService] Mapbox getRoute error: $e');
    }
    return const [];
  }

  /// Match recent GPS [trace] onto road geometry using Mapbox Map Matching API.
  Future<List<LatLng>> matchTrace(
    List<LatLng> trace, {
    int radiusMeters = 25,
  }) async {
    if (trace.length < 2) return const [];
    try {
      final token = ApiConfig.mapboxAccessToken;
      if (token.isEmpty) return const [];

      final coordPairs =
          trace.map((p) => '${p.longitude},${p.latitude}').join(';');
      final radiuses = List.filled(trace.length, radiusMeters).join(';');

      final url =
          'https://api.mapbox.com/matching/v5/mapbox/driving/$coordPairs'
          '?geometries=geojson&overview=full&radiuses=$radiuses&access_token=$token';

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        final matchings = data['matchings'] as List?;
        if (matchings != null && matchings.isNotEmpty) {
          final geometry = matchings[0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            return coords.map<LatLng>((c) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[DirectionsService] Mapbox matchTrace error: $e');
    }
    return const [];
  }
}
