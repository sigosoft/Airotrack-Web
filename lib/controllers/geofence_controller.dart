import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/geofence_model.dart';
import '../services/lookups_service.dart';
import '../utils/app_toast.dart';

class GeofenceController extends GetxController {
  final geofences = <GeofenceModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;

  final syncedVehicles = <GeofenceVehicleItem>[].obs;
  final unsyncedVehicles = <GeofenceVehicleItem>[].obs;
  final isVehicleLoading = false.obs;

  final vehicleSyncedGeofencesList = <GeofenceModel>[].obs;
  final vehicleUnsyncedGeofencesList = <GeofenceModel>[].obs;
  final isVehicleGeofencesLoading = false.obs;

  /// Geofences linked to the vehicle open on Track, drawn on its map.
  final vehicleGeofencesMapOverlayList = <GeofenceModel>[].obs;
  int? _overlayVehicleId;

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

  static List<GeofenceModel> _geofencesFrom(dynamic body) {
    dynamic list;
    if (body is Map) {
      final data = body['data'];
      if (data is Map) {
        list = data['geofences'];
      } else if (data is List) {
        list = data;
      } else {
        list = body['geofences'];
      }
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((j) => GeofenceModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  /// Fetch all user created geofences (GET /geofences)
  Future<void> fetchGeofences({String? keyword}) async {
    try {
      isLoading.value = true;
      final q = keyword ?? searchQuery.value.trim();
      final response = await DioClient().get(
        ApiEndPoints.geofences,
        queryParameters: {'limit': '100', if (q.isNotEmpty) 'keyword': q},
      );
      if (LookupsService.isOk(response)) {
        geofences.assignAll(_geofencesFrom(response.data));
      }
    } catch (e) {
      debugPrint('Error fetching geofences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Form for add_geofence / update_geofence, in the format the mobile app
  /// sends: type circle | rectangle | polygon, radius and tolerance in km,
  /// event_type 1/2/3, coordinates[i][lat|lng] for rectangle and polygon.
  FormData _geofenceForm({
    int? id,
    required String name,
    required String shape,
    required String address,
    required String description,
    required LatLng center,
    required double radiusMeters,
    required List<LatLng> coordinates,
    required int toleranceMeters,
    required int eventCode,
  }) {
    final form = FormData();
    void field(String k, String v) => form.fields.add(MapEntry(k, v));
    if (id != null) field('id', '$id');
    field('name', name);
    field('type', shape);
    field('tolerance', (toleranceMeters / 1000).toStringAsFixed(3));
    field('event_type', '$eventCode');
    field('address', address.isEmpty ? name : address);
    field('description', description);
    field('is_active', '1');
    if (shape == 'circle') {
      field('latitude', center.latitude.toStringAsFixed(8));
      field('longitude', center.longitude.toStringAsFixed(8));
      field('radius', (radiusMeters / 1000).toStringAsFixed(4));
    } else {
      for (var i = 0; i < coordinates.length; i++) {
        field('coordinates[$i][lat]', coordinates[i].latitude.toStringAsFixed(6));
        field('coordinates[$i][lng]', coordinates[i].longitude.toStringAsFixed(6));
      }
    }
    return form;
  }

  /// Add (POST add_geofence) or, with [id], update (POST update_geofence).
  Future<bool> saveGeofence({
    int? id,
    required String name,
    required String shape,
    required String address,
    required String description,
    required LatLng center,
    required double radiusMeters,
    required List<LatLng> coordinates,
    required int toleranceMeters,
    required int eventCode,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final response = await DioClient().post(
        id == null ? ApiEndPoints.addGeofence : ApiEndPoints.updateGeofence,
        body: _geofenceForm(
          id: id,
          name: name,
          shape: shape,
          address: address,
          description: description,
          center: center,
          radiusMeters: radiusMeters,
          coordinates: coordinates,
          toleranceMeters: toleranceMeters,
          eventCode: eventCode,
        ),
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(
            response,
            fallback: id == null ? 'Geofence created' : 'Geofence updated',
          ),
        );
        await fetchGeofences();
        return true;
      }
      AppToast.show(
        LookupsService.messageOf(
          response,
          fallback: id == null
              ? 'Failed to create geofence'
              : 'Failed to update geofence',
        ),
        isError: true,
      );
      return false;
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Delete geofence (POST /delete_geofence)
  Future<bool> deleteGeofence(int id) async {
    try {
      isLoading.value = true;
      final response = await DioClient().post(
        ApiEndPoints.deleteGeofence,
        body: FormData.fromMap({'id': id}),
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(response, fallback: 'Geofence deleted'),
        );
        geofences.removeWhere((g) => g.id == id);
        return true;
      }
      AppToast.show(
        LookupsService.messageOf(response, fallback: 'Failed to delete geofence'),
        isError: true,
      );
      return false;
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  static List<GeofenceVehicleItem> _vehiclesFrom(dynamic body, bool selected) {
    dynamic list;
    if (body is Map) {
      final data = body['data'];
      list = data is Map ? data['vehicles'] : data;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(
          (j) => GeofenceVehicleItem.fromJson(
            Map<String, dynamic>.from(j),
            isSelected: selected,
          ),
        )
        .toList();
  }

  /// Vehicles linked / not linked to a geofence
  /// (GET geofence_synced_vehicles, geofence_unsynced_vehicles).
  Future<void> fetchGeofenceVehicles(int geofenceId) async {
    try {
      isVehicleLoading.value = true;
      syncedVehicles.clear();
      unsyncedVehicles.clear();
      final query = {'geofence_id': '$geofenceId'};
      final results = await Future.wait([
        DioClient().get(ApiEndPoints.geofenceSyncedVehicles, queryParameters: query),
        DioClient().get(ApiEndPoints.geofenceUnsyncedVehicles, queryParameters: query),
      ]);
      syncedVehicles.assignAll(_vehiclesFrom(results[0].data, true));
      final syncedIds = syncedVehicles.map((v) => v.id).toSet();
      unsyncedVehicles.assignAll(
        _vehiclesFrom(results[1].data, false)
            .where((v) => !syncedIds.contains(v.id)),
      );
    } catch (e) {
      debugPrint('Error fetching geofence vehicles: $e');
    } finally {
      isVehicleLoading.value = false;
    }
  }

  Future<Response> _postIds(
    String path,
    String ownerKey,
    int ownerId,
    String listKey,
    List<int> ids,
  ) {
    final form = FormData();
    form.fields.add(MapEntry(ownerKey, '$ownerId'));
    for (var i = 0; i < ids.length; i++) {
      form.fields.add(MapEntry('$listKey[$i]', '${ids[i]}'));
    }
    return DioClient().post(path, body: form);
  }

  Future<List<int>> _vehicleGeofenceIds(int vehicleId) async {
    final r = await DioClient().get(
      ApiEndPoints.vehicleSyncedGeofences,
      queryParameters: {'vehicle_id': '$vehicleId'},
    );
    return _geofencesFrom(r.data).map((g) => g.id).toList();
  }

  Future<List<int>> _geofenceVehicleIds(int geofenceId) async {
    final r = await DioClient().get(
      ApiEndPoints.geofenceSyncedVehicles,
      queryParameters: {'geofence_id': '$geofenceId'},
    );
    return _vehiclesFrom(r.data, true).map((v) => v.id).toList();
  }

  /// The sync APIs reject an empty list, so unlinking the last item is done
  /// from the other side (as the mobile app does). Returns an error text, or
  /// null when every link was removed.
  Future<String?> _unlink({
    required int geofenceId,
    required int vehicleId,
  }) async {
    final others = (await _vehicleGeofenceIds(vehicleId))
        .where((id) => id != geofenceId)
        .toList();
    if (others.isNotEmpty) {
      final r = await _postIds(
        ApiEndPoints.syncVehicleGeofences,
        'vehicle_id',
        vehicleId,
        'geofence_ids',
        others,
      );
      return LookupsService.isOk(r)
          ? null
          : LookupsService.messageOf(r, fallback: 'Failed to unlink');
    }
    final otherVehicles = (await _geofenceVehicleIds(geofenceId))
        .where((id) => id != vehicleId)
        .toList();
    if (otherVehicles.isNotEmpty) {
      final r = await _postIds(
        ApiEndPoints.syncGeofenceVehicles,
        'geofence_id',
        geofenceId,
        'vehicle_ids',
        otherVehicles,
      );
      return LookupsService.isOk(r)
          ? null
          : LookupsService.messageOf(r, fallback: 'Failed to unlink');
    }
    return 'The server cannot remove the last link between a vehicle and a '
        'geofence yet';
  }

  /// Link exactly [vehicleIds] to a geofence (POST sync_geofence_vehicles,
  /// vehicle_ids[i]); unticked vehicles are unlinked.
  Future<bool> syncGeofenceVehicles(
    int geofenceId,
    List<int> vehicleIds, {
    List<int> previouslySynced = const [],
  }) async {
    try {
      isVehicleLoading.value = true;
      if (vehicleIds.isNotEmpty) {
        final r = await _postIds(
          ApiEndPoints.syncGeofenceVehicles,
          'geofence_id',
          geofenceId,
          'vehicle_ids',
          vehicleIds,
        );
        if (!LookupsService.isOk(r)) {
          AppToast.show(
            LookupsService.messageOf(r, fallback: 'Failed to sync vehicles'),
            isError: true,
          );
          return false;
        }
        AppToast.show(LookupsService.messageOf(r, fallback: 'Vehicles updated'));
        return true;
      }
      for (final v in previouslySynced) {
        final err = await _unlink(geofenceId: geofenceId, vehicleId: v);
        if (err != null) {
          AppToast.show(err, isError: true);
          return false;
        }
      }
      AppToast.show('Vehicles updated');
      return true;
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isVehicleLoading.value = false;
    }
  }

  /// Link exactly [geofenceIds] to a vehicle (POST sync_vehicle_geofences,
  /// geofence_ids[i]); unticked geofences are unlinked.
  Future<bool> syncVehicleGeofences(
    int vehicleId,
    List<int> geofenceIds, {
    List<int> previouslySynced = const [],
  }) async {
    try {
      isVehicleGeofencesLoading.value = true;
      if (geofenceIds.isNotEmpty) {
        final r = await _postIds(
          ApiEndPoints.syncVehicleGeofences,
          'vehicle_id',
          vehicleId,
          'geofence_ids',
          geofenceIds,
        );
        if (!LookupsService.isOk(r)) {
          AppToast.show(
            LookupsService.messageOf(r, fallback: 'Failed to sync geofences'),
            isError: true,
          );
          return false;
        }
        AppToast.show(
          LookupsService.messageOf(r, fallback: 'Geofences synced for vehicle'),
        );
      } else {
        for (final g in previouslySynced) {
          final err = await _unlink(geofenceId: g, vehicleId: vehicleId);
          if (err != null) {
            AppToast.show(err, isError: true);
            return false;
          }
        }
        AppToast.show('Geofences unsynced for vehicle');
      }
      if (_overlayVehicleId == vehicleId) {
        await fetchVehicleGeofences(vehicleId);
      }
      return true;
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isVehicleGeofencesLoading.value = false;
    }
  }

  /// Geofences linked and not linked to a vehicle
  /// (GET vehicle_synced_geofences, vehicle_unsynced_geofences).
  Future<void> fetchVehicleGeofenceLists(int vehicleId) async {
    try {
      isVehicleGeofencesLoading.value = true;
      vehicleSyncedGeofencesList.clear();
      vehicleUnsyncedGeofencesList.clear();
      final query = {'vehicle_id': '$vehicleId'};
      final results = await Future.wait([
        DioClient().get(ApiEndPoints.vehicleSyncedGeofences, queryParameters: query),
        DioClient().get(ApiEndPoints.vehicleUnsyncedGeofences, queryParameters: query),
      ]);
      vehicleSyncedGeofencesList.assignAll(_geofencesFrom(results[0].data));
      final synced = vehicleSyncedGeofencesList.map((g) => g.id).toSet();
      vehicleUnsyncedGeofencesList.assignAll(
        _geofencesFrom(results[1].data).where((g) => !synced.contains(g.id)),
      );
    } catch (e) {
      debugPrint('Error fetching vehicle geofences: $e');
    } finally {
      isVehicleGeofencesLoading.value = false;
    }
  }

  /// Full geometry of the geofences linked to a vehicle, for the Track map
  /// (GET vehicle_geofences?vehicle_id=).
  Future<void> fetchVehicleGeofences(int vehicleId) async {
    _overlayVehicleId = vehicleId;
    try {
      final response = await DioClient().get(
        ApiEndPoints.vehicleGeofences,
        queryParameters: {'vehicle_id': '$vehicleId'},
      );
      if (_overlayVehicleId != vehicleId) return;
      vehicleGeofencesMapOverlayList.assignAll(
        LookupsService.isOk(response) ? _geofencesFrom(response.data) : const [],
      );
    } catch (e) {
      debugPrint('Error fetching vehicle geofences geometry: $e');
    }
  }

  void clearVehicleGeofenceOverlay() {
    _overlayVehicleId = null;
    vehicleGeofencesMapOverlayList.clear();
  }
}
