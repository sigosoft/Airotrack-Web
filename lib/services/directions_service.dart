import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

class DirectionsService {
  final Dio _dio = Dio();

  /// Fetch road driving route between [start] and [end] from Google Directions API.
  Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    bool smooth = false,
  }) async {
    final apiKey = ApiConfig.googleMapKey;

    // 1. Try Google Directions API
    if (apiKey.isNotEmpty) {
      try {
        final url =
            'https://maps.googleapis.com/maps/api/directions/json'
            '?origin=${start.latitude},${start.longitude}'
            '&destination=${end.latitude},${end.longitude}'
            '&mode=driving'
            '&key=$apiKey';

        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data is String
              ? jsonDecode(response.data as String)
              : response.data;
          final routes = data['routes'] as List?;
          if (routes != null && routes.isNotEmpty) {
            final polyline = routes[0]['overview_polyline']?['points'];
            if (polyline is String && polyline.isNotEmpty) {
              final pts = _decodePolyline(polyline);
              if (pts.isNotEmpty) return pts;
            }
          }
        }
      } catch (e) {
        debugPrint('[DirectionsService] Google Directions API notice: $e');
      }
    }

    // 2. High-performance fallback: Open Source Routing (handles Web CORS seamlessly)
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';

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
      debugPrint('[DirectionsService] OSRM getRoute fallback notice: $e');
    }

    return const [];
  }

  /// Match recent GPS [trace] onto road geometry using Google Roads Snap-to-Roads API.
  Future<List<LatLng>> matchTrace(
    List<LatLng> trace, {
    int radiusMeters = 25,
  }) async {
    if (trace.length < 2) return const [];
    final apiKey = ApiConfig.googleMapKey;

    // 1. Try Google Roads API (Snap to Roads)
    if (apiKey.isNotEmpty) {
      try {
        final sample = trace.length > 100 ? trace.sublist(0, 100) : trace;
        final path = sample.map((p) => '${p.latitude},${p.longitude}').join('|');
        final url =
            'https://roads.googleapis.com/v1/snapToRoads'
            '?path=$path&interpolate=true&key=$apiKey';

        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data is String
              ? jsonDecode(response.data as String)
              : response.data;
          final snapped = data['snappedPoints'] as List?;
          if (snapped != null && snapped.isNotEmpty) {
            final result = <LatLng>[];
            for (final item in snapped) {
              final loc = item['location'];
              if (loc is Map) {
                final lat = (loc['latitude'] as num?)?.toDouble();
                final lng = (loc['longitude'] as num?)?.toDouble();
                if (lat != null && lng != null) {
                  result.add(LatLng(lat, lng));
                }
              }
            }
            if (result.isNotEmpty) return result;
          }
        }
      } catch (e) {
        debugPrint('[DirectionsService] Google Roads Snap-to-Roads notice: $e');
      }
    }

    // 2. High-performance fallback: Open Source Routing match
    try {
      final sample = trace.length > 50 ? trace.sublist(0, 50) : trace;
      final coordPairs =
          sample.map((p) => '${p.longitude},${p.latitude}').join(';');
      final radiuses = List.filled(sample.length, radiusMeters).join(';');

      final url =
          'https://router.project-osrm.org/match/v1/driving/$coordPairs'
          '?overview=full&geometries=geojson&radiuses=$radiuses';

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
      debugPrint('[DirectionsService] OSRM match fallback notice: $e');
    }

    return trace;
  }

  /// Decode Google encoded polyline string to LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
}
