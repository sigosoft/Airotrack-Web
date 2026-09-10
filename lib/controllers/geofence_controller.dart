import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData;
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/geofence_model.dart';
import '../utils/app_toast.dart';

class GeofenceController extends GetxController {
  final geofences = <GeofenceModel>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  final syncedVehicles = <GeofenceVehicleItem>[].obs;
  final unsyncedVehicles = <GeofenceVehicleItem>[].obs;
  final isVehicleLoading = false.obs;

  final vehicleSyncedGeofencesList = <GeofenceModel>[].obs;
  final vehicleUnsyncedGeofencesList = <GeofenceModel>[].obs;
  final vehicleGeofencesMapOverlayList = <GeofenceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchGeofences();
    debounce(
      searchQuery,
      (_) => fetchGeofences(),
      time: const Duration(milliseconds: 500),
    );
  }

  /// Filtered list based on search query (local or server-side fallback)
  List<GeofenceModel> get filteredGeofences {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return geofences;
    return geofences.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.address.toLowerCase().contains(q) ||
          g.type.toLowerCase().contains(q) ||
          g.description.toLowerCase().contains(q);
    }).toList();
  }

  /// Fetch all user created geofences (GET /geofences)
  Future<void> fetchGeofences({String? keyword}) async {
    try {
      isLoading.value = true;
      final q = keyword ?? searchQuery.value.trim();

      final response = await DioClient().get(
        ApiEndPoints.geofences,
        queryParameters: {'limit': '50', if (q.isNotEmpty) 'keyword': q},
      );

      if (response.data != null) {
        final data = response.data;
        List<dynamic>? rawList;

        if (data is Map) {
          if (data['data'] != null && data['data'] is Map) {
            rawList = data['data']['geofences'] as List<dynamic>?;
          } else if (data['data'] is List) {
            rawList = data['data'] as List<dynamic>?;
          } else if (data['geofences'] is List) {
            rawList = data['geofences'] as List<dynamic>?;
          }
        }

        if (rawList != null) {
          geofences.value = rawList
              .map(
                (json) => GeofenceModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching geofences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add new geofence (POST /add_geofence)
  Future<bool> addGeofence({
    required String name,
    required String type, // 'Circle' or 'Polygon'
    required String address,
    required String description,
    double? latitude,
    double? longitude,
    double radius = 500,
    int tolerance = 0,
    String eventType = 'both',
  }) async {
    try {
      isLoading.value = true;
      final typeInt = type.toLowerCase() == 'polygon' ? 2 : 1;

      final formData = FormData.fromMap({
        'name': name,
        'type': typeInt,
        'tolerance': tolerance,
        'event_type': eventType,
        'address': address,
        'description': description,
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'radius': radius,
      });

      final response = await DioClient().post(
        ApiEndPoints.addGeofence,
        body: formData,
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(
          response.data['message']?.toString() ??
              'Geofence created successfully',
        );
        await fetchGeofences();
        return true;
      } else {
        final msg =
            response.data?['message']?.toString() ??
            'Failed to create geofence';
        AppToast.show(msg, isError: true);
        return false;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing geofence (POST /update_geofence)
  Future<bool> updateGeofence({
    required int id,
    required String name,
    required String type,
    required String address,
    required String description,
    double? latitude,
    double? longitude,
    double radius = 500,
    int tolerance = 0,
    String eventType = 'both',
  }) async {
    try {
      isLoading.value = true;
      final typeInt = type.toLowerCase() == 'polygon' ? 2 : 1;

      final formData = FormData.fromMap({
        'id': id,
        'name': name,
        'type': typeInt,
        'tolerance': tolerance,
        'event_type': eventType,
        'address': address,
        'description': description,
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'radius': radius,
      });

      final response = await DioClient().post(
        ApiEndPoints.updateGeofence,
        body: formData,
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(
          response.data['message']?.toString() ?? 'Geofence updated',
        );
        await fetchGeofences();
        return true;
      } else {
        final msg =
            response.data?['message']?.toString() ??
            'Failed to update geofence';
        AppToast.show(msg, isError: true);
        return false;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete geofence (POST /delete_geofence)
  Future<bool> deleteGeofence(int id) async {
    try {
      isLoading.value = true;
      final formData = FormData.fromMap({'id': id});

      final response = await DioClient().post(
        ApiEndPoints.deleteGeofence,
        body: formData,
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(
          response.data['message']?.toString() ?? 'Geofence deleted',
        );
        geofences.removeWhere((g) => g.id == id);
        return true;
      } else {
        final msg =
            response.data?['message']?.toString() ??
            'Failed to delete geofence';
        AppToast.show(msg, isError: true);
        return false;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load vehicles linked and not linked to a specific geofence (GET /geofence_synced_vehicles & GET /geofence_unsynced_vehicles)
  Future<void> fetchGeofenceVehicles(int geofenceId) async {
    try {
      isVehicleLoading.value = true;

      final responseSynced = await DioClient().get(
        ApiEndPoints.geofenceSyncedVehicles,
        queryParameters: {'geofence_id': geofenceId.toString()},
      );

      final responseUnsynced = await DioClient().get(
        ApiEndPoints.geofenceUnsyncedVehicles,
        queryParameters: {'geofence_id': geofenceId.toString()},
      );

      List<GeofenceVehicleItem> synced = [];
      if (responseSynced.data != null) {
        final raw = responseSynced.data['data'];
        if (raw is List) {
          synced = raw
              .map((j) => GeofenceVehicleItem.fromJson(j, isSelected: true))
              .toList();
        }
      }

      List<GeofenceVehicleItem> unsynced = [];
      if (responseUnsynced.data != null) {
        final raw = responseUnsynced.data['data'];
        if (raw is List) {
          unsynced = raw
              .map((j) => GeofenceVehicleItem.fromJson(j, isSelected: false))
              .toList();
        }
      }

      syncedVehicles.value = synced;
      unsyncedVehicles.value = unsynced;
    } catch (e) {
      debugPrint('Error fetching geofence vehicle matrices: $e');
    } finally {
      isVehicleLoading.value = false;
    }
  }

  /// Sync vehicles to a geofence (POST /sync_geofence_vehicles)
  Future<bool> syncGeofenceVehicles(
    int geofenceId,
    List<int> vehicleIds,
  ) async {
    try {
      isVehicleLoading.value = true;
      final formData = FormData.fromMap({
        'geofence_id': geofenceId,
        'vehicle_ids': vehicleIds,
      });

      final response = await DioClient().post(
        ApiEndPoints.syncGeofenceVehicles,
        body: formData,
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(
          response.data['message']?.toString() ??
              'Synced vehicles successfully',
        );
        return true;
      } else {
        final msg =
            response.data?['message']?.toString() ?? 'Failed to sync vehicles';
        AppToast.show(msg, isError: true);
        return false;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isVehicleLoading.value = false;
    }
  }

  /// Sync geofences to a single vehicle (POST /sync_vehicle_geofences)
  Future<bool> syncVehicleGeofences(
    int vehicleId,
    List<int> geofenceIds,
  ) async {
    try {
      isLoading.value = true;
      final formData = FormData.fromMap({
        'vehicle_id': vehicleId,
        'geofence_ids': geofenceIds,
      });

      final response = await DioClient().post(
        ApiEndPoints.syncVehicleGeofences,
        body: formData,
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(
          response.data['message']?.toString() ??
              'Synced geofences successfully',
        );
        return true;
      } else {
        final msg =
            response.data?['message']?.toString() ?? 'Failed to sync geofences';
        AppToast.show(msg, isError: true);
        return false;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch geofences synced to a specific vehicle (GET /vehicle_synced_geofences)
  Future<void> fetchVehicleSyncedGeofences(int vehicleId) async {
    try {
      isLoading.value = true;
      final response = await DioClient().get(
        ApiEndPoints.vehicleSyncedGeofences,
        queryParameters: {'vehicle_id': vehicleId.toString()},
      );

      if (response.data != null && response.data['data'] != null) {
        final raw = response.data['data'];
        if (raw is List) {
          vehicleSyncedGeofencesList.value = raw
              .map((j) => GeofenceModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching vehicle synced geofences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch geofences unsynced to a specific vehicle (GET /vehicle_unsynced_geofences)
  Future<void> fetchVehicleUnsyncedGeofences(int vehicleId) async {
    try {
      isLoading.value = true;
      final response = await DioClient().get(
        ApiEndPoints.vehicleUnsyncedGeofences,
        queryParameters: {'vehicle_id': vehicleId.toString()},
      );

      if (response.data != null && response.data['data'] != null) {
        final raw = response.data['data'];
        if (raw is List) {
          vehicleUnsyncedGeofencesList.value = raw
              .map((j) => GeofenceModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching vehicle unsynced geofences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch full geometry geofences assigned to a vehicle for map overlay (GET /vehicle_geofences)
  Future<void> fetchVehicleGeofences(int vehicleId) async {
    try {
      isLoading.value = true;
      final response = await DioClient().get(
        ApiEndPoints.vehicleGeofences,
        queryParameters: {'vehicle_id': vehicleId.toString()},
      );

      if (response.data != null) {
        final data = response.data;
        List<dynamic>? rawList;

        if (data is Map) {
          if (data['data'] != null && data['data'] is Map) {
            rawList = data['data']['geofences'] as List<dynamic>?;
          } else if (data['data'] is List) {
            rawList = data['data'] as List<dynamic>?;
          } else if (data['geofences'] is List) {
            rawList = data['geofences'] as List<dynamic>?;
          }
        }

        if (rawList != null) {
          vehicleGeofencesMapOverlayList.value = rawList
              .map((j) => GeofenceModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching vehicle geofences geometry: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
