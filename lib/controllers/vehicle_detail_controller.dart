import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../models/live_track_model.dart';
import '../models/vehicle_detail_model.dart';
import '../models/vehicle_model.dart';
import '../services/directions_service.dart';
import '../services/app_settings.dart';
import '../services/live_track_websocket_service.dart';
import '../utils/app_toast.dart';
import 'alerts_controller.dart';
import 'dashboard_controller.dart';
import 'home_controller.dart';

class VehicleDetailController extends GetxController {
  final RxInt selectedTopTab =
      (-1).obs; // -1: Vehicle Info Detail, 0: History, 1: Alerts, 2: Statistics
  final RxBool isMapDialogVisible = false.obs;
  final RxBool isHistoryMapDialogVisible = false.obs;

  // Live Tracking Motion & Real-Time Engine
  final Rxn<LatLng> liveMarkerPosition = Rxn<LatLng>();
  final RxDouble liveMarkerBearing = 0.0.obs;
  final RxBool isLiveMoving = false.obs;
  final RxBool isLiveTrackingConnected = false.obs;
  final RxBool isLiveLocked = true.obs;
  final RxList<LatLng> liveRoadPolyline = <LatLng>[].obs;
  final MapController liveMapController = MapController();

  final LiveTrackWebSocketService _liveTrackWs = LiveTrackWebSocketService();
  final DirectionsService _directionsService = DirectionsService();

  LiveWebsocketConfig? _wsConfig;
  LiveWebsocketInfo? _wsInfo;

  Timer? _liveAnimationTimer;
  DateTime? _lastLiveTickTime;

  // Live Tracking Waypoint Motion Engine
  final List<LatLng> _liveWaypoints = [];
  int _liveWaypointIndex = 0;
  double _liveWaypointFraction = 0.0;
  double _currentLiveSpeedMs = 0.0;
  LatLng? _lastAcceptedGps;
  DateTime? _lastGpsTime;
  double _lastReportedSpeedKmh = 0.0;
  double _expectedPingSec = 10.0;
  String? _lastAcceptedDeviceTime;
  DateTime? _lastAcceptedFixTime;
  LatLng? _prevRawFix;
  bool _liveHeadingKnown = false; // heading taken from real movement
  Timer? _livePollingTimer;
  DateTime _lastLiveUpdateReceivedAt = DateTime.now();
  bool _liveDisposed = false;
  bool _roadFetchInFlight = false;
  final List<LatLng> _lastRoadCorridor = [];

  // Live session guards (prevent restarts / stale async results from resetting motion)
  int _liveSessionId = 0;
  String? _liveTrackingImei;
  DateTime? _lastLiveFixTime;

  // A fix older than this is shown as not moving (speed 0) instead of
  // repeating the last reported speed while the device is silent.
  // Trackers often deliver their data a few minutes late (network gaps,
  // weak signal on highways). 2 minutes showed a moving vehicle as 0 km/h
  // while the vehicle list showed its real speed; 10 minutes keeps them in
  // step and still shows 0 for a vehicle that has really stopped sending.
  static const Duration _liveStaleAfter = Duration(minutes: 10);

  // History Playback Engine
  final RxDouble playbackProgress = 0.0.obs;
  final RxBool isPlaying = false.obs;
  final RxString playbackSpeed = '1x'.obs;
  final RxDouble playbackSpeedMultiplier = 1.0.obs;
  final Rxn<LatLng> movingMarkerPosition = Rxn<LatLng>();
  final Rxn<double> movingMarkerBearing = Rxn<double>();
  final MapController historyMapController = MapController();
  final RxList<LatLng> traveledRoutePoints = <LatLng>[].obs;
  Timer? _movingMarkerTimer;
  int _movingSegmentIndex = 0;
  double _movingSegmentFraction = 0.0;
  int _lastCameraUpdateMs = 0;
  List<LatLng> _playbackRoutePoints = [];
  List<double> _playbackSpeedSeries = <double>[];

  static const Duration _playbackFramePeriod = Duration(milliseconds: 16);
  static const double _playbackTickSeconds = 0.016;
  // History playback pace at 1x is defined on screen: the car moves about
  // this many pixels per second at whatever zoom the map is on, so it is
  // always visibly moving but never jumps. 1.5x / 2x multiply this.
  static const double _playbackScreenPxPerSec = 45.0;
  static const double _playbackMinMps = 8.0;
  static const double _playbackMaxMps = 600.0;
  DateTime? _lastPlaybackTickAt;
  static const double _bearingSmoothing = 0.35;
  static String _formatInitialDate(DateTime dt, {bool isStart = true}) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    if (isStart) {
      return '$day-$month-$year 12:00 AM';
    } else {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day-$month-$year ${hour.toString().padLeft(2, '0')}:$minute $period';
    }
  }

  late final RxString startDateStr = _formatInitialDate(
    DateTime.now(),
    isStart: true,
  ).obs;
  late final RxString endDateStr = _formatInitialDate(
    DateTime.now(),
    isStart: false,
  ).obs;

  final RxBool isLoading = false.obs;
  final RxBool isStatisticsLoading = false.obs;

  // True while a history load the user asked for (date change, opening the
  // History tab) is in progress. Play is blocked and the map shows a loader.
  final RxBool isHistoryLoading = false.obs;
  int _historyRequestSeq = 0;
  final historyPoints = <Map<String, dynamic>>[].obs;
  final liveTrackData = <String, dynamic>{}.obs;

  // Dynamic History Metadata & Trips
  final RxMap<String, dynamic> historyResponseData = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> historyTrips =
      <Map<String, dynamic>>[].obs;
  final RxDouble currentPlaybackSpeedKmph = 0.0.obs;

  String get historyDisplaySpeed {
    if (isPlaying.value) {
      return currentPlaybackSpeedKmph.value.toStringAsFixed(1);
    }
    // Average of the 'speed' values in the history response (moving points).
    final speeds = historyPoints
        .map((p) => double.tryParse(p['speed']?.toString() ?? '') ?? 0.0)
        .where((s) => s > 0)
        .toList();
    if (speeds.isNotEmpty) {
      final avg = speeds.reduce((a, b) => a + b) / speeds.length;
      return avg.toStringAsFixed(1);
    }
    final metaAvg =
        historyResponseData['average_speed'] ??
        historyResponseData['avg_speed'];
    if (metaAvg != null && metaAvg.toString().isNotEmpty) {
      final clean = metaAvg.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      if (clean.isNotEmpty) return clean;
    }
    return '0.0';
  }

  String get historyDisplayDuration {
    if (historyTrips.isNotEmpty) {
      final firstStart = historyTrips.first['startTime'];
      final lastEnd = historyTrips.last['endTime'];
      final sDt = _parseTimestamp(firstStart);
      final eDt = _parseTimestamp(lastEnd);
      if (sDt != null && eDt != null) {
        return _formatDuration(eDt.difference(sDt));
      }
      return historyTrips.first['duration'] ?? '00h 00m';
    }
    if (historyPoints.length >= 2) {
      final sDt = _parseTimestamp(_pointTime(historyPoints.first));
      final eDt = _parseTimestamp(_pointTime(historyPoints.last));
      if (sDt != null && eDt != null) {
        return _formatDuration(eDt.difference(sDt));
      }
    }
    final metaDur =
        historyResponseData['duration'] ??
        historyResponseData['total_duration'];
    if (metaDur != null &&
        metaDur.toString().isNotEmpty &&
        metaDur.toString() != '00:00:00') {
      return metaDur.toString();
    }
    return '00h 00m';
  }

  String get historyDisplayDistance {
    // Distance along the latitude/longitude points of the history response.
    final pts = <LatLng>[];
    for (final p in historyPoints) {
      final ll = _pointLatLng(p);
      if (ll != null) pts.add(ll);
    }
    if (pts.length >= 2) {
      final km = _getTotalDistanceKm(pts);
      return '${km.toStringAsFixed(2)} Km';
    }
    final metaDist =
        historyResponseData['distance'] ??
        historyResponseData['total_distance'];
    if (metaDist != null &&
        metaDist.toString().isNotEmpty &&
        metaDist.toString() != '0 km') {
      return metaDist.toString().contains('Km')
          ? metaDist.toString()
          : '$metaDist Km';
    }
    return '0.00 Km';
  }

  String get historyDialogDeviceTime {
    if (historyPoints.isNotEmpty) {
      final idx = _historyDialogPointIndex;
      final pt = historyPoints[idx];
      final val = _pointTime(pt);
      if (val != null && val.toString().trim().isNotEmpty) {
        return formatDisplayTime(val.toString());
      }
    }
    return vehicleDetail.value.deviceTime.isNotEmpty
        ? vehicleDetail.value.deviceTime
        : 'N/A';
  }

  String get historyDialogServerTime {
    if (historyPoints.isNotEmpty) {
      final idx = _historyDialogPointIndex;
      final pt = historyPoints[idx];
      final val =
          pt['server_time'] ??
          pt['servertime'] ??
          pt['serverTime'] ??
          pt['updated_at'];
      if (val != null && val.toString().trim().isNotEmpty) {
        return formatDisplayTime(val.toString());
      }
    }
    return vehicleDetail.value.serverTime.isNotEmpty
        ? vehicleDetail.value.serverTime
        : 'N/A';
  }

  /// Duration for the live-tracking popup: how long the vehicle has been in
  /// its current status (calculated from today's route data).
  String get liveDialogDuration {
    if (currentStatusDuration.value.isNotEmpty) {
      return currentStatusDuration.value;
    }
    final d = vehicleDetail.value;
    return _isFallbackValue(d.runningDuration) ? '-' : d.runningDuration;
  }

  String get historyDialogDuration {
    if (_tappedStopDuration != null && historyTapIndex.value >= 0) {
      return _tappedStopDuration!;
    }
    return historyDisplayDuration;
  }

  String get historyDialogAddress {
    if (historyPoints.isNotEmpty) {
      final idx = _historyDialogPointIndex;
      final pt = historyPoints[idx];
      final addr = pt['address'] ?? pt['location'];
      if (addr != null && addr.toString().trim().isNotEmpty && addr != 'null') {
        return addr.toString();
      }
      // No address in the history point: use the reverse-geocoded one for
      // this exact point (never the vehicle's current address).
      final key = _historyAddressKey(idx);
      final cached = key == null ? null : _historyAddressCache[key];
      if (cached != null) return cached;
      // While playing (no tapped point) the point changes every frame, so
      // show coordinates instead of looking up every position.
      if (historyTapIndex.value < 0 && isPlaying.value) {
        final ll = _pointLatLng(pt);
        if (ll != null) {
          return '${ll.latitude.toStringAsFixed(5)}, '
              '${ll.longitude.toStringAsFixed(5)}';
        }
      }
      historyTapAddressTick.value; // rebuild when the lookup finishes
      _resolveHistoryAddress(idx);
      return 'Fetching address...';
    }
    return vehicleDetail.value.address.isNotEmpty
        ? vehicleDetail.value.address
        : 'Fetching location...';
  }

  // ---------------------------------------------------------------------
  // History: tap on the map / route point <-> history point mapping
  // ---------------------------------------------------------------------
  /// History point picked by tapping the map (-1 = follow the car).
  final RxInt historyTapIndex = (-1).obs;
  final Rxn<LatLng> historyTapPoint = Rxn<LatLng>();
  final RxInt historyTapAddressTick = 0.obs;
  final Map<String, String> _historyAddressCache = {};
  final Set<String> _historyAddressPending = {};

  /// Index in [historyPoints] the dialog should describe.
  int get _historyDialogPointIndex {
    if (historyPoints.isEmpty) return 0;
    final tap = historyTapIndex.value;
    if (tap >= 0 && tap < historyPoints.length) return tap;
    return _playbackPointIndex.clamp(0, historyPoints.length - 1);
  }

  /// History point the playback car is currently at.
  int get _playbackPointIndex {
    final idxs = _activeRouteSourceIndex();
    if (idxs.isEmpty) return 0;
    return idxs[_movingSegmentIndex.clamp(0, idxs.length - 1)];
  }

  String? _historyAddressKey(int idx) {
    if (idx < 0 || idx >= historyPoints.length) return null;
    final ll = _pointLatLng(historyPoints[idx]);
    if (ll == null) return null;
    return '${ll.latitude.toStringAsFixed(4)},${ll.longitude.toStringAsFixed(4)}';
  }

  /// Reverse-geocodes a history point that has no address of its own.
  Future<void> _resolveHistoryAddress(int idx) async {
    final key = _historyAddressKey(idx);
    if (key == null ||
        _historyAddressCache.containsKey(key) ||
        _historyAddressPending.contains(key)) {
      return;
    }
    final ll = _pointLatLng(historyPoints[idx])!;
    _historyAddressPending.add(key);
    try {
      final res = await dio_pkg.Dio().get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': ll.latitude,
          'lon': ll.longitude,
          'zoom': 18,
          'addressdetails': 0,
        },
      );
      final name = res.data is Map
          ? res.data['display_name']?.toString()
          : null;
      _historyAddressCache[key] = (name != null && name.isNotEmpty)
          ? name
          : '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
    } catch (e) {
      debugPrint('[History] Reverse geocode failed: $e');
      _historyAddressCache[key] =
          '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
    } finally {
      _historyAddressPending.remove(key);
      historyTapAddressTick.value++;
    }
  }

  /// Tap on the history map: show time + address of the nearest route
  /// point. Tapping away from the route closes the dialog.
  /// Tap on the history map. Only a tap ON the drawn route line opens the
  /// dialog (time, duration, address of that exact spot); a tap anywhere
  /// else just closes it.
  void onHistoryMapTap(LatLng tapped) {
    final route = getActiveRoutePoints();
    final srcIdx = _activeRouteSourceIndex();
    if (route.length < 2 || srcIdx.length != route.length) {
      hideHistoryMapDialog();
      return;
    }
    // Metres per screen pixel at the tap.
    double zoom = 14;
    try {
      zoom = historyMapController.camera.zoom;
    } catch (_) {}
    final mPerPx =
        156543.03392 *
        math.cos(tapped.latitude * math.pi / 180) /
        math.pow(2, zoom);
    final maxM = mPerPx * 16; // finger must be within ~16 px of the line

    // Nearest point on the line (projection onto each segment).
    final cosLat = math.cos(tapped.latitude * math.pi / 180);
    const mPerDeg = 111320.0;
    double bestD = double.infinity;
    int bestSeg = -1;
    double bestT = 0;
    LatLng? bestPt;
    for (int i = 0; i < route.length - 1; i++) {
      final a = route[i], b = route[i + 1];
      final ax = (a.longitude - tapped.longitude) * mPerDeg * cosLat;
      final ay = (a.latitude - tapped.latitude) * mPerDeg;
      final bx = (b.longitude - tapped.longitude) * mPerDeg * cosLat;
      final by = (b.latitude - tapped.latitude) * mPerDeg;
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      double t = len2 > 0 ? -(ax * dx + ay * dy) / len2 : 0;
      t = t.clamp(0.0, 1.0);
      final px = ax + dx * t, py = ay + dy * t;
      final d = math.sqrt(px * px + py * py);
      if (d < bestD) {
        bestD = d;
        bestSeg = i;
        bestT = t;
        bestPt = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
      }
    }
    if (bestSeg < 0 || bestD > maxM || bestPt == null) {
      hideHistoryMapDialog();
      return;
    }
    final idx = bestT < 0.5 ? srcIdx[bestSeg] : srcIdx[bestSeg + 1];
    _showHistoryPointDialog(idx, bestPt);
  }

  /// Opens the dialog for history point [idx] with the pin at [at].
  void _showHistoryPointDialog(int idx, LatLng at) {
    if (idx < 0 || idx >= historyPoints.length) return;
    _tappedStopDuration = _durationAtPoint(idx);
    historyTapIndex.value = idx;
    historyTapPoint.value = at;
    isHistoryMapDialogVisible.value = true;
  }

  /// Duration for a picked point: if the vehicle was parked there, how long
  /// it was parked; otherwise how long it had been travelling since the
  /// start of the selected period.
  String _durationAtPoint(int idx) {
    for (final st in historyStops) {
      final si = st['index'] as int;
      final s0 = st['start'] as DateTime;
      final s1 = st['end'] as DateTime;
      final t = _parseTimestamp(_pointTime(historyPoints[idx]));
      if (si == idx || (t != null && !t.isBefore(s0) && !t.isAfter(s1))) {
        return 'Parked ${_formatDuration(Duration(seconds: st['seconds'] as int))}';
      }
    }
    final t0 = _parseTimestamp(_pointTime(historyPoints.first));
    final t = _parseTimestamp(_pointTime(historyPoints[idx]));
    if (t0 == null || t == null) return '-';
    return _formatDuration(t.difference(t0));
  }

  /// Date the history period starts on (for the time picker).
  DateTime? get historyFirstTime => historyPoints.isEmpty
      ? null
      : _parseTimestamp(_pointTime(historyPoints.first));
  DateTime? get historyLastTime => historyPoints.isEmpty
      ? null
      : _parseTimestamp(_pointTime(historyPoints.last));

  /// Shows where the vehicle was at [when]: pin + dialog (time, duration,
  /// address) on that spot of the route, map moved there, and the playback
  /// car placed there so Play continues from that moment.
  void showHistoryAtTime(DateTime when) {
    if (historyPoints.isEmpty) {
      AppToast.show('No history loaded for this period');
      return;
    }
    final first = historyFirstTime, last = historyLastTime;
    if (first != null &&
        last != null &&
        (when.isBefore(first.subtract(const Duration(minutes: 1))) ||
            when.isAfter(last.add(const Duration(minutes: 1))))) {
      AppToast.show('No data at that time in the selected period');
      return;
    }
    // History point closest in time.
    int best = -1;
    int bestDiff = 1 << 62;
    for (int i = 0; i < historyPoints.length; i++) {
      final t = _parseTimestamp(_pointTime(historyPoints[i]));
      if (t == null || _pointLatLng(historyPoints[i]) == null) continue;
      final diff = t.difference(when).inSeconds.abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    if (best < 0) {
      AppToast.show('No location found for that time');
      return;
    }
    // Same spot on the drawn (road) line.
    final route = getActiveRoutePoints();
    final srcIdx = _activeRouteSourceIndex();
    int vertex = -1;
    if (srcIdx.length == route.length) {
      vertex = srcIdx.indexWhere((s) => s >= best);
    }
    final at = vertex >= 0 ? route[vertex] : _pointLatLng(historyPoints[best])!;

    // Car to that moment (paused), then pin + dialog.
    if (vertex >= 0 && route.length >= 2) {
      final cum = _cumulativeKm(route);
      if (cum.isNotEmpty && cum.last > 0)
        seekToProgress(cum[vertex] / cum.last);
    }
    _showHistoryPointDialog(best, at);
    try {
      final z = historyMapController.camera.zoom;
      historyMapController.move(at, z < 15 ? 16 : z);
    } catch (_) {}
  }

  void onHistoryCarTap() {
    historyTapIndex.value = -1;
    historyTapPoint.value = null;
    toggleHistoryMapDialog();
  }

  // Time keys a history point may use ('devicetime' is what the live
  // WebSocket sends, so history points most likely use it too).
  static const List<String> _pointTimeKeys = [
    'device_time',
    'devicetime',
    'deviceTime',
    'fix_time',
    'fixtime',
    'gps_time',
    'datetime',
    'date_time',
    'created_at',
    'timestamp',
    'time',
    'server_time',
    'servertime',
    'recorded_at',
  ];
  bool _warnedNoPointTime = false;

  /// The time of one history point, whichever key the API uses.
  dynamic _pointTime(Map<dynamic, dynamic> pt) {
    for (final k in _pointTimeKeys) {
      final v = pt[k];
      if (v != null) {
        final str = v.toString().trim();
        if (str.isNotEmpty && str != 'null' && str != '-') return v;
      }
    }
    if (!_warnedNoPointTime) {
      _warnedNoPointTime = true;
      debugPrint(
        '[History] No time field found on history point. Keys: ${pt.keys.toList()}',
      );
    }
    return null;
  }

  DateTime? _parseTimestamp(dynamic timeVal) {
    if (timeVal == null) return null;
    final str = timeVal.toString().trim();
    if (str.isEmpty || str == '-' || str == 'N/A') return null;

    // Epoch seconds / milliseconds
    if (RegExp(r'^\d{9,13}$').hasMatch(str)) {
      final n = int.tryParse(str);
      if (n != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          str.length >= 12 ? n : n * 1000,
        );
      }
    }

    final iso = DateTime.tryParse(str);
    // UTC times ('...Z') are shown in local time, like the rest of the app.
    if (iso != null) return iso.isUtc ? iso.toLocal() : iso;

    try {
      final parts = str.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          int p1 = int.parse(dateParts[0]);
          int p2 = int.parse(dateParts[1]);
          int p3 = int.parse(dateParts[2]);
          int year = p3 > 1000 ? p3 : p1;
          int day = p3 > 1000 ? p1 : p3;
          int month = p2;
          final timeParts = parts[1].split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          int second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          if (parts.length > 2 && parts[2].toUpperCase() == 'PM' && hour < 12) {
            hour += 12;
          } else if (parts.length > 2 &&
              parts[2].toUpperCase() == 'AM' &&
              hour == 12) {
            hour = 0;
          }
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    } catch (_) {}
    return null;
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) d = -d;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    } else if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }

  String formatDisplayTime(String raw) {
    if (raw.trim().isEmpty || raw == '-' || raw == 'N/A') return '-';
    final dt = _parseTimestamp(raw);
    if (dt != null) {
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day-$month-$year ${hour.toString().padLeft(2, '0')}:$minute:$second $period';
    }
    return raw;
  }

  final RxMap<String, String> statisticsData = <String, String>{
    'Route Length': '0 km',
    'Move Duration': '00:00:00',
    'Idle Duration': '00:00:00',
    'Stop Duration': '00:00:00',
    'Stop Count': '0',
    'Average Speed': '0 kmph',
    'Top Speed': '0 kmph',
    'Over Speed Count': '0',
    'Engine Hours': '00:00:00',
    'Odometer': '0 km',
  }.obs;

  String activeImei = '';

  final Rx<VehicleDetailData> vehicleDetail = VehicleDetailData(
    vehicleNumber: 'Loading...',
    odometerDigits: '0000000',
    timestamp: 'N/A',
    distanceKm: '0 km',
    speedKmph: 0,
    coordinates: 'N/A',
    address: 'Fetching location...',
    deviceTime: 'N/A',
    serverTime: 'N/A',
    runningDuration: 'N/A',
    idleDuration: 'N/A',
    stoppedDuration: 'N/A',
    inactiveDuration: 'N/A',
    avgSpeedKmph: '0',
    maxSpeedKmph: '0',
    todayOdoKm: '0',
    sensors: [
      SensorReadingItem(label: 'Battery', value: '-', iconType: 'battery'),
      SensorReadingItem(label: 'GSM Signal', value: '-', iconType: 'gsm'),
      SensorReadingItem(label: 'Ignition', value: '-', iconType: 'ignition'),
      SensorReadingItem(label: 'Network', value: '-', iconType: 'network'),
      SensorReadingItem(label: 'Altitude', value: '-', iconType: 'altitude'),
      SensorReadingItem(label: 'Fuel', value: '-', iconType: 'fuel'),
      SensorReadingItem(label: 'Temperature', value: '-', iconType: 'temp'),
      SensorReadingItem(label: 'Movement', value: '-', iconType: 'movement'),
    ],
  ).obs;

  @override
  void onInit() {
    super.onInit();
    ever(vehicleDetail, (_) => _applyTodayStats());
    _startLiveAnimationLoop();
    _bindToHomeController();
    placeMovingMarkerAtStart();
    // Profile > General Settings > Show History on Live: today's route is
    // drawn on the live map while the switch is ON.
    final settings = AppSettings.to;
    settings.ready.then(
      (_) => _applyHistoryOnLive(settings.showHistoryOnLive.value),
    );
    ever<bool>(settings.showHistoryOnLive, _applyHistoryOnLive);
  }

  void _applyHistoryOnLive(bool on) {
    // Quietly (no toast): the route fills in when today's points arrive.
    showLiveRoute.value = on;
    if (on) {
      _rebuildLiveOverlays();
    } else {
      liveTodayRoute.clear();
    }
  }

  // ---------------------------------------------------------------------
  // Today's statistics from the route data (track_vehicle, today 12 AM - now)
  // Used when the live snapshot / Home list do not send these values.
  // ---------------------------------------------------------------------
  final RxString currentStatus = ''.obs; // running / idle / stopped / inactive
  final RxString currentStatusDuration = ''.obs; // time in the current status
  Map<String, String> _todayStats = {};
  String? _todayStatsImei;
  DateTime? _todayStatsFetchedAt;
  bool _todayStatsInFlight = false;
  static const int _todayStatsRefreshSeconds = 60;
  static const double _statMovingKmh = 3.0;
  static const int _statGapSeconds = 900; // no data this long = inactive

  bool _isFallbackValue(String v) {
    final t = v.trim();
    return t.isEmpty ||
        t == '-' ||
        t == 'N/A' ||
        t == 'null' ||
        t == '0' ||
        t == '00:00:00';
  }

  String _hms(int seconds) {
    if (seconds < 0) seconds = 0;
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool? _pointIgnition(Map<String, dynamic> p) {
    final attrs = p['attributes'];
    final dynamic v =
        p['ignition'] ??
        p['ign'] ??
        p['acc'] ??
        p['engine'] ??
        (attrs is Map ? attrs['ignition'] : null);
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (['1', 'true', 'on', 'yes'].contains(s)) return true;
    if (['0', 'false', 'off', 'no'].contains(s)) return false;
    return null;
  }

  List<Map<String, dynamic>> _extractHistoryPoints(dynamic body) {
    final resData = body is Map ? (body['data'] ?? body) : body;
    List<dynamic> raw = [];
    if (resData is List) {
      raw = resData;
    } else if (resData is Map) {
      for (final k in [
        'location_history',
        'history',
        'locations',
        'track',
        'track_vehicle',
        'points',
        'route',
        'items',
        'data',
        'list',
      ]) {
        if (resData[k] is List) {
          raw = resData[k];
          break;
        }
      }
    }
    return raw
        .whereType<Map>()
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  /// Running / idle / stopped / inactive time, avg & max speed and the
  /// current status duration, all calculated from today's route points.
  Map<String, String> _computeTodayStats(
    List<Map<String, dynamic>> pts,
    DateTime now,
  ) {
    final rows = <(DateTime, double, bool?)>[];
    for (final p in pts) {
      final t = _parseTimestamp(_pointTime(p));
      if (t == null) continue;
      final spd = double.tryParse(p['speed']?.toString() ?? '') ?? 0.0;
      rows.add((t, spd, _pointIgnition(p)));
    }
    if (rows.isEmpty) return {};
    rows.sort((a, b) => a.$1.compareTo(b.$1));

    String stateOf((DateTime, double, bool?) r) => r.$2 >= _statMovingKmh
        ? 'running'
        : (r.$3 == true ? 'idle' : 'stopped');

    final totals = <String, int>{
      'running': 0,
      'idle': 0,
      'stopped': 0,
      'inactive': 0,
    };
    double maxSpeed = 0, sumMoving = 0;
    int nMoving = 0;

    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (r.$2 > maxSpeed) maxSpeed = r.$2;
      if (r.$2 >= _statMovingKmh) {
        sumMoving += r.$2;
        nMoving++;
      }
      final nextT = i < rows.length - 1 ? rows[i + 1].$1 : now;
      final dt = nextT.difference(r.$1).inSeconds;
      if (dt <= 0) continue;
      if (dt > _statGapSeconds) {
        totals['inactive'] = totals['inactive']! + dt;
      } else {
        final st = stateOf(r);
        totals[st] = totals[st]! + dt;
      }
    }

    // Current status and how long the vehicle has been in it.
    final last = rows.last;
    final sinceLast = now.difference(last.$1).inSeconds;
    String cur;
    DateTime since;
    if (sinceLast > _statGapSeconds) {
      cur = 'inactive';
      since = last.$1;
    } else {
      cur = stateOf(last);
      int j = rows.length - 1;
      while (j > 0 &&
          stateOf(rows[j - 1]) == cur &&
          rows[j].$1.difference(rows[j - 1].$1).inSeconds <= _statGapSeconds) {
        j--;
      }
      since = rows[j].$1;
    }

    return {
      'running': _hms(totals['running']!),
      'idle': _hms(totals['idle']!),
      'stopped': _hms(totals['stopped']!),
      'inactive': _hms(totals['inactive']!),
      'avg': nMoving > 0 ? (sumMoving / nMoving).toStringAsFixed(0) : '0',
      'max': maxSpeed.toStringAsFixed(0),
      'status': cur,
      'statusDuration': _hms(now.difference(since).inSeconds),
    };
  }

  /// Fetches today's route (at most once a minute) and fills the daily
  /// statistics. Uses the existing track_vehicle endpoint.
  Future<void> _refreshTodayStats() async {
    final imei = activeImei;
    if (imei.isEmpty || _todayStatsInFlight || selectedTopTab.value != -1) {
      return;
    }
    final fresh =
        _todayStatsImei == imei &&
        _todayStatsFetchedAt != null &&
        DateTime.now().difference(_todayStatsFetchedAt!).inSeconds <
            _todayStatsRefreshSeconds;
    if (fresh) {
      _applyTodayStats();
      return;
    }
    _todayStatsInFlight = true;
    try {
      final now = DateTime.now();
      final response = await DioClient().get(
        ApiEndPoints.vehicleHistory,
        queryParameters: {
          'imei': imei,
          'from_date': _formatInitialDate(now, isStart: true),
          'to_date': _formatInitialDate(now, isStart: false),
          'page': '1',
        },
      );
      if (_liveDisposed || imei != activeImei) return;
      final pts = _extractHistoryPoints(response.data);
      _todayPoints = pts;
      _rebuildLiveOverlays();
      if (!_liveHeadingKnown) {
        final h = _headingFromToday();
        if (h != null) liveMarkerBearing.value = h;
      }
      _todayStats = _computeTodayStats(pts, now);
      _todayStatsImei = imei;
      _todayStatsFetchedAt = now;
      _applyTodayStats();
    } catch (e) {
      debugPrint('[TodayStats] Error: $e');
    } finally {
      _todayStatsInFlight = false;
    }
  }

  /// Replaces placeholder values (00:00:00, '-', N/A) with today's
  /// calculated values. Real values from the API are never overwritten.
  void _applyTodayStats() {
    if (_todayStats.isEmpty || _todayStatsImei != activeImei) return;
    currentStatus.value = _todayStats['status'] ?? '';
    currentStatusDuration.value = _todayStats['statusDuration'] ?? '';

    final d = vehicleDetail.value;
    String pick(String current, String key) =>
        _isFallbackValue(current) ? (_todayStats[key] ?? current) : current;

    final running = pick(d.runningDuration, 'running');
    final idle = pick(d.idleDuration, 'idle');
    final stopped = pick(d.stoppedDuration, 'stopped');
    final inactive = pick(d.inactiveDuration, 'inactive');
    final avg = pick(d.avgSpeedKmph, 'avg');
    final max = pick(d.maxSpeedKmph, 'max');

    if (running == d.runningDuration &&
        idle == d.idleDuration &&
        stopped == d.stoppedDuration &&
        inactive == d.inactiveDuration &&
        avg == d.avgSpeedKmph &&
        max == d.maxSpeedKmph) {
      return; // nothing to change (also stops the ever() loop)
    }

    vehicleDetail.value = VehicleDetailData(
      vehicleNumber: d.vehicleNumber,
      odometerDigits: d.odometerDigits,
      timestamp: d.timestamp,
      distanceKm: d.distanceKm,
      speedKmph: d.speedKmph,
      coordinates: d.coordinates,
      latitude: d.latitude,
      longitude: d.longitude,
      address: d.address,
      deviceTime: d.deviceTime,
      serverTime: d.serverTime,
      runningDuration: running,
      idleDuration: idle,
      stoppedDuration: stopped,
      inactiveDuration: inactive,
      avgSpeedKmph: avg,
      maxSpeedKmph: max,
      todayOdoKm: d.todayOdoKm,
      sensors: d.sensors,
    );
  }

  // ---------------------------------------------------------------------
  // Map toolbar buttons (Live + History)
  // ---------------------------------------------------------------------
  /// Google tile layer: m = road, y = hybrid (satellite + labels),
  /// s = satellite.
  final RxString mapLayer = 'm'.obs;
  static const Map<String, String> _mapLayerNames = {
    'm': 'Road map',
    'y': 'Hybrid map',
    's': 'Satellite map',
  };

  /// Map button: Road -> Hybrid -> Satellite -> Road.
  void cycleMapLayer() {
    _streetViewMode = false;
    const order = ['m', 'y', 's'];
    final i = order.indexOf(mapLayer.value);
    mapLayer.value = order[(i + 1) % order.length];
    AppToast.show(_mapLayerNames[mapLayer.value] ?? 'Map');
  }

  bool _usesGoogleTiles(String base) => base.contains('lyrs=');

  /// Tile URL for the selected map type, based on the app's own URL.
  String tileUrlFor(String base) {
    if (mapLayer.value == 'm') return base;
    if (_usesGoogleTiles(base)) {
      return base.replaceFirst(
        RegExp(r'lyrs=[a-z,]+'),
        'lyrs=${mapLayer.value}',
      );
    }
    return 'https://mt{s}.google.com/vt/lyrs=${mapLayer.value}&x={x}&y={y}&z={z}';
  }

  List<String> tileSubdomainsFor(String base, List<String> baseSubs) {
    if (mapLayer.value == 'm' || _usesGoogleTiles(base)) return baseSubs;
    return const ['0', '1', '2', '3'];
  }

  /// Bottom panel on the live page (action cards on desktop, the draggable
  /// details sheet on mobile). Can be closed so the map / dialog is visible.
  final RxBool isBottomPanelVisible = true.obs;
  void hideBottomPanel() => isBottomPanelVisible.value = false;
  void showBottomPanel() => isBottomPanelVisible.value = true;

  /// Street View card: switches the live map to the HYBRID style
  /// (satellite + road names), zooms in on the vehicle and follows it as it
  /// moves. Tapping it again returns to the normal road map.
  /// (No external link / app is opened.)
  bool _streetViewMode = false;

  void openStreetView() {
    if (_streetViewMode && mapLayer.value == 'y') {
      _streetViewMode = false;
      mapLayer.value = 'm';
      AppToast.show('Road map');
      return;
    }

    final pos =
        liveMarkerPosition.value ??
        ((vehicleDetail.value.latitude != null &&
                vehicleDetail.value.longitude != null)
            ? LatLng(
                vehicleDetail.value.latitude!,
                vehicleDetail.value.longitude!,
              )
            : null);

    _streetViewMode = true;
    mapLayer.value = 'y';
    isLiveLocked.value = true; // follow the vehicle while it moves

    if (pos != null && (pos.latitude != 0 || pos.longitude != 0)) {
      try {
        final zoom = liveMapController.camera.zoom;
        liveMapController.move(pos, zoom < 18 ? 18 : zoom);
      } catch (_) {}
    }
    AppToast.show('Hybrid view - following vehicle');
  }

  /// Lock button: follow the vehicle on/off.
  void toggleLiveLock() {
    if (isLiveLocked.value) {
      isLiveLocked.value = false;
      AppToast.show('Map unlocked');
    } else {
      recenterLiveMap(); // sets isLiveLocked = true and centres the car
      AppToast.show('Map locked to vehicle');
    }
  }

  /// Compass button: turn the map back to north-up.
  void resetLiveNorth() {
    try {
      final r = liveMapController.camera.rotation % 360;
      if (r.abs() < 0.5 || (360 - r).abs() < 0.5) {
        AppToast.show('Map is already facing north');
        return;
      }
      liveMapController.rotate(0);
      AppToast.show('Map turned to north');
    } catch (_) {}
  }

  // ---- Parking stops -------------------------------------------------
  static const int _stopMinSeconds = 300; // stationary 5 min = a stop
  static const double _stopRadiusM = 40;

  /// Stops in [pts]: vehicle stationary >= 5 min. Each stop has
  /// point, index (in [pts]), start, end, seconds.
  List<Map<String, dynamic>> _computeStops(List<Map<String, dynamic>> pts) {
    final stops = <Map<String, dynamic>>[];
    int? startIdx;
    LatLng? startLl;
    DateTime? startT;

    void close(int endIdx) {
      if (startIdx == null || startT == null) return;
      final endT = _parseTimestamp(_pointTime(pts[endIdx]));
      if (endT == null) return;
      final secs = endT.difference(startT!).inSeconds;
      if (secs >= _stopMinSeconds) {
        stops.add({
          'point': startLl,
          'index': startIdx,
          'start': startT,
          'end': endT,
          'seconds': secs,
        });
      }
    }

    for (int i = 0; i < pts.length; i++) {
      final ll = _pointLatLng(pts[i]);
      final t = _parseTimestamp(_pointTime(pts[i]));
      if (ll == null || t == null) continue;
      final spd = double.tryParse(pts[i]['speed']?.toString() ?? '') ?? 0.0;
      final stationary =
          spd < _statMovingKmh &&
          (startLl == null || _distanceMeters(startLl!, ll) <= _stopRadiusM);
      if (stationary) {
        if (startIdx == null) {
          startIdx = i;
          startLl = ll;
          startT = t;
        }
      } else {
        if (startIdx != null) close(i);
        startIdx = null;
        startLl = null;
        startT = null;
        if (spd < _statMovingKmh) {
          startIdx = i;
          startLl = ll;
          startT = t;
        }
      }
    }
    if (startIdx != null) close(pts.length - 1);
    return stops;
  }

  String _clock(DateTime t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  String stopLabel(Map<String, dynamic> stop) {
    final st = stop['start'] as DateTime;
    final en = stop['end'] as DateTime;
    final dur = _formatDuration(Duration(seconds: stop['seconds'] as int));
    return 'Parked ${_clock(st)} - ${_clock(en)} ($dur)';
  }

  // ---- Live: P (today's stops) and route (today's path) --------------
  List<Map<String, dynamic>> _todayPoints = [];
  final RxBool showLiveStops = false.obs;
  final RxBool showLiveRoute = false.obs;
  final RxList<Map<String, dynamic>> liveStops = <Map<String, dynamic>>[].obs;
  final RxList<LatLng> liveTodayRoute = <LatLng>[].obs;

  void _rebuildLiveOverlays() {
    if (showLiveStops.value) liveStops.assignAll(_computeStops(_todayPoints));
    if (showLiveRoute.value) {
      liveTodayRoute.assignAll([
        for (final p in _todayPoints)
          if (_pointLatLng(p) != null) _pointLatLng(p)!,
      ]);
    }
  }

  /// Direction the vehicle last drove in, from today's route: from the
  /// point ~25 m before the last point to the last point (drift ignored).
  double? _headingFromToday() {
    LatLng? last;
    for (int i = _todayPoints.length - 1; i >= 0; i--) {
      final ll = _pointLatLng(_todayPoints[i]);
      if (ll == null) continue;
      if (last == null) {
        last = ll;
        continue;
      }
      if (_calculateDistance(ll, last) >= 25.0) return _getBearing(ll, last);
    }
    return null;
  }

  Future<void> _ensureTodayPoints() async {
    // A background fetch may already be running: wait for it (up to 15 s)
    // instead of returning with no points (P showed nothing).
    for (int i = 0; i < 60 && _todayStatsInFlight; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (_todayPoints.isEmpty || _todayStatsImei != activeImei) {
      _todayStatsFetchedAt = null; // force a fetch now
      await _refreshTodayStats();
    }
  }

  /// P button (live): show / hide today's parking stops.
  Future<void> toggleLiveStops() async {
    showLiveStops.value = !showLiveStops.value;
    if (!showLiveStops.value) {
      liveStops.clear();
      return;
    }
    await _ensureTodayPoints();
    if (!showLiveStops.value) return; // turned off meanwhile
    _rebuildLiveOverlays();
    if (liveStops.isEmpty) {
      AppToast.show('No stops today');
      return;
    }
    // Stops are usually away from where the car is now: show the car and
    // every P marker. Follow-vehicle is paused so the map stays there; the
    // lock button follows the car again.
    final pts = <LatLng>[
      for (final st in liveStops) st['point'] as LatLng,
      if (liveMarkerPosition.value != null) liveMarkerPosition.value!,
    ];
    try {
      isLiveLocked.value = false;
      if (pts.length == 1) {
        liveMapController.move(pts.first, 16);
      } else {
        liveMapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(pts),
            padding: const EdgeInsets.all(60),
          ),
        );
      }
    } catch (e) {
      debugPrint('[LiveStops] fit error: $e');
    }
  }

  /// Route button (live): show / hide today's travelled path.
  Future<void> toggleLiveRoute() async {
    showLiveRoute.value = !showLiveRoute.value;
    if (!showLiveRoute.value) {
      liveTodayRoute.clear();
      return;
    }
    await _ensureTodayPoints();
    _rebuildLiveOverlays();
    if (liveTodayRoute.length < 2) AppToast.show('No route recorded today');
  }

  void onLiveStopTap(Map<String, dynamic> stop) =>
      AppToast.show(stopLabel(stop));

  // ---- History: P (stops) and location points ------------------------
  final RxBool showHistoryStops = false.obs;
  final RxBool showHistoryPoints = false.obs;
  List<Map<String, dynamic>> _historyStopsCache = [];
  String _historyStopsSig = '';
  String? _tappedStopDuration;

  List<Map<String, dynamic>> get historyStops {
    final sig = _historySig();
    if (sig != _historyStopsSig) {
      _historyStopsCache = _computeStops(historyPoints);
      _historyStopsSig = sig;
    }
    return _historyStopsCache;
  }

  /// Recorded GPS points to draw as dots (thinned for very long ranges).
  List<LatLng> get historyPointDots {
    final raw = _rawRoute().$1;
    if (raw.length <= 1500) return raw;
    final step = (raw.length / 1500).ceil();
    return [for (int i = 0; i < raw.length; i += step) raw[i]];
  }

  /// P button (history): show / hide stops on the route.
  void toggleHistoryStops() {
    showHistoryStops.value = !showHistoryStops.value;
    // Not playing: show the whole route with all its P markers in view.
    if (showHistoryStops.value && !isPlaying.value) fitHistoryRoute();
  }

  /// Location button (history): show / hide every recorded point.
  void toggleHistoryPoints() {
    showHistoryPoints.value = !showHistoryPoints.value;
    if (showHistoryPoints.value) {
      final n = _rawRoute().$1.length;
      AppToast.show(
        n == 0 ? 'No location points in this period' : '$n location points',
      );
    }
  }

  /// Tap on a P marker (history): dialog shows that stop.
  void onHistoryStopTap(Map<String, dynamic> stop) {
    final idx = stop['index'] as int;
    historyTapIndex.value = idx;
    historyTapPoint.value = stop['point'] as LatLng?;
    _tappedStopDuration = _formatDuration(
      Duration(seconds: stop['seconds'] as int),
    );
    isHistoryMapDialogVisible.value = true;
  }

  /// Picks the vehicle this screen is showing from a Home list refresh.
  /// FIX: once a vehicle is open, a Home refresh must never change it, even
  /// if the list order changes or selectedVehicleIndex is reset elsewhere.
  /// The dashboard index is only used for the very first vehicle.
  Vehicle _resolveHomeVehicle(List<Vehicle> list) {
    if (activeImei.isNotEmpty) {
      for (final v in list) {
        if (v.deviceId == activeImei) return v;
      }
    }
    final dashCtrl = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;
    final idx =
        (dashCtrl != null && dashCtrl.selectedVehicleIndex.value < list.length)
        ? dashCtrl.selectedVehicleIndex.value
        : 0;
    return list[idx];
  }

  void _bindToHomeController() {
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      if (homeCtrl.vehicles.isNotEmpty) {
        updateFromVehicle(_resolveHomeVehicle(homeCtrl.vehicles));
      }
      ever(homeCtrl.vehicles, (List<Vehicle> list) {
        if (list.isNotEmpty) {
          updateFromVehicle(_resolveHomeVehicle(list));
        }
      });
    }
  }

  /// An odometer only goes up. A smaller reading for the same vehicle comes
  /// from a wrong field (today's km, a date-range total...) and is ignored.
  /// Only Update Odometer (a user action) may set a lower value.
  String _keepOdometerUp(String next, String current) {
    final n = int.tryParse(next) ?? 0;
    final c = int.tryParse(current) ?? 0;
    if (n == 0) return current;
    if (c > 0 && n < c) return current;
    return next;
  }

  String _extractOdometerDigits(dynamic val, {dynamic fallback}) {
    String? tryParse(dynamic v) {
      if (v == null) return null;
      final str = v.toString().trim();
      if (str.isEmpty || str == '-' || str == 'N/A' || str == 'null')
        return null;
      final clean = str.split('.').first.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty && clean != '0' && clean != '0000000') {
        return clean.length >= 7 ? clean : clean.padLeft(7, '0');
      }
      return null;
    }

    final primary = tryParse(val);
    if (primary != null) return primary;

    final second = tryParse(fallback);
    if (second != null) return second;

    return '0000000';
  }

  bool _sensorKeysLogged = false;

  /// All values from the response in one flat, lower-case-keyed map,
  /// including nested maps where trackers usually put sensor data.
  Map<String, dynamic> _sensorLookup(Map<String, dynamic>? raw) {
    final out = <String, dynamic>{};
    void addAll(dynamic m, [int depth = 0]) {
      if (m is! Map || depth > 3) return;
      m.forEach((k, v) {
        final key = k.toString().toLowerCase();
        if (v is Map) {
          addAll(v, depth + 1);
        } else {
          out.putIfAbsent(key, () => v);
        }
      });
    }

    if (raw != null) {
      // Top level first, then the usual nested containers.
      raw.forEach((k, v) {
        if (v is! Map) out[k.toString().toLowerCase()] = v;
      });
      for (final k in [
        'current_position',
        'position',
        'vehicle_info',
        'attributes',
        'io',
        'io_data',
        'io_elements',
        'sensors',
        'params',
        'other',
        'data',
      ]) {
        addAll(raw[k]);
      }
    }
    return out;
  }

  /// First usable value among [keys]. With [minValue], numeric values below
  /// it are skipped (e.g. power = 1 meaning "connected", not volts).
  String? _pickSensor(
    Map<String, dynamic> sv,
    List<String> keys, {
    double? minValue,
  }) {
    for (final k in keys) {
      final v = sv[k];
      if (v == null || v is bool) continue;
      final s = v.toString().trim();
      if (s.isEmpty || s == 'null' || s == '-' || s.toUpperCase() == 'N/A') {
        continue;
      }
      if (minValue != null) {
        final n = double.tryParse(s.replaceAll(RegExp(r'[^0-9.\-]'), ''));
        if (n != null && n < minValue) continue;
      }
      return s;
    }
    return null;
  }

  void _logSensorKeysOnce(Map<String, dynamic> sv) {
    if (_sensorKeysLogged || sv.length < 5) return;
    _sensorKeysLogged = true;
    debugPrint('[Sensors] Keys in response: ${sv.keys.toList()}');
  }

  List<SensorReadingItem> _buildDynamicSensors({
    LiveCurrentPosition? pos,
    Map<String, dynamic>? rawMap,
    Vehicle? vehicle,
    bool isStale = false,
    bool keepPrevious = true,
  }) {
    final ignition =
        pos?.ignition ??
        (rawMap?['ignition'] is int
            ? rawMap!['ignition'] as int
            : int.tryParse(rawMap?['ignition']?.toString() ?? '')) ??
        (vehicle?.isIgnitionOn == true ? 1 : 0);

    // Sensor values are looked up under many key names and inside nested
    // maps (current_position, attributes, io...), and Teltonika IO ids.
    final sv = _sensorLookup(rawMap);

    int? asFlag(dynamic v) {
      if (v == null || v is Map || v is List) return null;
      if (v is bool) return v ? 1 : 0;
      final t = v.toString().trim().toLowerCase();
      if (t == 'on' || t == 'true') return 1;
      if (t == 'off' || t == 'false') return 0;
      return int.tryParse(t);
    }

    String onOff(int? f) => f == null ? '-' : (f == 1 ? 'ON' : 'OFF');

    // Battery = power key: 1 -> ON, 0 -> OFF.
    final powerVal = onOff(pos?.power ?? asFlag(sv['power']));

    // Ignition key: 1 -> ON, 0 -> OFF (only when the response has it).
    final ignitionFlag =
        pos?.ignition ??
        asFlag(sv['ignition']) ??
        (vehicle != null ? (vehicle.isIgnitionOn ? 1 : 0) : null);
    final ignitionVal = onOff(ignitionFlag);

    // GSM signal strength (e.g. 13).
    final gsmRaw =
        _pickSensor(sv, ['gsm_signal_strength', 'gsm_signal', 'gsm', 'rssi']) ??
        pos?.gsmSignalStrength;
    final gsmVal = (gsmRaw != null && gsmRaw.isNotEmpty && gsmRaw != 'null')
        ? gsmRaw
        : '-';

    // Network operator (e.g. BSNLXX).
    final networkVal =
        _pickSensor(sv, ['network', 'network_operator', 'operator']) ?? '-';

    // Altitude in metres (e.g. 14 -> 14 m).
    final altRaw = pos?.altitude ?? _pickSensor(sv, ['altitude', 'alt']);
    final altitudeVal =
        (altRaw != null && altRaw.isNotEmpty && altRaw != 'null')
        ? (altRaw.toLowerCase().contains('m') ? altRaw : '$altRaw m')
        : '-';

    // Fuel level (shown when the tracker sends one).
    final fuelRaw = _pickSensor(sv, [
      'fuel_level',
      'fuellevel',
      'fuel_percent',
      'fuel_percentage',
      'fuel',
      'fuel_liters',
      'fuel_litres',
      'io89', // Teltonika fuel level %
      'io48', // Teltonika fuel level
    ]);
    String fuelVal = '-';
    if (fuelRaw != null) {
      final low = fuelRaw.toLowerCase();
      fuelVal = (low.contains('%') || low.contains('l'))
          ? fuelRaw
          : '$fuelRaw%';
    }

    final tempRaw = _pickSensor(sv, [
      'temperature',
      'temp',
      'temp1',
      'temperature1',
      'temperature_1',
      'engine_temp',
      'coolant_temp',
      'device_temp',
      'devicetemp',
      'io72', // Teltonika Dallas temperature 1 (0.1 C)
      'io201',
    ]);
    String tempVal = '-';
    if (tempRaw != null) {
      if (tempRaw.contains('°')) {
        tempVal = tempRaw;
      } else {
        final n = double.tryParse(tempRaw.replaceAll(RegExp(r'[^0-9.\-]'), ''));
        if (n != null) {
          final c = n.abs() > 200 ? n / 10 : n; // 0.1 C units -> C
          tempVal = '${c.toStringAsFixed(c % 1 == 0 ? 0 : 1)}°C';
        }
      }
    }
    if (tempVal == '-') _logSensorKeysOnce(sv);

    final speedVal = isStale
        ? 0.0
        : (pos?.speed ??
              double.tryParse(
                rawMap?['speed']?.toString() ?? vehicle?.speed ?? '0',
              ) ??
              0.0);
    final movement1 = speedVal > 0
        ? 'Moving'
        : (ignition == 1 ? 'Idle' : 'Stopped');

    // Tiles (in this order): Battery (power), GSM Signal, Ignition,
    // Network, Altitude, Fuel, Temperature, Movement.
    final built = [
      SensorReadingItem(label: 'Battery', value: powerVal, iconType: 'battery'),
      SensorReadingItem(label: 'GSM Signal', value: gsmVal, iconType: 'gsm'),
      SensorReadingItem(
        label: 'Ignition',
        value: ignitionVal,
        iconType: 'ignition',
      ),
      SensorReadingItem(
        label: 'Network',
        value: networkVal,
        iconType: 'network',
      ),
      SensorReadingItem(
        label: 'Altitude',
        value: altitudeVal,
        iconType: 'altitude',
      ),
      SensorReadingItem(label: 'Fuel', value: fuelVal, iconType: 'fuel'),
      SensorReadingItem(label: 'Temperature', value: tempVal, iconType: 'temp'),
      SensorReadingItem(
        label: 'Movement',
        value: movement1,
        iconType: 'movement',
      ),
    ];

    // FIX: an update that does not carry a sensor (e.g. the Home list has no
    // satellites / accuracy) must not blank the tile to '-'. Keep the last
    // known value for the same vehicle until a new value arrives.
    if (!keepPrevious) return built;
    final previous = <String, String>{
      for (final s in vehicleDetail.value.sensors) s.iconType: s.value,
    };
    return [
      for (final s in built)
        (s.value == '-' &&
                previous[s.iconType] != null &&
                previous[s.iconType] != '-')
            ? SensorReadingItem(
                label: s.label,
                value: previous[s.iconType]!,
                iconType: s.iconType,
              )
            : s,
    ];
  }

  /// Update vehicle details from a selected [Vehicle] model
  void updateFromVehicle(Vehicle v) {
    if (activeImei.isNotEmpty && activeImei != v.deviceId) {
      final caller = StackTrace.current
          .toString()
          .split('\n')
          .take(6)
          .join('\n');
      debugPrint(
        '[VehicleDetail] Vehicle switched $activeImei -> ${v.deviceId} (${v.plateNumber}). Called from:\n$caller',
      );
    }
    final bool sameVehicle = activeImei == v.deviceId;
    activeImei = v.deviceId;
    // FIX: Home list data can be old (e.g. last packet 35 min ago). An old
    // position must not show its old speed / "Moving" as if live.
    final bool isStale = _isStaleFix(v.lastUpdated);
    final speed = isStale ? 0.0 : (double.tryParse(v.speed) ?? 0.0);
    final lat = v.latitude;
    final lng = v.longitude;
    final coordStr = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
        : 'Coordinates N/A';

    final initialSensors = _buildDynamicSensors(
      vehicle: v,
      rawMap: {'speed': v.speed, 'ignition': v.isIgnitionOn ? 1 : 0},
      isStale: isStale,
      keepPrevious: sameVehicle,
    );

    // FIX: the Home list usually has no status duration. Writing '00:00:00'
    // on every refresh wiped the real durations from the live snapshot.
    // Keep the values already shown for this vehicle; the Home duration (if
    // any) only belongs to the vehicle's CURRENT status.
    final prev = vehicleDetail.value;
    final rawDur = v.statusDuration.trim();
    final hasDur =
        rawDur.isNotEmpty &&
        rawDur.toUpperCase() != 'N/A' &&
        rawDur.toLowerCase() != 'null';
    final curStatus = v.status.trim().toLowerCase();
    String durFor(String status, String previous) {
      if (hasDur && curStatus == status) return rawDur;
      return sameVehicle ? previous : '00:00:00';
    }

    // Odometer only from a real odometer value (not distance / today's km).
    final homeOdo = _extractOdometerDigits(v.odometer);
    final initialOdo = sameVehicle
        ? _keepOdometerUp(homeOdo, prev.odometerDigits)
        : homeOdo;

    vehicleDetail.value = VehicleDetailData(
      vehicleNumber: v.plateNumber,
      odometerDigits: initialOdo,
      timestamp: (sameVehicle && !_isFallbackValue(prev.timestamp))
          ? prev.timestamp
          : (v.lastUpdated.isNotEmpty ? v.lastUpdated : 'N/A'),
      distanceKm: v.todayKm,
      speedKmph: speed.toInt(),
      coordinates: coordStr,
      latitude: lat,
      longitude: lng,
      address: v.locationLabel,
      // Device Time = the tracker's 'devicetime' (from the snapshot / live
      // updates). The Home list only has last_update (server time), so it is
      // used just until the first snapshot arrives.
      deviceTime: (sameVehicle && !_isFallbackValue(prev.deviceTime))
          ? prev.deviceTime
          : v.lastUpdated,
      serverTime: v.lastUpdated.isNotEmpty ? v.lastUpdated : prev.serverTime,
      runningDuration: durFor('running', prev.runningDuration),
      idleDuration: durFor('idle', prev.idleDuration),
      stoppedDuration: durFor('stopped', prev.stoppedDuration),
      inactiveDuration: durFor('inactive', prev.inactiveDuration),
      // Avg / Max are daily figures, not the current speed. Keep what the
      // live snapshot or today's route calculation already provided.
      avgSpeedKmph: sameVehicle ? prev.avgSpeedKmph : '-',
      maxSpeedKmph: sameVehicle ? prev.maxSpeedKmph : '-',
      // Keep the snapshot's today_km for the same vehicle; Home list value
      // (may carry a "Km" suffix) is only used for a newly opened vehicle.
      todayOdoKm: (sameVehicle && !_isFallbackValue(prev.todayOdoKm))
          ? prev.todayOdoKm
          : v.todayKm.replaceAll(RegExp(r'[^0-9.]'), ''),
      sensors: initialSensors,
    );

    // FIX: when the same vehicle is already being live-tracked, a Home list
    // refresh must NOT snap the marker or restart the socket. Its position is
    // fed into the glide engine like any other fix (older fixes are ignored),
    // so the car keeps moving smoothly even if the snapshot has no position.
    final bool isSameLiveSession =
        selectedTopTab.value == -1 &&
        _liveTrackingImei != null &&
        _liveTrackingImei == v.deviceId;

    final bool hasHomeFix =
        lat != null && lng != null && (lat != 0.0 || lng != 0.0);

    // The Home list position has no device time and is often older than
    // the snapshot / WebSocket fix: feeding it made the car go BACK and
    // then forward again (and turn around). Use it only until the first
    // timed fix of this live session has arrived.
    if (isSameLiveSession && hasHomeFix && _lastLiveFixTime == null) {
      _onLiveDevicePosition(
        LatLng(lat!, lng!),
        speed,
        status: isStale ? 'stale' : v.status,
        // Not a device time (Home list last_update is server time): do not
        // use it for the out-of-order check, or real fixes get dropped.
        deviceTime: null,
      );
    } else if (!isSameLiveSession && hasHomeFix) {
      final loc = LatLng(lat!, lng!);
      _snapLiveMarkerTo(loc, speed);
      isLiveMoving.value =
          !isStale && (speed > 0 || v.status.toLowerCase() == 'running');
    }

    if (v.deviceId.isNotEmpty) {
      if (selectedTopTab.value == -1) {
        // Same API call as before; for an active session it only refreshes
        // the snapshot instead of resetting the whole live engine.
        startLiveTracking(v.deviceId, reconnectOnly: isSameLiveSession);
        _refreshTodayStats();
      } else {
        loadVehicleSnapshot(v.deviceId);
      }
      loadLiveTrack(v.deviceId);
      loadStatistics(imei: v.deviceId);
      loadVehicleHistory(imei: v.deviceId);
    }
  }

  /// Load live tracking snapshot for vehicle by IMEI (GET /live_track_snapshot)
  Future<void> loadVehicleSnapshot(String imei) async {
    if (imei.isEmpty) return;
    if (selectedTopTab.value == -1) {
      await startLiveTracking(imei);
      return;
    }
    try {
      isLoading.value = true;
      activeImei = imei;

      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei},
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final currentPos = data['current_position'] ?? data['vehicle_info'];
        final todayStats = data['today_statistics'] is Map
            ? Map<String, dynamic>.from(data['today_statistics'])
            : null;

        if (currentPos != null && currentPos is Map) {
          final lat = double.tryParse(currentPos['latitude']?.toString() ?? '');
          final lng = double.tryParse(
            currentPos['longitude']?.toString() ?? '',
          );
          final speed =
              double.tryParse(currentPos['speed']?.toString() ?? '0') ?? 0.0;
          final rawOdo =
              currentPos['odometer'] ??
              currentPos['total_kilometers_traveled'] ??
              data['vehicle_info']?['odometer'] ??
              data['vehicle_info']?['total_kilometers_traveled'] ??
              data['odometer'];

          final dynSensors = _buildDynamicSensors(
            rawMap: Map<String, dynamic>.from(currentPos),
          );

          vehicleDetail.update((val) {
            if (val != null) {
              vehicleDetail.value = VehicleDetailData(
                vehicleNumber:
                    currentPos['vehicle_number']?.toString() ??
                    currentPos['name']?.toString() ??
                    val.vehicleNumber,
                odometerDigits: _extractOdometerDigits(
                  rawOdo,
                  fallback: val.odometerDigits,
                ),
                timestamp:
                    currentPos['device_time']?.toString() ?? val.timestamp,
                // Today's distance only. position 'kilometer' is the
                // device's running counter (e.g. 4318.51), not today's km.
                distanceKm: todayStats?['total_kilometers_today'] != null
                    ? '${todayStats!['total_kilometers_today']} km'
                    : val.distanceKm,
                speedKmph: speed.toInt(),
                coordinates: (lat != null && lng != null)
                    ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                    : val.coordinates,
                latitude: lat ?? val.latitude,
                longitude: lng ?? val.longitude,
                address:
                    currentPos['address']?.toString() ??
                    currentPos['location']?.toString() ??
                    val.address,
                deviceTime:
                    currentPos['device_time']?.toString() ?? val.deviceTime,
                serverTime:
                    currentPos['server_time']?.toString() ?? val.serverTime,
                runningDuration:
                    todayStats?['running_duration']?.toString() ??
                    todayStats?['display_running_duration']?.toString() ??
                    val.runningDuration,
                idleDuration:
                    todayStats?['idle_duration']?.toString() ??
                    todayStats?['display_idle_duration']?.toString() ??
                    val.idleDuration,
                stoppedDuration:
                    todayStats?['stopped_duration']?.toString() ??
                    todayStats?['display_stopped_duration']?.toString() ??
                    val.stoppedDuration,
                inactiveDuration:
                    todayStats?['inactive_duration']?.toString() ??
                    todayStats?['display_inactive_duration']?.toString() ??
                    val.inactiveDuration,
                avgSpeedKmph:
                    todayStats?['avg_speed']?.toString() ??
                    todayStats?['average_speed']?.toString() ??
                    val.avgSpeedKmph,
                maxSpeedKmph:
                    todayStats?['max_speed']?.toString() ??
                    todayStats?['top_speed']?.toString() ??
                    val.maxSpeedKmph,
                todayOdoKm:
                    todayStats?['total_kilometers_today']?.toString() ??
                    val.todayOdoKm,
                sensors: dynSensors,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading vehicle live snapshot: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load live track update by IMEI (GET /live_track)
  Future<void> loadLiveTrack(String imei) async {
    if (imei.isEmpty) return;
    try {
      final response = await DioClient().get(
        ApiEndPoints.liveTrack,
        queryParameters: {'imei': imei},
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        if (data is Map) {
          liveTrackData.value = Map<String, dynamic>.from(data);
          final pos = data['current_position'] ?? data['position'] ?? data;
          if (pos is Map) {
            final rawOdo =
                pos['odometer'] ??
                pos['total_kilometers_traveled'] ??
                data['vehicle_info']?['odometer'] ??
                data['vehicle_info']?['total_kilometers_traveled'];
            final digits = _extractOdometerDigits(rawOdo);
            if (digits != '0000000') {
              vehicleDetail.update((val) {
                if (val != null) {
                  vehicleDetail.value = val.copyWith(
                    odometerDigits: _keepOdometerUp(digits, val.odometerDigits),
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching live track: $e');
    }
  }

  /// Update vehicle odometer reading (POST /update_odometer)
  Future<bool> updateOdometer(String imei, double odometer) async {
    try {
      isLoading.value = true;
      final response = await DioClient().post(
        ApiEndPoints.updateOdometer,
        body: {'imei': imei, 'odometer': odometer},
      );

      if (response.data != null && response.data['status'] == true) {
        AppToast.show(
          response.data['message']?.toString() ?? 'Odometer updated',
        );
        vehicleDetail.update((val) {
          if (val != null) {
            vehicleDetail.value = VehicleDetailData(
              vehicleNumber: val.vehicleNumber,
              odometerDigits: odometer.toInt().toString().padLeft(7, '0'),
              timestamp: val.timestamp,
              distanceKm: val.distanceKm,
              speedKmph: val.speedKmph,
              coordinates: val.coordinates,
              latitude: val.latitude,
              longitude: val.longitude,
              address: val.address,
              deviceTime: val.deviceTime,
              serverTime: val.serverTime,
              runningDuration: val.runningDuration,
              idleDuration: val.idleDuration,
              stoppedDuration: val.stoppedDuration,
              inactiveDuration: val.inactiveDuration,
              avgSpeedKmph: val.avgSpeedKmph,
              maxSpeedKmph: val.maxSpeedKmph,
              todayOdoKm: val.todayOdoKm,
              sensors: val.sensors,
            );
          }
        });
        return true;
      } else {
        final msg =
            response.data?['message']?.toString() ??
            'Failed to update odometer';
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

  /// Load vehicle history coordinates for route playback (GET /track_vehicle)
  Future<void> loadVehicleHistory({
    String? imei,
    String? fromDate,
    String? toDate,
    bool userInitiated = false,
  }) async {
    // A background refresh (Home list) must not interrupt a load the user is
    // waiting for; that load already fetches the same date range.
    if (!userInitiated && (isHistoryLoading.value || _snapInProgress)) return;

    String targetImei = (imei != null && imei.isNotEmpty) ? imei : activeImei;
    if (targetImei.isEmpty) {
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        if (home.vehicles.isNotEmpty) {
          final dashCtrl = Get.isRegistered<DashboardController>()
              ? Get.find<DashboardController>()
              : null;
          final idx =
              (dashCtrl != null &&
                  dashCtrl.selectedVehicleIndex.value < home.vehicles.length)
              ? dashCtrl.selectedVehicleIndex.value
              : 0;
          targetImei = home.vehicles[idx].deviceId;
          activeImei = targetImei;
        }
      }
    }
    if (targetImei.isEmpty) return;

    final fDate = fromDate ?? startDateStr.value;
    final tDate = toDate ?? endDateStr.value;

    final int requestId = ++_historyRequestSeq;
    if (userInitiated) {
      // New date range: stop the car and remove the old route right away so
      // the previous day's line is never shown or played meanwhile.
      stopMovingMarker();
      isHistoryLoading.value = true;
      historyPoints.clear();
      historyTrips.clear();
      _snappedRoute = [];
      _snappedIdx = [];
      traveledRoutePoints.clear();
      historyTapIndex.value = -1;
      historyTapPoint.value = null;
      _playbackRoutePoints = [];
      movingMarkerPosition.value = null;
      playbackProgress.value = 0.0;
    }

    try {
      isLoading.value = true;
      final response = await DioClient().get(
        ApiEndPoints.vehicleHistory,
        queryParameters: {
          'imei': targetImei,
          'from_date': fDate,
          'to_date': tDate,
          'page': '1',
        },
      );

      // A newer request was started meanwhile: ignore this older result.
      if (requestId != _historyRequestSeq) return;

      if (response.data != null) {
        final resData = response.data['data'] ?? response.data;
        if (resData is Map) {
          historyResponseData.value = Map<String, dynamic>.from(resData);
        } else {
          historyResponseData.clear();
        }

        List<dynamic> raw = [];
        List<dynamic> rawTrips = [];
        if (resData is List) {
          raw = resData;
        } else if (resData is Map) {
          if (resData['trips'] is List) {
            rawTrips = resData['trips'];
          } else if (resData['trip_reports'] is List) {
            rawTrips = resData['trip_reports'];
          }

          if (resData['location_history'] is List) {
            raw = resData['location_history'];
          } else if (resData['history'] is List) {
            raw = resData['history'];
          } else if (resData['locations'] is List) {
            raw = resData['locations'];
          } else if (resData['track'] is List) {
            raw = resData['track'];
          } else if (resData['track_vehicle'] is List) {
            raw = resData['track_vehicle'];
          } else if (resData['points'] is List) {
            raw = resData['points'];
          } else if (resData['route'] is List) {
            raw = resData['route'];
          } else if (resData['items'] is List) {
            raw = resData['items'];
          } else if (resData['data'] is List) {
            raw = resData['data'];
          } else if (resData['list'] is List) {
            raw = resData['list'];
          }
        }

        historyPoints.value = raw
            .whereType<Map>()
            .map((j) => Map<String, dynamic>.from(j))
            .toList();

        _populateHistoryTrips(rawTrips);
        // Background refresh with no new points: nothing to redo (re-building
        // the route used to restart playback from the start).
        if (!userInitiated &&
            _snappedRoute.isNotEmpty &&
            _snappedSig == _historySig()) {
          return;
        }
        // The loader stays until the WHOLE route is on the road; only then
        // is the line drawn and Play enabled (no raw GPS line is shown).
        _snapInProgress = true;
        try {
          await _snapHistoryToRoads(requestId);
        } finally {
          if (requestId == _historyRequestSeq) _snapInProgress = false;
        }
        if (requestId != _historyRequestSeq) return;
        initPlaybackRoute();
      }
    } catch (e) {
      debugPrint('Error loading vehicle history: $e');
    } finally {
      isLoading.value = false;
      if (requestId == _historyRequestSeq) {
        isHistoryLoading.value = false;
      }
    }
  }

  List<Map<String, dynamic>> get dynamicHistoryTrips {
    if (historyTrips.isNotEmpty) return historyTrips;
    if (historyPoints.isEmpty) return [];
    return _generateTripsFromPoints();
  }

  void _populateHistoryTrips(List<dynamic> rawTrips) {
    if (rawTrips.isNotEmpty) {
      final list = <Map<String, dynamic>>[];
      for (int i = 0; i < rawTrips.length; i++) {
        final item = rawTrips[i];
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final dist =
              m['distance'] ??
              m['trip_distance'] ??
              m['distance_km'] ??
              '0.00 Km';
          final spd =
              m['max_speed'] ?? m['speed'] ?? m['top_speed'] ?? '0.0 Kmph';
          final start =
              m['startTime'] ??
              m['start_time'] ??
              m['from_time'] ??
              m['created_at'] ??
              '-';
          final end =
              m['endTime'] ??
              m['end_time'] ??
              m['to_time'] ??
              m['updated_at'] ??
              '-';
          final dur =
              m['duration'] ??
              m['trip_duration'] ??
              m['time_duration'] ??
              _calculateDurationString(start.toString(), end.toString());
          list.add({
            'badge': m['badge']?.toString() ?? 'Trip ${i + 1}',
            'distance': dist.toString().toLowerCase().contains('km')
                ? dist.toString()
                : '$dist Km',
            'maxSpeed': spd.toString().toLowerCase().contains('km')
                ? spd.toString()
                : '$spd Kmph',
            'startTime': formatDisplayTime(start.toString()),
            'duration': dur.toString(),
            'endTime': formatDisplayTime(end.toString()),
          });
        }
      }
      historyTrips.value = list;
    } else {
      historyTrips.value = _generateTripsFromPoints();
    }
  }

  // Trip detection thresholds.
  static const double _tripMovingSpeedKmh = 3.0; // reported speed = moving
  static const double _tripMovingJumpMeters =
      100.0; // or position moved this far
  static const int _tripStopSeconds = 300; // stationary this long ends a trip
  static const int _tripGapSeconds = 900; // no data this long ends a trip
  static const double _tripMinKm = 0.1; // ignore trips shorter than this

  LatLng? _pointLatLng(Map<String, dynamic> pt) {
    final la = double.tryParse(
      pt['latitude']?.toString() ?? pt['lat']?.toString() ?? '',
    );
    final ln = double.tryParse(
      pt['longitude']?.toString() ?? pt['lng']?.toString() ?? '',
    );
    if (la == null || ln == null || (la == 0 && ln == 0)) return null;
    return LatLng(la, ln);
  }

  /// Builds trips from the history points. A trip is a stretch where the
  /// vehicle is actually moving; parked periods (e.g. overnight pings every
  /// 5 minutes at 0 km/h) are gaps between trips, not trips themselves.
  List<Map<String, dynamic>> _generateTripsFromPoints() {
    if (historyPoints.length < 2) return [];

    final trips = <Map<String, dynamic>>[];
    var current = <Map<String, dynamic>>[];
    int lastMovingIdx = -1; // index in [current] of the last moving point
    DateTime? lastMoveTime;
    Map<String, dynamic>? prev;

    void finishTrip() {
      if (current.length >= 2 && lastMovingIdx >= 0) {
        // Keep the trip up to the first stationary point after the last
        // movement (that is where the vehicle stopped).
        final endIdx = math.min(lastMovingIdx + 1, current.length - 1);
        final pts = current.sublist(0, endIdx + 1);
        final summary = _buildTripSummaryMap(pts, tripIndex: trips.length + 1);
        final km =
            double.tryParse(
              summary['distance']?.toString().split(' ').first ?? '',
            ) ??
            0.0;
        final maxSpd =
            double.tryParse(
              summary['maxSpeed']?.toString().split(' ').first ?? '',
            ) ??
            0.0;
        if (km >= _tripMinKm || maxSpd >= _tripMovingSpeedKmh) {
          summary['badge'] = 'Trip ${trips.length + 1}';
          trips.add(summary);
        }
      }
      current = <Map<String, dynamic>>[];
      lastMovingIdx = -1;
      lastMoveTime = null;
    }

    for (final pt in historyPoints) {
      final t = _parseTimestamp(_pointTime(pt));
      final speed = double.tryParse(pt['speed']?.toString() ?? '') ?? 0.0;
      final here = _pointLatLng(pt);
      final before = prev == null ? null : _pointLatLng(prev);
      final movedM = (here != null && before != null)
          ? _distanceMeters(before, here)
          : 0.0;
      final prevT = prev == null ? null : _parseTimestamp(_pointTime(prev));

      // Long data gap inside a trip ends it.
      if (current.isNotEmpty &&
          t != null &&
          prevT != null &&
          t.difference(prevT).inSeconds.abs() >= _tripGapSeconds) {
        finishTrip();
      }

      final isMoving =
          speed >= _tripMovingSpeedKmh || movedM >= _tripMovingJumpMeters;

      if (isMoving) {
        if (current.isEmpty && prev != null) {
          current.add(prev); // trip starts where the vehicle was standing
        }
        current.add(pt);
        lastMovingIdx = current.length - 1;
        lastMoveTime = t ?? lastMoveTime;
      } else if (current.isNotEmpty) {
        current.add(pt);
        if (t != null &&
            lastMoveTime != null &&
            t.difference(lastMoveTime!).inSeconds >= _tripStopSeconds) {
          finishTrip();
        }
      }
      prev = pt;
    }
    finishTrip();

    if (trips.length == 1) {
      trips[0]['badge'] = 'Trip';
    }
    return trips;
  }

  Map<String, dynamic> _buildTripSummaryMap(
    List<Map<String, dynamic>> pts, {
    required int tripIndex,
  }) {
    if (pts.isEmpty) return {};

    final first = pts.first;
    final last = pts.last;

    final rawStart = _pointTime(first) ?? '-';
    final rawEnd = _pointTime(last) ?? '-';

    final startDt = _parseTimestamp(rawStart);
    final endDt = _parseTimestamp(rawEnd);

    String durationStr = '00h 00m';
    if (startDt != null && endDt != null) {
      final diff = endDt.difference(startDt);
      durationStr = _formatDuration(diff);
    }

    double distKm = 0.0;
    double maxSpeedKmph = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final s = double.tryParse(pts[i]['speed']?.toString() ?? '') ?? 0.0;
      if (s > maxSpeedKmph) maxSpeedKmph = s;

      if (i < pts.length - 1) {
        final lat1 = double.tryParse(
          pts[i]['latitude']?.toString() ?? pts[i]['lat']?.toString() ?? '',
        );
        final lon1 = double.tryParse(
          pts[i]['longitude']?.toString() ?? pts[i]['lng']?.toString() ?? '',
        );
        final lat2 = double.tryParse(
          pts[i + 1]['latitude']?.toString() ??
              pts[i + 1]['lat']?.toString() ??
              '',
        );
        final lon2 = double.tryParse(
          pts[i + 1]['longitude']?.toString() ??
              pts[i + 1]['lng']?.toString() ??
              '',
        );
        if (lat1 != null &&
            lon1 != null &&
            lat2 != null &&
            lon2 != null &&
            (lat1 != 0 || lon1 != 0) &&
            (lat2 != 0 || lon2 != 0)) {
          distKm += _distanceKm(LatLng(lat1, lon1), LatLng(lat2, lon2));
        }
      }
    }

    final firstDist = double.tryParse(first['distance']?.toString() ?? '');
    final lastDist = double.tryParse(last['distance']?.toString() ?? '');
    if (firstDist != null && lastDist != null && lastDist > firstDist) {
      distKm = lastDist - firstDist;
    }

    return {
      'badge': 'Trip $tripIndex',
      'distance': '${distKm.toStringAsFixed(2)} Km',
      'maxSpeed': '${maxSpeedKmph.toStringAsFixed(1)} Kmph',
      'startTime': formatDisplayTime(rawStart.toString()),
      'duration': durationStr,
      'endTime': formatDisplayTime(rawEnd.toString()),
    };
  }

  String _calculateDurationString(String startStr, String endStr) {
    final sDt = _parseTimestamp(startStr);
    final eDt = _parseTimestamp(endStr);
    if (sDt != null && eDt != null) {
      return _formatDuration(eDt.difference(sDt));
    }
    return '00h 00m';
  }

  /// Load vehicle statistics from API (GET /statistics)
  Future<void> loadStatistics({
    String? imei,
    String? fromDate,
    String? toDate,
    String? period,
  }) async {
    final targetImei = (imei != null && imei.isNotEmpty) ? imei : activeImei;
    if (targetImei.isEmpty) return;

    final fDate = (fromDate != null && fromDate.isNotEmpty)
        ? fromDate
        : startDateStr.value;
    final tDate = (toDate != null && toDate.isNotEmpty)
        ? toDate
        : endDateStr.value;

    final queryParams = <String, dynamic>{
      'imei': targetImei,
      'from_date': fDate,
      'to_date': tDate,
    };

    if (period != null &&
        period.isNotEmpty &&
        period.toLowerCase() != 'custom') {
      queryParams['period'] = period;
    }

    try {
      isStatisticsLoading.value = true;
      var response = await DioClient().get(
        ApiEndPoints.statistics,
        queryParameters: queryParams,
      );

      // If 422 or status false occurs due to period parameter, retry without period parameter
      if ((response.statusCode == 422 ||
              (response.data is Map && response.data['status'] == false)) &&
          queryParams.containsKey('period')) {
        queryParams.remove('period');
        response = await DioClient().get(
          ApiEndPoints.statistics,
          queryParameters: queryParams,
        );
      }

      if (response.data != null && response.data['data'] != null) {
        _parseAndSetStatisticsData(response.data['data']);
      }
    } catch (e) {
      debugPrint('Error loading vehicle statistics: $e');
    } finally {
      isStatisticsLoading.value = false;
    }
  }

  void _parseAndSetStatisticsData(dynamic data) {
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);

    final routeLen =
        map['route_length']?.toString() ??
        map['route_distance']?.toString() ??
        map['distance']?.toString() ??
        map['total_distance']?.toString() ??
        '0 km';

    final moveDur =
        map['move_duration']?.toString() ??
        map['moving_duration']?.toString() ??
        map['moving_time']?.toString() ??
        '00:00:00';

    final idleDur =
        map['idle_duration']?.toString() ??
        map['idling_duration']?.toString() ??
        map['idle_time']?.toString() ??
        '00:00:00';

    final stopDur =
        map['stop_duration']?.toString() ??
        map['stopped_duration']?.toString() ??
        map['stop_time']?.toString() ??
        '00:00:00';

    final stopCnt =
        map['stop_count']?.toString() ??
        map['stops']?.toString() ??
        map['stopped_count']?.toString() ??
        '0';

    final avgSpd =
        map['average_speed']?.toString() ??
        map['avg_speed']?.toString() ??
        '0 kmph';

    final topSpd =
        map['top_speed']?.toString() ??
        map['max_speed']?.toString() ??
        '0 kmph';

    final overSpdCnt =
        map['over_speed_count']?.toString() ??
        map['overspeed_count']?.toString() ??
        map['overspeed_events']?.toString() ??
        '0';

    final engHrs =
        map['engine_hours']?.toString() ??
        map['engine_duration']?.toString() ??
        map['engine_on_time']?.toString() ??
        '00:00:00';

    final odo =
        map['odometer']?.toString() ??
        map['odo']?.toString() ??
        map['today_odo']?.toString() ??
        map['total_distance']?.toString() ??
        '0 km';

    statisticsData.value = {
      'Route Length': routeLen.contains('km') ? routeLen : '$routeLen km',
      'Move Duration': moveDur,
      'Idle Duration': idleDur,
      'Stop Duration': stopDur,
      'Stop Count': stopCnt,
      'Average Speed': avgSpd.contains('kmph') ? avgSpd : '$avgSpd kmph',
      'Top Speed': topSpd.contains('kmph') ? topSpd : '$topSpd kmph',
      'Over Speed Count': overSpdCnt,
      'Engine Hours': engHrs,
      'Odometer': odo.contains('km') ? odo : '$odo km',
    };

    // Statistics are for the selected date range, so they no longer write
    // the live odometer / Today Odo (that caused sudden jumps, e.g. 320).
  }

  @override
  void onClose() {
    _liveDisposed = true;
    stopMovingMarker();
    stopLiveTracking();
    super.onClose();
  }

  void selectTab(int index) {
    selectedTopTab.value = index;
    if (index != 0) {
      stopMovingMarker();
    }
    if (index != -1) {
      stopLiveTracking();
    }

    // Trigger API calls when tab changes
    if (index == 0) {
      // History Tab
      loadVehicleHistory(userInitiated: true);
    } else if (index == 1) {
      // Alerts Tab
      if (Get.isRegistered<AlertsController>()) {
        Get.find<AlertsController>().loadAlerts();
      } else {
        Get.put(AlertsController()).loadAlerts();
      }
    } else if (index == 2) {
      // Statistics Tab
      if (activeImei.isNotEmpty) {
        loadStatistics(imei: activeImei);
      }
    } else if (index == -1) {
      if (activeImei.isNotEmpty) {
        startLiveTracking(activeImei);
        _refreshTodayStats();
      }
    }
  }

  // The tap on the dialog's X can also reach the map underneath (web),
  // whose tap toggled the dialog straight back open. Taps on the map right
  // after closing are ignored.
  DateTime _mapDialogClosedAt = DateTime.fromMillisecondsSinceEpoch(0);

  void toggleMapDialog() {
    if (!isMapDialogVisible.value &&
        DateTime.now().difference(_mapDialogClosedAt).inMilliseconds < 400) {
      return;
    }
    isMapDialogVisible.value = !isMapDialogVisible.value;
    if (!isMapDialogVisible.value) _mapDialogClosedAt = DateTime.now();
  }

  void hideMapDialog() {
    isMapDialogVisible.value = false;
    _mapDialogClosedAt = DateTime.now();
  }

  void showMapDialog() {
    isMapDialogVisible.value = true;
  }

  void toggleHistoryMapDialog() {
    isHistoryMapDialogVisible.value = !isHistoryMapDialogVisible.value;
  }

  void hideHistoryMapDialog() {
    isHistoryMapDialogVisible.value = false;
    _tappedStopDuration = null;
    historyTapIndex.value = -1;
    historyTapPoint.value = null;
  }

  bool get _snappedReady => _snappedRoute.isNotEmpty;

  /// Copy of the drawn route for the car, remembering whether it is the
  /// road route (so the car can switch when a newer road route is ready).
  List<LatLng> _takeActiveRoute() {
    _playbackSnapVersion = _snappedReady ? _snappedVersion : -1;
    _playbackIdx = List<int>.from(_activeRouteSourceIndex());
    return List<LatLng>.from(getActiveRoutePoints());
  }

  List<int> _playbackIdx = const [];

  List<LatLng> getActiveRoutePoints() {
    historyRouteVersion.value; // redraw the map when the road route updates
    // Only the road route is drawn. While it is being built nothing is
    // drawn (the loader is shown); raw GPS is used only if building failed.
    if (_snappedRoute.isNotEmpty) return _snappedRoute;
    if (_snapInProgress) return const [];
    return _rawRoute().$1;
  }

  // ---------------------------------------------------------------------
  // History route snapped to the road
  // ---------------------------------------------------------------------
  List<LatLng> _snappedRoute = [];
  bool _snapInProgress = false;
  // Changes whenever the drawn route changes, so the map redraws.
  final RxInt historyRouteVersion = 0.obs;
  int _snappedVersion = 0; // bumped each time a new road route is ready
  int _playbackSnapVersion = -1; // road route the car is driving on (-1: GPS)
  List<int> _snappedIdx = [];
  String _snappedSig = '';

  String _historySig() {
    if (historyPoints.isEmpty) return '';
    final f = _pointLatLng(historyPoints.first);
    final l = _pointLatLng(historyPoints.last);
    return '${historyPoints.length}|$f|$l';
  }

  /// Valid GPS points of the history and, for each, its index in
  /// [historyPoints].
  (List<LatLng>, List<int>) _rawRoute() {
    final pts = <LatLng>[];
    final idx = <int>[];
    for (int i = 0; i < historyPoints.length; i++) {
      final ll = _pointLatLng(historyPoints[i]);
      if (ll != null) {
        pts.add(ll);
        idx.add(i);
      }
    }
    return (pts, idx);
  }

  List<int> _activeRouteSourceIndex() {
    if (_snappedRoute.isNotEmpty) {
      return _snappedIdx;
    }
    return _rawRoute().$2;
  }

  // History road route.
  // DirectionsService (used by live tracking) asks Google Directions first,
  // which a browser cannot call (no CORS), then the free OSRM server. That
  // is fine for live tracking (one short hop every few seconds) but a full
  // day is ~1500 hops: the free server refuses most of them ("too many
  // requests") and those hops stay straight. So history sends the points
  // in batches of 60 to the same OSRM server (one request per batch, one
  // request per second, retried when refused): ~25 requests for a day.
  static const String _osrmBase = 'https://router.project-osrm.org';
  final Map<String, (List<LatLng>, List<int>)> _roadRouteCache = {};
  dio_pkg.Dio? _osrmDio;
  DateTime _lastOsrmCall = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _snapHistoryToRoads(int requestId) async {
    final raw = _rawRoute();
    final allPts = raw.$1;
    final allSrc = raw.$2;
    if (allPts.length < 2) {
      _snappedRoute = [];
      _snappedIdx = [];
      _snappedSig = '';
      return;
    }

    // Drop parked repeats / duplicates and points whose time goes backwards.
    final pts = <LatLng>[];
    final src = <int>[];
    final ts = <int?>[];
    int? lastT;
    for (int i = 0; i < allPts.length; i++) {
      final dt = _parseTimestamp(_pointTime(historyPoints[allSrc[i]]));
      final t = dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
      if (pts.isNotEmpty) {
        if (_distanceMeters(pts.last, allPts[i]) < 5) continue;
        if (t != null && lastT != null && t <= lastT) continue;
      }
      pts.add(allPts[i]);
      src.add(allSrc[i]);
      ts.add(t);
      if (t != null) lastT = t;
    }
    if (pts.length < 2) return;
    final hasTimes = ts.every((t) => t != null);

    // Same vehicle + same points as before (e.g. reopening the tab):
    // reuse the finished road route, no requests at all.
    final cacheKey =
        '$activeImei|${startDateStr.value}|${endDateStr.value}|${_historySig()}';
    final cached = _roadRouteCache[cacheKey];
    if (cached != null) {
      _publishRoute(cached.$1, cached.$2, pts, src, pts.length);
      return;
    }

    // Batches of 100 points (Google's limit), sharing one point each.
    final batches = <(int, int)>[];
    for (
      int st = 0;
      st < pts.length - 1;
      st = math.min(st + 99, pts.length - 1)
    ) {
      batches.add((st, math.min(st + 100, pts.length)));
    }
    final parts = List<(List<LatLng>, List<int>)?>.filled(batches.length, null);

    // 1) Google Roads for all batches at the same time (Google has no
    //    one-request-per-second limit), 6 requests in parallel.
    int next = 0;
    Future<void> gWorker() async {
      while (next < batches.length) {
        if (requestId != _historyRequestSeq) return;
        final k = next++;
        final (st, en) = batches[k];
        parts[k] = await _googleSnap(pts.sublist(st, en), src.sublist(st, en));
      }
    }

    await Future.wait(List.generate(6, (_) => gWorker()));
    if (requestId != _historyRequestSeq) return;

    // 2) Batches Google could not do: free road server (one per second).
    int onRoad = 0, left = 0;
    for (int k = 0; k < batches.length; k++) {
      if (parts[k] != null) {
        onRoad++;
        continue;
      }
      final (st, en) = batches[k];
      final cp = pts.sublist(st, en);
      final cs = src.sublist(st, en);
      final ct = hasTimes ? ts.sublist(st, en).cast<int>() : null;
      parts[k] =
          await _osrmMatch(cp, cs, ct, requestId) ??
          await _osrmRouteVia(cp, cs, requestId);
      if (requestId != _historyRequestSeq) return;
      if (parts[k] != null) {
        onRoad++;
      } else {
        left++;
        parts[k] = (cp, cs);
      }
    }

    // 3) Join the batches into one line.
    var out = <LatLng>[];
    var outIdx = <int>[];
    for (final part in parts) {
      for (int k = 0; k < part!.$1.length; k++) {
        if (out.isNotEmpty && _distanceMeters(out.last, part.$1[k]) < 0.6) {
          continue;
        }
        out.add(part.$1[k]);
        final si = part.$2[k];
        outIdx.add(outIdx.isNotEmpty && si < outIdx.last ? outIdx.last : si);
      }
    }

    // 4) All remaining straight pieces of the whole day by road, many per
    //    request (a handful of requests instead of one per batch).
    final filled = await _fillGaps(out, outIdx, requestId);
    if (requestId != _historyRequestSeq) return;
    out = filled.$1;
    outIdx = filled.$2;
    _roadRouteCache[cacheKey] = (out, outIdx);
    _publishRoute(out, outIdx, pts, src, pts.length);
    debugPrint('[History] Road route: $onRoad batch(es) on road, $left left');
  }

  /// One OSRM request, max one per second, retried when refused (429) or
  /// not answered. Returns the decoded JSON, or null.
  Future<Map?> _osrmGet(String path, Map<String, dynamic> q, int reqId) async {
    _osrmDio ??= dio_pkg.Dio(
      dio_pkg.BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (_) => true,
      ),
    );
    for (int attempt = 0; attempt < 3; attempt++) {
      if (reqId != _historyRequestSeq) return null;
      final wait = _lastOsrmCall
          .add(const Duration(milliseconds: 1100))
          .difference(DateTime.now());
      if (!wait.isNegative) await Future.delayed(wait);
      _lastOsrmCall = DateTime.now();
      try {
        final res = await _osrmDio!.get('$_osrmBase$path', queryParameters: q);
        final data = res.data is String
            ? jsonDecode(res.data as String)
            : res.data;
        if (res.statusCode == 200 && data is Map) return data;
        if (data is Map && data['code'] != null && res.statusCode != 429) {
          return data; // e.g. NoMatch: a real answer, do not retry
        }
        debugPrint('[History] Road server busy (${res.statusCode}), retrying');
      } catch (e) {
        debugPrint('[History] Road server not answering, retrying: $e');
      }
      if (attempt < 2)
        await Future.delayed(Duration(seconds: 1 + attempt)); // 1,2 s
    }
    return null;
  }

  String _coords(List<LatLng> cp) => cp
      .map(
        (p) =>
            '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}',
      )
      .join(';');

  /// Google Roads snap-to-roads (works from the browser): puts the points on
  /// Google's roads - the same roads the Google map shows - and adds road
  /// points between them. Null when Google refuses (key / API not enabled).
  Future<(List<LatLng>, List<int>)?> _googleSnap(
    List<LatLng> cp,
    List<int> cs,
  ) async {
    final key = ApiConfig.googleMapKey;
    if (key.isEmpty || !_googleRoadsOk) return null;
    try {
      _osrmDio ??= dio_pkg.Dio(
        dio_pkg.BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      final res = await _osrmDio!.get(
        'https://roads.googleapis.com/v1/snapToRoads',
        queryParameters: {
          'path': cp
              .map(
                (p) =>
                    '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}',
              )
              .join('|'),
          'interpolate': 'true',
          'key': key,
        },
      );
      final data = res.data is String
          ? jsonDecode(res.data as String)
          : res.data;
      if (res.statusCode != 200 || data is! Map) {
        debugPrint('[History] Google Roads refused (${res.statusCode}): $data');
        // 403 = key / Roads API not allowed. A 400 is only this one bad
        // request: it must not switch Google off for the whole session.
        if (res.statusCode == 403) {
          _googleRoadsOk = false; // key not allowed: use OSRM from now on
        }
        return null;
      }
      final sp = (data['snappedPoints'] as List?) ?? const [];
      final out = <LatLng>[];
      final idx = <int>[];
      int last = cs.first;
      for (final p in sp) {
        if (p is! Map || p['location'] is! Map) continue;
        final loc = p['location'] as Map;
        final oi = p['originalIndex'];
        if (oi is num && oi.toInt() < cs.length) last = cs[oi.toInt()];
        out.add(
          LatLng(
            (loc['latitude'] as num).toDouble(),
            (loc['longitude'] as num).toDouble(),
          ),
        );
        idx.add(last);
      }
      return out.length >= 2 ? (out, idx) : null;
    } catch (e) {
      debugPrint('[History] Google Roads failed: $e');
      return null;
    }
  }

  bool _googleRoadsOk = true;

  /// Any straight piece longer than [_gapM] left in the route (points far
  /// apart at speed) is replaced by the road between its ends. All gaps of
  /// a batch go in ONE road request (waypoints A1,B1,A2,B2,...; the legs
  /// A->B are the gaps, the legs B->A in between are ignored).
  static const double _gapM = 90;

  Future<(List<LatLng>, List<int>)> _fillGaps(
    List<LatLng> pts,
    List<int> idx,
    int reqId,
  ) async {
    final gaps = <int>[];
    for (int i = 0; i < pts.length - 1; i++) {
      if (_distanceMeters(pts[i], pts[i + 1]) > _gapM) gaps.add(i);
    }
    if (gaps.isEmpty) return (pts, idx);
    final fills = <int, List<LatLng>>{};
    for (int g0 = 0; g0 < gaps.length; g0 += 80) {
      final group = gaps.sublist(g0, math.min(g0 + 80, gaps.length));
      final wps = <LatLng>[];
      for (final i in group) {
        wps
          ..add(pts[i])
          ..add(pts[i + 1]);
      }
      final data = await _osrmGet('/route/v1/driving/${_coords(wps)}', {
        'overview': 'false',
        'steps': 'true',
        'geometries': 'geojson',
      }, reqId);
      if (data == null || data['code'] != 'Ok') continue;
      final routes = (data['routes'] as List?) ?? const [];
      if (routes.isEmpty || routes.first is! Map) continue;
      final legs = ((routes.first as Map)['legs'] as List?) ?? const [];
      for (int k = 0; k < group.length; k++) {
        final li = k * 2;
        if (li >= legs.length || legs[li] is! Map) continue;
        final leg = legs[li] as Map;
        final i = group[k];
        final straight = _distanceMeters(pts[i], pts[i + 1]);
        final legDist = (leg['distance'] as num?)?.toDouble() ?? 0;
        if (legDist > straight * 2.0 + 120) continue; // loop / wrong way
        final road = <LatLng>[];
        for (final st in (leg['steps'] as List?) ?? const []) {
          final g = st is Map ? st['geometry'] : null;
          final cl = g is Map ? (g['coordinates'] as List?) : null;
          for (final c in cl ?? const []) {
            if (c is List && c.length >= 2) {
              road.add(
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              );
            }
          }
        }
        if (road.length >= 2) fills[i] = road;
      }
    }
    final out = <LatLng>[];
    final oi = <int>[];
    for (int i = 0; i < pts.length; i++) {
      out.add(pts[i]);
      oi.add(idx[i]);
      final f = fills[i];
      if (f != null) {
        out.addAll(f);
        oi.addAll(List.filled(f.length, idx[i]));
      }
    }
    return (out, oi);
  }

  /// OSRM map matching: puts every point on the road it was driven on and
  /// follows the road between them, in the driving direction.
  Future<(List<LatLng>, List<int>)?> _osrmMatch(
    List<LatLng> cp,
    List<int> cs,
    List<int>? ct,
    int reqId,
  ) async {
    final data = await _osrmGet('/match/v1/driving/${_coords(cp)}', {
      'geometries': 'geojson',
      'overview': 'false',
      'steps': 'true',
      'gaps': 'ignore',
      'tidy': 'true',
      'radiuses': List.filled(cp.length, '50').join(';'),
      if (ct != null) 'timestamps': ct.join(';'),
    }, reqId);
    if (data == null || data['code'] != 'Ok') return null;
    final tps = (data['tracepoints'] as List?) ?? const [];
    final matchings = (data['matchings'] as List?) ?? const [];

    final out = <LatLng>[];
    final idx = <int>[];
    Map? prev;
    int prevSrc = cs.first;
    for (int i = 0; i < tps.length && i < cp.length; i++) {
      final tp = tps[i];
      if (tp is! Map || tp['location'] is! List) continue; // outlier point
      final loc = tp['location'] as List;
      final here = LatLng(
        (loc[1] as num).toDouble(),
        (loc[0] as num).toDouble(),
      );
      if (prev != null && prev['matchings_index'] == tp['matchings_index']) {
        final mi = (tp['matchings_index'] as num).toInt();
        final li = (prev['waypoint_index'] as num).toInt();
        final legs = mi < matchings.length
            ? ((matchings[mi]['legs'] as List?) ?? const [])
            : const [];
        if (li < legs.length && legs[li] is Map) {
          final leg = legs[li] as Map;
          final legDist = (leg['distance'] as num?)?.toDouble() ?? 0;
          final straight = out.isEmpty ? 0.0 : _distanceMeters(out.last, here);
          // Skip a leg that loops away (wrong-way / U-turn detour).
          if (legDist <= straight * 1.8 + 100) {
            for (final st in (leg['steps'] as List?) ?? const []) {
              final g = st is Map ? st['geometry'] : null;
              final cl = g is Map ? (g['coordinates'] as List?) : null;
              for (final c in cl ?? const []) {
                if (c is List && c.length >= 2) {
                  out.add(
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
                  );
                  idx.add(prevSrc);
                }
              }
            }
          }
        }
      }
      out.add(here);
      idx.add(cs[i]);
      prev = tp;
      prevSrc = cs[i];
    }
    return out.length >= 2 ? (out, idx) : null;
  }

  /// Backup when matching fails: road route through the same points.
  Future<(List<LatLng>, List<int>)?> _osrmRouteVia(
    List<LatLng> cp,
    List<int> cs,
    int reqId,
  ) async {
    final data = await _osrmGet('/route/v1/driving/${_coords(cp)}', {
      'overview': 'false',
      'steps': 'true',
      'geometries': 'geojson',
    }, reqId);
    if (data == null || data['code'] != 'Ok') return null;
    final routes = (data['routes'] as List?) ?? const [];
    if (routes.isEmpty || routes.first is! Map) return null;
    final legs = ((routes.first as Map)['legs'] as List?) ?? const [];
    final out = <LatLng>[cp.first];
    final idx = <int>[cs.first];
    for (int li = 0; li < legs.length && li < cp.length - 1; li++) {
      final leg = legs[li];
      final straight = _distanceMeters(cp[li], cp[li + 1]);
      final legDist = leg is Map
          ? ((leg['distance'] as num?)?.toDouble() ?? 0)
          : 0.0;
      if (leg is Map && legDist <= straight * 1.8 + 100) {
        for (final st in (leg['steps'] as List?) ?? const []) {
          final g = st is Map ? st['geometry'] : null;
          final cl = g is Map ? (g['coordinates'] as List?) : null;
          for (final c in cl ?? const []) {
            if (c is List && c.length >= 2) {
              out.add(
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              );
              idx.add(cs[li]);
            }
          }
        }
      } else {
        out.add(cp[li + 1]);
        idx.add(cs[li + 1]);
      }
    }
    return out.length >= 2 ? (out, idx) : null;
  }

  void _publishRoute(
    List<LatLng> out,
    List<int> outIdx,
    List<LatLng> pts,
    List<int> src,
    int rawFrom,
  ) {
    final r = List<LatLng>.from(out);
    final ri = List<int>.from(outIdx);
    for (int k = rawFrom; k < pts.length; k++) {
      r.add(pts[k]);
      ri.add(ri.isNotEmpty && src[k] < ri.last ? ri.last : src[k]);
    }
    if (r.length < 2) return;
    _snappedRoute = r;
    _snappedIdx = ri;
    _snappedSig = _historySig();
    _snappedVersion++;
    // Car not started yet: keep it at the start of the new line.
    if (!isPlaying.value && playbackProgress.value == 0.0) {
      _playbackRoutePoints = _takeActiveRoute();
      movingMarkerPosition.value = r.first;
      traveledRoutePoints.assignAll([r.first]);
    }
    historyRouteVersion.value++;
  }

  void _buildPlaybackSpeedSeries() {
    _playbackSpeedSeries = historyPoints.map((pt) {
      final s = pt['speed'];
      return double.tryParse(s?.toString() ?? '') ?? 0.0;
    }).toList();
  }

  void fitHistoryRoute() {
    final route = getActiveRoutePoints();
    if (route.isEmpty) return;
    try {
      if (route.length == 1) {
        historyMapController.move(route.first, 14.0);
      } else {
        historyMapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(route),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } catch (e) {
      debugPrint('fitHistoryRoute error: $e');
    }
  }

  void zoomInHistoryMap() {
    try {
      historyMapController.move(
        historyMapController.camera.center,
        historyMapController.camera.zoom + 1,
      );
    } catch (_) {}
  }

  void zoomOutHistoryMap() {
    try {
      historyMapController.move(
        historyMapController.camera.center,
        historyMapController.camera.zoom - 1,
      );
    } catch (_) {}
  }

  void initPlaybackRoute() {
    _buildPlaybackSpeedSeries();

    // FIX: a Home list refresh re-fetches the same history. If playback is
    // running or paused mid-route and the new route is the same trip (same
    // start, old route is a prefix), keep the car where it is instead of
    // stopping it and sending it back to the start.
    final newPoints = getActiveRoutePoints();
    if (_canContinuePlayback(newPoints)) {
      _playbackRoutePoints = _takeActiveRoute();
      return;
    }
    // Playback running or paused mid-route: keep the car where it is on the
    // new line instead of restarting from the beginning.
    final inProgress =
        isPlaying.value ||
        (playbackProgress.value > 0.0 && playbackProgress.value < 1.0);
    if (inProgress && newPoints.length >= 2) {
      _playbackSnapVersion = -2; // force _followDrawnRoute to remap
      _followDrawnRoute();
      return;
    }

    placeMovingMarkerAtStart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedTopTab.value == 0) {
        fitHistoryRoute();
      }
    });
  }

  /// The car must always drive on the line that is drawn. If the road route
  /// became ready (or changed) after playback started, move the car onto it
  /// at the same share of the journey and continue from there.
  void _followDrawnRoute() {
    if (!_snappedReady || _playbackSnapVersion == _snappedVersion) return;
    // History point the car is at now.
    final oldIdx = _playbackIdx;
    final curSrc = (oldIdx.isNotEmpty)
        ? oldIdx[_movingSegmentIndex.clamp(0, oldIdx.length - 1)]
        : 0;
    final here = movingMarkerPosition.value;
    final route = _takeActiveRoute();
    _playbackRoutePoints = route;
    if (route.length < 2) return;
    // Same history point on the new route; nearest vertex among those.
    final idx = _playbackIdx;
    int i = 0;
    while (i < idx.length - 2 && idx[i + 1] < curSrc) {
      i++;
    }
    if (here != null) {
      int best = i;
      double bestD = double.infinity;
      for (int k = i; k < route.length - 1 && k < idx.length; k++) {
        if (idx[k] > curSrc + 1) break;
        final d = _distanceMeters(here, route[k]);
        if (d < bestD) {
          bestD = d;
          best = k;
        }
      }
      i = best.clamp(0, route.length - 2);
    }
    _movingSegmentIndex = i;
    _movingSegmentFraction = 0.0;
    traveledRoutePoints.assignAll([...route.sublist(0, i + 1)]);
  }

  bool _canContinuePlayback(List<LatLng> newPoints) {
    final old = _playbackRoutePoints;
    final inProgress =
        isPlaying.value ||
        (playbackProgress.value > 0.0 && playbackProgress.value < 1.0);
    if (!inProgress || old.length < 2 || newPoints.length < old.length) {
      return false;
    }
    bool same(LatLng a, LatLng b) =>
        (a.latitude - b.latitude).abs() < 1e-7 &&
        (a.longitude - b.longitude).abs() < 1e-7;
    return same(old.first, newPoints.first) &&
        same(old.last, newPoints[old.length - 1]);
  }

  void placeMovingMarkerAtStart() {
    stopMovingMarker();
    final points = _takeActiveRoute();
    _playbackRoutePoints = points;
    _movingSegmentIndex = 0;
    _movingSegmentFraction = 0.0;
    playbackProgress.value = 0.0;
    currentPlaybackSpeedKmph.value = 0.0;
    _lastCameraUpdateMs = 0;
    if (points.isEmpty) {
      movingMarkerPosition.value = null;
      movingMarkerBearing.value = null;
      traveledRoutePoints.clear();
    } else {
      movingMarkerPosition.value = points.first;
      movingMarkerBearing.value = points.length >= 2
          ? _getBearing(points[0], points[1])
          : 0.0;
      traveledRoutePoints.assignAll([points.first]);
    }
  }

  void togglePlay() {
    if (isPlaying.value) {
      stopMovingMarker();
    } else {
      startMovingMarker();
    }
  }

  void startMovingMarker() {
    // Do not play until the selected date range has fully loaded.
    if (isHistoryLoading.value) {
      AppToast.show('Loading history, please wait...');
      return;
    }
    historyTapIndex.value = -1;
    historyTapPoint.value = null;
    final points = getActiveRoutePoints();
    if (points.length < 2) {
      AppToast.showErrorMessage('No history route available for playback');
      return;
    }

    if (playbackProgress.value >= 1.0) {
      placeMovingMarkerAtStart();
    }

    _playbackRoutePoints = _takeActiveRoute();
    stopMovingMarker();

    if (movingMarkerPosition.value == null) {
      movingMarkerPosition.value = _playbackRoutePoints.first;
      movingMarkerBearing.value = _playbackRoutePoints.length > 1
          ? _getBearing(_playbackRoutePoints[0], _playbackRoutePoints[1])
          : 0.0;
      traveledRoutePoints.assignAll([_playbackRoutePoints.first]);
    }

    // Ensure vehicle position is visible when starting playback
    if (movingMarkerPosition.value != null) {
      try {
        final currentZoom = historyMapController.camera.zoom;
        historyMapController.move(
          movingMarkerPosition.value!,
          currentZoom < 12 ? 14.0 : currentZoom,
        );
      } catch (_) {}
    }

    isPlaying.value = true;
    _lastCameraUpdateMs = 0;
    _lastPlaybackTickAt = null;
    _movingMarkerTimer = Timer.periodic(_playbackFramePeriod, (_) {
      advanceFrame();
    });
  }

  void stopMovingMarker() {
    _movingMarkerTimer?.cancel();
    _movingMarkerTimer = null;
    isPlaying.value = false;
    currentPlaybackSpeedKmph.value = 0.0;
  }

  void replay() {
    seekToProgress(0.0);
    startMovingMarker();
  }

  void cyclePlaybackSpeed() {
    final current = playbackSpeedMultiplier.value;
    if (current < 1.25) {
      playbackSpeedMultiplier.value = 1.5;
      playbackSpeed.value = '1.5x';
    } else if (current < 1.75) {
      playbackSpeedMultiplier.value = 2.0;
      playbackSpeed.value = '2x';
    } else {
      playbackSpeedMultiplier.value = 1.0;
      playbackSpeed.value = '1x';
    }
  }

  void seekToProgress(double p) {
    final route = _playbackRoutePoints.isNotEmpty
        ? _playbackRoutePoints
        : getActiveRoutePoints();
    if (route.length < 2) return;

    final wasPlaying = isPlaying.value;
    stopMovingMarker();

    final clamped = p.clamp(0.0, 1.0);
    playbackProgress.value = clamped;

    if (clamped <= 0.0) {
      _movingSegmentIndex = 0;
      _movingSegmentFraction = 0.0;
      movingMarkerPosition.value = route.first;
      movingMarkerBearing.value = _getBearing(route[0], route[1]);
      traveledRoutePoints.assignAll([route.first]);
      try {
        historyMapController.move(
          route.first,
          historyMapController.camera.zoom,
        );
      } catch (_) {}
      if (wasPlaying) startMovingMarker();
      return;
    }
    if (clamped >= 1.0) {
      _movingSegmentIndex = route.length - 1;
      _movingSegmentFraction = 1.0;
      movingMarkerPosition.value = route.last;
      movingMarkerBearing.value = route.length >= 2
          ? _getBearing(route[route.length - 2], route.last)
          : 0.0;
      traveledRoutePoints.assignAll(List<LatLng>.from(route));
      try {
        historyMapController.move(route.last, historyMapController.camera.zoom);
      } catch (_) {}
      return;
    }
    final totalKm = _getTotalDistanceKm(route);
    final targetKm = clamped * totalKm;
    double cum = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      final segKm = _distanceKm(route[i], route[i + 1]);
      if (cum + segKm >= targetKm) {
        final t = segKm > 0 ? (targetKm - cum) / segKm : 0.0;
        _movingSegmentIndex = i;
        _movingSegmentFraction = t.clamp(0.0, 1.0);
        final a = route[i];
        final b = route[i + 1];
        final interpolated = LatLng(
          a.latitude + (b.latitude - a.latitude) * _movingSegmentFraction,
          a.longitude + (b.longitude - a.longitude) * _movingSegmentFraction,
        );
        movingMarkerPosition.value = interpolated;
        movingMarkerBearing.value = _getBearing(a, b);

        final passed = route.sublist(0, _movingSegmentIndex + 1);
        traveledRoutePoints.assignAll([...passed, interpolated]);

        try {
          historyMapController.move(
            interpolated,
            historyMapController.camera.zoom,
          );
        } catch (_) {}

        if (wasPlaying) startMovingMarker();
        return;
      }
      cum += segKm;
    }
    _movingSegmentIndex = route.length - 1;
    _movingSegmentFraction = 1.0;
    movingMarkerPosition.value = route.last;
    traveledRoutePoints.assignAll(List<LatLng>.from(route));
  }

  void advanceFrame() {
    _followDrawnRoute();
    final route = _playbackRoutePoints;
    if (route.length < 2) {
      stopMovingMarker();
      return;
    }

    // Real elapsed time per frame (web timers can fire late).
    final now = DateTime.now();
    final dt = _lastPlaybackTickAt == null
        ? _playbackTickSeconds
        : (now.difference(_lastPlaybackTickAt!).inMicroseconds / 1000000.0)
              .clamp(0.001, 0.1);
    _lastPlaybackTickAt = now;

    final baseMps = _playbackBaseMps(route);
    final effectiveMps = baseMps * playbackSpeedMultiplier.value;
    double distanceBudgetMeters = effectiveMps * dt;

    while (distanceBudgetMeters > 0) {
      if (_movingSegmentIndex >= route.length - 1) {
        movingMarkerPosition.value = route.last;
        final prevBearing = movingMarkerBearing.value ?? 0.0;
        final endBearing = route.length >= 2
            ? _getBearing(route[route.length - 2], route.last)
            : prevBearing;
        movingMarkerBearing.value = _lerpBearing(
          prevBearing,
          endBearing,
          _bearingSmoothing,
        );
        playbackProgress.value = 1.0;
        traveledRoutePoints.assignAll(List<LatLng>.from(route));
        currentPlaybackSpeedKmph.value = 0.0;
        stopMovingMarker();
        return;
      }

      final a = route[_movingSegmentIndex];
      final b = route[_movingSegmentIndex + 1];
      final segmentMeters = _distanceMeters(a, b);
      if (segmentMeters <= 1e-6) {
        _movingSegmentIndex++;
        _movingSegmentFraction = 0.0;
        continue;
      }

      final currentT = _movingSegmentFraction.clamp(0.0, 1.0);
      final remainingMeters = segmentMeters * (1.0 - currentT);
      if (distanceBudgetMeters >= remainingMeters) {
        distanceBudgetMeters -= remainingMeters;
        _movingSegmentIndex++;
        _movingSegmentFraction = 0.0;
      } else {
        final additionalT = distanceBudgetMeters / segmentMeters;
        _movingSegmentFraction = (currentT + additionalT).clamp(0.0, 1.0);
        distanceBudgetMeters = 0.0;
      }
    }

    if (_movingSegmentIndex >= route.length - 1) {
      movingMarkerPosition.value = route.last;
      playbackProgress.value = 1.0;
      traveledRoutePoints.assignAll(List<LatLng>.from(route));
      currentPlaybackSpeedKmph.value = 0.0;
      stopMovingMarker();
      return;
    }

    final a = route[_movingSegmentIndex];
    final b = route[_movingSegmentIndex + 1];
    final t = _movingSegmentFraction.clamp(0.0, 1.0);
    final interpolated = LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
    movingMarkerPosition.value = interpolated;
    final targetBearing = _getBearing(a, b);
    final prevBearing = movingMarkerBearing.value ?? targetBearing;
    movingMarkerBearing.value = _lerpBearing(
      prevBearing,
      targetBearing,
      _bearingSmoothing,
    );
    playbackProgress.value = _getProgressFromMarkerPosition(route);

    // Update dynamic playback speed
    final speedIdx = _playbackPointIndex;
    if (_playbackSpeedSeries.isNotEmpty &&
        speedIdx < _playbackSpeedSeries.length) {
      // Show the speed the vehicle actually recorded at this point.
      final s = _playbackSpeedSeries[speedIdx];
      currentPlaybackSpeedKmph.value = s > 0 ? s : 0.0;
    } else {
      currentPlaybackSpeedKmph.value = 0.0;
    }

    // Draw the route behind the moving vehicle. Only the moving tip changes
    // per frame; the whole list is rebuilt only when a new segment starts
    // (rebuilding thousands of points every frame made playback stutter).
    if (_movingSegmentIndex < route.length) {
      final wantLen = _movingSegmentIndex + 2; // passed points + moving tip
      final t = traveledRoutePoints;
      if (t.length == wantLen && t.length >= 2) {
        t[t.length - 1] = interpolated;
      } else {
        t.assignAll([
          ...route.sublist(0, _movingSegmentIndex + 1),
          interpolated,
        ]);
      }
    }

    // Camera glides with the vehicle every frame (it used to jump every
    // 300 ms, which made the map move in steps).
    try {
      // Map centre stays on the car every frame, at any speed, so the car
      // never runs off the screen.
      final cam = historyMapController.camera;
      historyMapController.move(interpolated, cam.zoom);
    } catch (_) {}
  }

  /// 1x playback speed in m/s, derived from the map's current zoom so the
  /// marker moves ~[_playbackScreenPxPerSec] px/s on screen.
  double _playbackBaseMps(List<LatLng> route) {
    double zoom = 14.0;
    try {
      zoom = historyMapController.camera.zoom;
    } catch (_) {}
    final lat = (movingMarkerPosition.value ?? route.first).latitude;
    final metersPerPixel =
        156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, zoom);
    final screenPace = metersPerPixel * _playbackScreenPxPerSec;
    // A long route (a whole day) must still finish in a sensible time and
    // the progress bar must visibly move, even when zoomed in close: at 1x
    // the full route plays in at most [_playbackMaxRouteSeconds].
    final cum = _cumulativeKm(route);
    final routePace = cum.isEmpty
        ? 0.0
        : cum.last * 1000 / _playbackMaxRouteSeconds;
    // ...but never more than 3x the on-screen pace, so even at 2x the car
    // moves at most ~270 px/s and the map tiles keep up with it.
    return math
        .max(screenPace, math.min(routePace, screenPace * 3))
        .clamp(_playbackMinMps, _playbackMaxMps)
        .toDouble();
  }

  static const double _playbackMaxRouteSeconds = 900; // 15 min at 1x

  // Cumulative distance (km) along the playback route, cached per route.
  List<LatLng>? _cumKmFor;
  List<double> _cumKm = const [];
  List<double> _cumulativeKm(List<LatLng> pts) {
    if (identical(_cumKmFor, pts) && _cumKm.length == pts.length) {
      return _cumKm;
    }
    final c = <double>[];
    double total = 0;
    for (int i = 0; i < pts.length; i++) {
      if (i > 0) total += _distanceKm(pts[i - 1], pts[i]);
      c.add(total);
    }
    _cumKmFor = pts;
    _cumKm = c;
    return c;
  }

  double _getProgressFromMarkerPosition([List<LatLng>? routePoints]) {
    final points = routePoints ?? _playbackRoutePoints;
    if (points.length < 2) return 0.0;
    final cum = _cumulativeKm(points);
    final total = cum.last;
    if (total <= 0) return 0.0;
    final i = _movingSegmentIndex.clamp(0, points.length - 1);
    double covered = cum[i];
    if (i < points.length - 1) {
      covered += _movingSegmentFraction.clamp(0.0, 1.0) * (cum[i + 1] - cum[i]);
    }
    return (covered / total).clamp(0.0, 1.0);
  }

  double _getTotalDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _distanceKm(points[i], points[i + 1]);
    }
    return total;
  }

  /// Rotation (in radians) to apply to the live car image so its front
  /// points in the direction of travel. The car image faces right (east)
  /// when not rotated, so 90 degrees is subtracted, exactly like History.
  double get liveMarkerRotationRad =>
      (liveMarkerBearing.value - 90.0) * math.pi / 180.0;

  /// Rotation for the top-view car (its front points up / north when not
  /// rotated), so it is simply the heading.
  double get liveTopViewRotationRad =>
      liveMarkerBearing.value * math.pi / 180.0;

  /// Same for the History playback car.
  double get historyTopViewRotationRad =>
      (movingMarkerBearing.value ?? 0.0) * math.pi / 180.0;

  double _getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final lon2 = end.longitude * math.pi / 180;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  double _lerpBearing(double from, double to, double t) {
    final diff = ((to - from + 540) % 360) - 180;
    return (from + diff * t) % 360;
  }

  double _distanceKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final la1 = a.latitude * math.pi / 180;
    final la2 = b.latitude * math.pi / 180;
    final x =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return R * c;
  }

  double _distanceMeters(LatLng a, LatLng b) => _distanceKm(a, b) * 1000;

  // ---------------------------------------------------------------------
  // Live Tracking Real-Time Engine (WebSocket + Road Buffer + Motion Gliding)
  // ---------------------------------------------------------------------

  Future<void> startLiveTracking(
    String imei, {
    bool reconnectOnly = false,
  }) async {
    if (imei.isEmpty || _liveDisposed) return;
    activeImei = imei;

    // FIX: every full start opens a new session. Any older in-flight start /
    // poll / road request that finishes later is ignored instead of
    // overwriting the current motion state.
    final int session = reconnectOnly ? _liveSessionId : ++_liveSessionId;

    if (!reconnectOnly) {
      _liveTrackingImei = imei;
      _stopLiveAnimationLoop();
      _stopLivePollingTimer();
      await _liveTrackWs.disconnect();
      _liveWaypoints.clear();
      _liveWaypointIndex = 0;
      _liveWaypointFraction = 0.0;
      _currentLiveSpeedMs = 0.0;
      _lastAcceptedGps = null;
      _lastGpsTime = null;
      _lastReportedSpeedKmh = 0.0;
      _roadFetchInFlight = false;
      _lastLiveFixTime = null;
      _lastAcceptedDeviceTime = null;
      _lastAcceptedFixTime = null;
      _prevRawFix = null;
      _liveHeadingKnown = false;
      _liveTrace.clear();
      _rtReset();
    }

    try {
      if (!reconnectOnly) isLoading.value = true;

      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei.trim()},
      );

      if (_liveDisposed || session != _liveSessionId) return;

      final rawBody = response.data;
      if (rawBody is! Map) return;
      final body = Map<String, dynamic>.from(rawBody);
      final snapshot = LiveTrackSnapshotModel.fromJson(body);
      final data = snapshot.data;
      if (data == null) return;

      _wsConfig = data.websocketConfig;
      _wsInfo = data.websocket;

      bool fed = false;
      final pos = data.currentPosition;
      final todayStats = data.todayStatistics;
      if (pos != null) {
        final lat = double.tryParse(pos.latitude ?? '');
        final lng = double.tryParse(pos.longitude ?? '');
        final bool isStale = _isStaleFix(pos.deviceTime);
        final speed = isStale ? 0.0 : (pos.speed ?? 0.0);
        final rawOdo =
            pos.odometer ??
            body['data']?['current_position']?['odometer'] ??
            body['data']?['vehicle_info']?['odometer'] ??
            data.vehicleInfo?.totalKilometersTraveled ??
            body['data']?['vehicle_info']?['total_kilometers_traveled'];

        final odoDigits = _keepOdometerUp(
          _extractOdometerDigits(rawOdo),
          vehicleDetail.value.odometerDigits,
        );

        final dynamicSensors = _buildDynamicSensors(
          pos: pos,
          rawMap: body['data'] is Map
              ? Map<String, dynamic>.from(body['data'])
              : null,
          isStale: isStale,
        );

        vehicleDetail.update((val) {
          if (val != null) {
            vehicleDetail.value = VehicleDetailData(
              vehicleNumber:
                  data.vehicleInfo?.vehicleNumber ?? val.vehicleNumber,
              odometerDigits: odoDigits,
              timestamp: pos.deviceTime ?? val.timestamp,
              // Today's distance only (position.kilometer is the device's
              // running counter, not today's km).
              distanceKm: todayStats?.totalKilometersToday != null
                  ? '${todayStats!.totalKilometersToday!.toStringAsFixed(1)} km'
                  : val.distanceKm,
              speedKmph: speed.toInt(),
              coordinates: (lat != null && lng != null)
                  ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                  : val.coordinates,
              latitude: lat ?? val.latitude,
              longitude: lng ?? val.longitude,
              address: val.address,
              deviceTime: pos.deviceTime ?? val.deviceTime,
              serverTime: pos.lastUpdate ?? val.serverTime,
              runningDuration:
                  todayStats?.displayRunningDuration ?? val.runningDuration,
              idleDuration: todayStats?.displayIdleDuration ?? val.idleDuration,
              stoppedDuration:
                  todayStats?.displayStoppedDuration ?? val.stoppedDuration,
              inactiveDuration:
                  todayStats?.displayInactiveDuration ?? val.inactiveDuration,
              avgSpeedKmph: todayStats?.avgSpeed != null
                  ? todayStats!.avgSpeed!.toInt().toString()
                  : val.avgSpeedKmph,
              maxSpeedKmph: todayStats?.maxSpeed != null
                  ? todayStats!.maxSpeed!.toInt().toString()
                  : val.maxSpeedKmph,
              todayOdoKm: todayStats?.totalKilometersToday != null
                  ? todayStats!.totalKilometersToday!.toStringAsFixed(1)
                  : val.todayOdoKm,
              sensors: dynamicSensors,
            );
          }
        });

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final location = LatLng(lat, lng);
          _lastLiveUpdateReceivedAt = DateTime.now();
          fed = true;

          // Home list refresh / WebSocket reconnect while this vehicle is
          // already moving on the map: feed the fix like any other one.
          // (Snapping here reset the road engine and threw the car onto
          // raw GPS, off the road.)
          if (reconnectOnly &&
              (_liveWaypoints.isNotEmpty ||
                  (_useRoadEngine && _rtPos != null))) {
            _onLiveDevicePosition(
              location,
              speed,
              status: isStale ? 'stale' : pos.derivedStatus,
              deviceTime: pos.deviceTime,
            );
          } else {
            _isOlderFix(pos.deviceTime); // records the fix time
            _snapLiveMarkerTo(location, speed);
            isLiveMoving.value =
                !isStale &&
                (speed > 0 || (pos.derivedStatus.toLowerCase() == 'running'));
            if (isLiveLocked.value) {
              recenterLiveMap();
            }
          }
        }
      }

      // FIX: model gave no usable position -> read it from the raw response.
      if (!fed) _feedRawSnapshotPosition(body);
      _applySnapshotOdometer(body);
      _applySnapshotDetails(body);

      if (!reconnectOnly) {
        _startLiveAnimationLoop();
        _startLivePollingTimer(imei);
        await _connectLiveWebSocket(imei);
      }
    } catch (e) {
      debugPrint('[LiveTrack] Error starting live tracking: $e');
    } finally {
      if (!reconnectOnly) isLoading.value = false;
      // FIX: the animation loop was stopped at the top of a full start; if the
      // snapshot failed or returned early, it was never restarted and the
      // marker froze. Restart it (no API involved).
      if (!reconnectOnly &&
          !_liveDisposed &&
          session == _liveSessionId &&
          _liveAnimationTimer == null) {
        _startLiveAnimationLoop();
      }
    }
  }

  void _startLivePollingTimer(String imei) {
    _stopLivePollingTimer();
    _livePollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_liveDisposed || activeImei.isEmpty || selectedTopTab.value != -1) {
        return;
      }
      final elapsedSec = DateTime.now()
          .difference(_lastLiveUpdateReceivedAt)
          .inSeconds;
      if (elapsedSec >= 4) {
        await _pollLiveSnapshot(imei);
      }
    });
  }

  void _stopLivePollingTimer() {
    _livePollingTimer?.cancel();
    _livePollingTimer = null;
  }

  Future<void> _pollLiveSnapshot(String imei) async {
    final int session = _liveSessionId;
    try {
      final response = await DioClient().get(
        ApiEndPoints.liveTrackSnapshot,
        queryParameters: {'imei': imei.trim()},
      );

      if (_liveDisposed || session != _liveSessionId) return;

      final rawBody = response.data;
      if (rawBody is! Map) return;
      final body = Map<String, dynamic>.from(rawBody);
      final snapshot = LiveTrackSnapshotModel.fromJson(body);
      final data = snapshot.data;
      if (data == null) return;

      bool fed = false;
      final pos = data.currentPosition;
      final todayStats = data.todayStatistics;
      if (pos != null) {
        final lat = double.tryParse(pos.latitude ?? '');
        final lng = double.tryParse(pos.longitude ?? '');
        final bool isStale = _isStaleFix(pos.deviceTime);
        final speed = isStale ? 0.0 : (pos.speed ?? 0.0);
        final odo = _keepOdometerUp(
          _extractOdometerDigits(pos.odometer),
          vehicleDetail.value.odometerDigits,
        );

        final dynamicSensors = _buildDynamicSensors(
          pos: pos,
          rawMap: body['data'] is Map
              ? Map<String, dynamic>.from(body['data'])
              : null,
          isStale: isStale,
        );

        vehicleDetail.update((val) {
          if (val != null) {
            vehicleDetail.value = VehicleDetailData(
              vehicleNumber:
                  data.vehicleInfo?.vehicleNumber ?? val.vehicleNumber,
              odometerDigits: odo,
              timestamp: pos.deviceTime ?? val.timestamp,
              // Today's distance only (position.kilometer is the device's
              // running counter, not today's km).
              distanceKm: todayStats?.totalKilometersToday != null
                  ? '${todayStats!.totalKilometersToday!.toStringAsFixed(1)} km'
                  : val.distanceKm,
              speedKmph: speed.toInt(),
              coordinates: (lat != null && lng != null)
                  ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
                  : val.coordinates,
              latitude: lat ?? val.latitude,
              longitude: lng ?? val.longitude,
              address: val.address,
              deviceTime: pos.deviceTime ?? val.deviceTime,
              serverTime: pos.lastUpdate ?? val.serverTime,
              runningDuration:
                  todayStats?.displayRunningDuration ?? val.runningDuration,
              idleDuration: todayStats?.displayIdleDuration ?? val.idleDuration,
              stoppedDuration:
                  todayStats?.displayStoppedDuration ?? val.stoppedDuration,
              inactiveDuration:
                  todayStats?.displayInactiveDuration ?? val.inactiveDuration,
              avgSpeedKmph: todayStats?.avgSpeed != null
                  ? todayStats!.avgSpeed!.toInt().toString()
                  : val.avgSpeedKmph,
              maxSpeedKmph: todayStats?.maxSpeed != null
                  ? todayStats!.maxSpeed!.toInt().toString()
                  : val.maxSpeedKmph,
              todayOdoKm: todayStats?.totalKilometersToday != null
                  ? todayStats!.totalKilometersToday!.toStringAsFixed(1)
                  : val.todayOdoKm,
              sensors: dynamicSensors,
            );
          }
        });

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final location = LatLng(lat, lng);
          _lastLiveUpdateReceivedAt = DateTime.now();
          fed = true;
          _onLiveDevicePosition(
            location,
            speed,
            status: isStale ? 'stale' : pos.derivedStatus,
            deviceTime: pos.deviceTime,
          );
        }
      }

      // FIX: model gave no usable position -> read it from the raw response.
      if (!fed) _feedRawSnapshotPosition(body);
      _applySnapshotOdometer(body);
      _applySnapshotDetails(body);
    } catch (e) {
      debugPrint('[LiveTrack] Fallback polling error: $e');
    }
  }

  /// Odometer from the live_track_snapshot response. The API sends it as
  /// data.position.odometer (e.g. 289155.23); other shapes are also read.
  /// The reading never goes down for the same vehicle.
  void _applySnapshotOdometer(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map) return;
    dynamic pick(dynamic m) => m is Map
        ? (m['odometer'] ?? m['total_km'] ?? m['total_kilometers_traveled'])
        : null;
    final raw =
        pick(data['position']) ??
        pick(data['current_position']) ??
        pick(data['vehicle']) ??
        pick(data['vehicle_info']) ??
        data['odometer'];
    final digits = _extractOdometerDigits(raw);
    if (digits == '0000000') return;
    final current = vehicleDetail.value.odometerDigits;
    final next = _keepOdometerUp(digits, current);
    if (next == current) return;
    vehicleDetail.value = vehicleDetail.value.copyWith(odometerDigits: next);
  }

  /// Fills the vehicle detail panel from the live_track_snapshot response
  /// exactly as the API sends it:
  ///   data.vehicle  -> vehicle_number
  ///   data.position -> speed, devicetime, last_update, latitude/longitude,
  ///                    odometer (via _applySnapshotOdometer), power,
  ///                    ignition, gsm_signal_strength, network, altitude
  ///   data.today    -> running/idle/stopped/inactive_hours, avg_speed,
  ///                    max_speed, today_km   (position.* as a backup)
  void _applySnapshotDetails(Map<String, dynamic> body) {
    final root = body['data'];
    if (root is! Map) return;
    final data = Map<String, dynamic>.from(root);
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

    final pos = data['position'] is Map
        ? asMap(data['position'])
        : asMap(data['current_position']);
    if (pos.isEmpty) return;
    final today = data['today'] is Map
        ? asMap(data['today'])
        : asMap(data['today_statistics']);
    final veh = data['vehicle'] is Map
        ? asMap(data['vehicle'])
        : asMap(data['vehicle_info']);

    String? str(dynamic v) {
      if (v == null || v is Map || v is List) return null;
      final t = v.toString().trim();
      return (t.isEmpty || t == 'null' || t == '-') ? null : t;
    }

    String? todayVal(String key) => str(today[key]) ?? str(pos[key]);

    final devTime = str(pos['devicetime']) ?? str(pos['device_time']);
    final srvTime = str(pos['last_update']) ?? str(pos['server_time']);
    final stale = _isStaleFix(devTime);
    final speed = stale
        ? 0.0
        : (double.tryParse(str(pos['speed']) ?? '') ?? 0.0);
    final lat = double.tryParse(str(pos['latitude']) ?? '');
    final lng = double.tryParse(str(pos['longitude']) ?? '');
    final hasLatLng = lat != null && lng != null && (lat != 0 || lng != 0);
    final todayKm = todayVal('today_km');

    final d = vehicleDetail.value;
    vehicleDetail.value = VehicleDetailData(
      vehicleNumber: str(veh['vehicle_number']) ?? d.vehicleNumber,
      odometerDigits: d.odometerDigits, // set by _applySnapshotOdometer
      timestamp: devTime ?? d.timestamp,
      distanceKm: todayKm != null ? '$todayKm Km' : d.distanceKm,
      speedKmph: speed.round(),
      coordinates: hasLatLng
          ? '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E'
          : d.coordinates,
      latitude: hasLatLng ? lat : d.latitude,
      longitude: hasLatLng ? lng : d.longitude,
      address: str(pos['address']) ?? str(pos['location']) ?? d.address,
      deviceTime: devTime ?? d.deviceTime,
      serverTime: srvTime ?? d.serverTime,
      runningDuration: todayVal('running_hours') ?? d.runningDuration,
      idleDuration: todayVal('idle_hours') ?? d.idleDuration,
      stoppedDuration: todayVal('stopped_hours') ?? d.stoppedDuration,
      inactiveDuration: todayVal('inactive_hours') ?? d.inactiveDuration,
      avgSpeedKmph: todayVal('avg_speed') ?? d.avgSpeedKmph,
      maxSpeedKmph: todayVal('max_speed') ?? d.maxSpeedKmph,
      todayOdoKm: todayKm ?? d.todayOdoKm,
      sensors: _buildDynamicSensors(rawMap: data, isStale: stale),
    );
  }

  /// Reads a position straight from a raw live_track_snapshot body when
  /// [LiveTrackSnapshotModel] did not parse one, and feeds it to the engine.
  void _feedRawSnapshotPosition(Map<String, dynamic> body) {
    final root = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'])
        : body;

    double? toD(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

    Map<String, dynamic>? src;
    double? lat;
    double? lng;
    for (final key in [
      'current_position',
      'position',
      'vehicle_info',
      'vehicle',
      'last_position',
      'location',
      null,
    ]) {
      final cand = key == null ? root : root[key];
      if (cand is! Map) continue;
      final m = Map<String, dynamic>.from(cand);
      final la = toD(m['latitude'] ?? m['lat'] ?? m['Latitude']);
      final ln = toD(m['longitude'] ?? m['lng'] ?? m['lon'] ?? m['Longitude']);
      if (la != null && ln != null && (la != 0.0 || ln != 0.0)) {
        src = m;
        lat = la;
        lng = ln;
        break;
      }
    }

    if (src == null || lat == null || lng == null) {
      debugPrint(
        '[LiveTrack] Snapshot has no usable position. data keys: ${root.keys.toList()}',
      );
      return;
    }

    final devTime =
        (src['device_time'] ??
                src['devicetime'] ??
                src['last_update'] ??
                src['server_time'])
            ?.toString();
    final stale = _isStaleFix(devTime);
    final speed = stale ? 0.0 : (toD(src['speed'] ?? src['Speed']) ?? 0.0);
    final course = toD(
      src['course'] ?? src['angle'] ?? src['heading'] ?? src['bearing'],
    );

    _lastLiveUpdateReceivedAt = DateTime.now();
    _onLiveDevicePosition(
      LatLng(lat, lng),
      speed,
      status: stale ? 'stale' : src['status']?.toString(),
      courseDeg: course,
      deviceTime: devTime,
    );
  }

  Future<void> _connectLiveWebSocket(String imei) async {
    if (_wsConfig == null) {
      debugPrint('[LiveTrack] WebSocket config missing from API snapshot');
      return;
    }

    final int session = _liveSessionId;
    final connected = await _liveTrackWs.connect(
      imei: imei,
      websocketConfig: _wsConfig,
      websocket: _wsInfo,
      onDeviceUpdate: _handleLiveDeviceUpdate,
      onReconnected: () {
        if (_liveDisposed || activeImei.isEmpty) return;
        debugPrint('[LiveTrack] WS reconnected, refreshing snapshot');
        startLiveTracking(activeImei, reconnectOnly: true);
      },
    );

    if (session != _liveSessionId) return;
    isLiveTrackingConnected.value = connected;
  }

  (double, double)? _readLatLngFromMap(Map<String, dynamic> data) {
    Map<String, dynamic> map = data;
    if (data['current_position'] is Map) {
      map = Map<String, dynamic>.from(data['current_position']);
    } else if (data['position'] is Map) {
      map = Map<String, dynamic>.from(data['position']);
    } else if (data['data'] is Map) {
      map = Map<String, dynamic>.from(data['data']);
    } else if (data['vehicle'] is Map) {
      map = Map<String, dynamic>.from(data['vehicle']);
    }

    final lat = double.tryParse(
      (map['latitude'] ?? map['lat'] ?? map['Latitude'])?.toString() ?? '',
    );
    final lng = double.tryParse(
      (map['longitude'] ?? map['lng'] ?? map['lon'] ?? map['Longitude'])
              ?.toString() ??
          '',
    );
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) return null;
    return (lat, lng);
  }

  num? _readSpeedFromMap(Map<String, dynamic> data) {
    Map<String, dynamic> map = data;
    if (data['current_position'] is Map) {
      map = Map<String, dynamic>.from(data['current_position']);
    } else if (data['position'] is Map) {
      map = Map<String, dynamic>.from(data['position']);
    } else if (data['data'] is Map) {
      map = Map<String, dynamic>.from(data['data']);
    }
    final raw = map['speed'] ?? map['Speed'] ?? map['spd'];
    if (raw is num) return raw;
    return num.tryParse(raw?.toString() ?? '');
  }

  double? _readCourseFromMap(Map<String, dynamic> data) {
    Map<String, dynamic> map = data;
    if (data['current_position'] is Map) {
      map = Map<String, dynamic>.from(data['current_position']);
    } else if (data['position'] is Map) {
      map = Map<String, dynamic>.from(data['position']);
    } else if (data['data'] is Map) {
      map = Map<String, dynamic>.from(data['data']);
    }
    final raw =
        map['course'] ??
        map['angle'] ??
        map['heading'] ??
        map['direction'] ??
        map['bearing'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  void _handleLiveDeviceUpdate(Map<String, dynamic> data) {
    if (_liveDisposed) return;
    try {
      final coords = _readLatLngFromMap(data);
      if (coords == null) {
        debugPrint('[LiveTrack] device update missing valid coords: $data');
        return;
      }

      final lat = coords.$1;
      final lng = coords.$2;
      var speed = _readSpeedFromMap(data)?.toDouble() ?? 0.0;
      final course = _readCourseFromMap(data);

      debugPrint(
        '[LiveTrack] Device Update -> Lat: $lat, Lng: $lng, Speed: $speed km/h, Course: $course',
      );

      _lastLiveUpdateReceivedAt = DateTime.now();

      Map<String, dynamic> map = data;
      if (data['current_position'] is Map) {
        map = Map<String, dynamic>.from(data['current_position']);
      } else if (data['data'] is Map) {
        map = Map<String, dynamic>.from(data['data']);
      }

      final todayMap = (data['today_statistics'] is Map)
          ? Map<String, dynamic>.from(data['today_statistics'])
          : ((data['todayStatistics'] is Map)
                ? Map<String, dynamic>.from(data['todayStatistics'])
                : null);

      final rawOdo = map['odometer'] ?? map['total_kilometers_traveled'];
      final odo = _keepOdometerUp(
        _extractOdometerDigits(rawOdo),
        vehicleDetail.value.odometerDigits,
      );
      final rawDevTime =
          map['devicetime']?.toString() ?? map['device_time']?.toString();
      final devTime = rawDevTime ?? vehicleDetail.value.deviceTime;
      final bool isStale = _isStaleFix(rawDevTime);
      if (isStale) speed = 0.0;
      final srvTime =
          map['last_update']?.toString() ??
          map['server_time']?.toString() ??
          vehicleDetail.value.serverTime;

      final dynamicSensors = _buildDynamicSensors(
        rawMap: map,
        isStale: isStale,
      );

      vehicleDetail.update((val) {
        if (val != null) {
          vehicleDetail.value = VehicleDetailData(
            vehicleNumber: val.vehicleNumber,
            odometerDigits: odo,
            timestamp: devTime.isNotEmpty ? devTime : val.timestamp,
            // The live update's 'kilometer' is the device's running counter
            // (e.g. 4318.51), not today's km: keep today's figure from the
            // snapshot unless the update itself carries today's total.
            distanceKm: todayMap?['total_kilometers_today'] != null
                ? '${todayMap!['total_kilometers_today']} km'
                : val.distanceKm,
            speedKmph: speed.toInt(),
            coordinates:
                '${lat.toStringAsFixed(5)}°N ${lng.toStringAsFixed(5)}°E',
            latitude: lat,
            longitude: lng,
            address: val.address,
            deviceTime: devTime,
            serverTime: srvTime,
            runningDuration:
                todayMap?['running_duration']?.toString() ??
                todayMap?['display_running_duration']?.toString() ??
                val.runningDuration,
            idleDuration:
                todayMap?['idle_duration']?.toString() ??
                todayMap?['display_idle_duration']?.toString() ??
                val.idleDuration,
            stoppedDuration:
                todayMap?['stopped_duration']?.toString() ??
                todayMap?['display_stopped_duration']?.toString() ??
                val.stoppedDuration,
            inactiveDuration:
                todayMap?['inactive_duration']?.toString() ??
                todayMap?['display_inactive_duration']?.toString() ??
                val.inactiveDuration,
            avgSpeedKmph:
                todayMap?['avg_speed']?.toString() ??
                todayMap?['average_speed']?.toString() ??
                val.avgSpeedKmph,
            maxSpeedKmph:
                todayMap?['max_speed']?.toString() ??
                todayMap?['top_speed']?.toString() ??
                val.maxSpeedKmph,
            todayOdoKm:
                todayMap?['total_kilometers_today']?.toString() ??
                val.todayOdoKm,
            sensors: dynamicSensors,
          );
        }
      });

      final statusStr = isStale
          ? 'stale'
          : (speed > 0
                ? 'Running'
                : (map['status']?.toString() ??
                      (map['ignition'] == 1 || map['ignition'] == '1'
                          ? 'Idle'
                          : 'Stopped')));

      _onLiveDevicePosition(
        LatLng(lat, lng),
        speed,
        status: statusStr,
        courseDeg: course,
        deviceTime: rawDevTime,
      );
    } catch (e) {
      debugPrint('[LiveTrack] Error handling live update: $e');
    }
  }

  void _onLiveDevicePosition(
    LatLng location,
    double speedKmH, {
    String? status,
    double? courseDeg,
    String? deviceTime,
  }) {
    // FIX: WebSocket, fallback polling and snapshot refreshes can deliver the
    // same trip out of order. An older fix queued after a newer one makes the
    // marker go backwards and then jump forward. Drop out-of-order fixes.
    if (_isOlderFix(deviceTime)) {
      debugPrint('[LiveTrack] Ignoring out-of-order fix ($deviceTime)');
      return;
    }

    // The 4 s snapshot poll repeats the same fix until the device sends a
    // new one. A repeat is not a new position: it must not reset the timing
    // (that made the car rush to the point and then stand still).
    final sameTime =
        deviceTime != null &&
        deviceTime.isNotEmpty &&
        deviceTime == _lastAcceptedDeviceTime;
    final samePlace =
        deviceTime == null &&
        _lastAcceptedGps != null &&
        _calculateDistance(_lastAcceptedGps!, location) < 0.5;
    if ((sameTime || samePlace) &&
        (_liveWaypoints.isNotEmpty || (_useRoadEngine && _rtPos != null))) {
      _lastReportedSpeedKmh = speedKmH;
      return;
    }
    if (deviceTime != null && deviceTime.isNotEmpty) {
      _lastAcceptedDeviceTime = deviceTime;
    }

    // Live movement: road engine (same model as the mobile app).
    if (_useRoadEngine) {
      _rtOnDevicePosition(
        location,
        speedKmH,
        status: status,
        courseDeg: courseDeg,
      );
      return;
    }

    final now = DateTime.now();
    final previousGps = _lastAcceptedGps;
    final previousGpsTime = _lastGpsTime;

    if (previousGps != null && liveMarkerPosition.value != null) {
      final anchor0 = previousGps;
      final d0 = _calculateDistance(anchor0, location);
      // a) GPS spike: further than the vehicle can have driven since the
      //    last fix (bad fix far from the road) -> ignore it.
      final fixT = _parseFixTime(deviceTime);
      final prevT = _lastAcceptedFixTime;
      final dt = (fixT != null && prevT != null)
          ? fixT.difference(prevT).inMilliseconds / 1000.0
          : (previousGpsTime == null
                ? 0.0
                : now.difference(previousGpsTime).inMilliseconds / 1000.0);
      if (dt > 0.5 && d0 < 3000.0) {
        final maxMps = math.max(speedKmH, 40.0) / 3.6 * 2.0 + 15.0;
        if (d0 / dt > maxMps) {
          debugPrint(
            '[LiveTrack] Ignoring GPS spike (${d0.round()} m in ${dt.toStringAsFixed(0)} s)',
          );
          return;
        }
      }
      // b) Small step BACKWARDS while driving (jitter / late fix): ignore,
      //    so the car never goes back and turns around.
      if (_prevRawFix != null &&
          _calculateDistance(_prevRawFix!, anchor0) > 5.0 &&
          d0 < 60.0 &&
          d0 > 0.5) {
        final travel = _getBearing(_prevRawFix!, anchor0);
        final toFix = _getBearing(anchor0, location);
        var diff = (toFix - travel).abs() % 360;
        if (diff > 180) diff = 360 - diff;
        if (diff > 110) {
          debugPrint('[LiveTrack] Ignoring backward step (${d0.round()} m)');
          return;
        }
      }
    }
    if (_parseFixTime(deviceTime) != null) {
      _lastAcceptedFixTime = _parseFixTime(deviceTime);
    }
    if (previousGps != null) _prevRawFix = previousGps;

    _lastReportedSpeedKmh = speedKmH;
    if (previousGpsTime != null) {
      final interval = now.difference(previousGpsTime).inMilliseconds / 1000.0;
      if (interval >= 0.8 && interval < 120.0) {
        // Follow longer gaps quickly (so the car does not run out of path),
        // shorter ones slowly.
        final w = interval > _expectedPingSec ? 0.5 : 0.25;
        _expectedPingSec = _expectedPingSec * (1 - w) + interval * w;
      }
    }

    final movedM = previousGps == null
        ? 0.0
        : _calculateDistance(previousGps, location);
    final isMoving =
        speedKmH > 0 ||
        (status != null && status.toLowerCase() == 'running') ||
        movedM > 30.0; // smaller moves at speed 0 are GPS drift
    isLiveMoving.value = isMoving;

    _lastAcceptedGps = location;
    _lastGpsTime = now;

    if (_liveWaypoints.isEmpty || liveMarkerPosition.value == null) {
      _snapLiveMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }

    final anchor = _liveWaypoints.last;
    final dist = _calculateDistance(anchor, location);

    if (dist > 3000.0) {
      _snapLiveMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }

    // Parked: the GPS position wanders a few metres (often across the
    // road). Those are not real moves - ignore them so the car neither
    // shifts nor turns sideways while standing.
    if (!isMoving && dist < 30.0) return;

    // Safety net: if the car has drifted away from the real position (bad
    // road geometry), bring it back onto the real fix right away.
    final carNow = liveMarkerPosition.value!;
    // (Checked against the PREVIOUS real fix, which the path must pass
    // near, and only when no fix is still waiting for Google.)
    if (_calculateDistance(carNow, location) > 1500.0 ||
        (_snapPending == 0 &&
            previousGps != null &&
            _distToQueuedPath(previousGps) > 60.0)) {
      _snapLiveMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }

    if (dist >= 0.5) {
      // The car only ever drives to ROAD points: the new fix is first put
      // on the road (Google), then added. Fixes are handled one after the
      // other so the path stays in order. Meanwhile the car keeps creeping
      // towards the previous (road) point.
      _snapPending++;
      _snapChain = _snapChain
          .then((_) => _queueSnappedFix(location))
          .whenComplete(() => _snapPending--);
    }
  }

  Future<void> _snapChain = Future.value();
  int _snapPending = 0;

  /// Distance from [p] to the nearest point of the car's remaining path.
  double _distToQueuedPath(LatLng p) {
    double best = double.infinity;
    for (int i = _liveWaypointIndex; i < _liveWaypoints.length; i++) {
      final d = _calculateDistance(_liveWaypoints[i], p);
      if (d < best) best = d;
    }
    final car = liveMarkerPosition.value;
    if (car != null) best = math.min(best, _calculateDistance(car, p));
    return best;
  }

  // Last raw GPS fixes, used to put the newest one on the right road.
  final List<LatLng> _liveTrace = [];

  /// Puts the newest fix ON the road and follows the road to it, using
  /// Google Roads (same as History, same roads as the Google map). Several
  /// recent fixes are sent together so Google knows the driving direction
  /// and picks the correct side of a divided road. Only when Google cannot
  /// answer (within 3 s) is the raw fix used, with the road route to it.
  Future<void> _queueSnappedFix(LatLng to) async {
    final session = _liveSessionId;
    if (_liveWaypoints.isEmpty) return;
    final from = _liveWaypoints.last;
    _liveTrace.add(to);
    if (_liveTrace.length > 6) _liveTrace.removeAt(0);
    final trace = List<LatLng>.from(_liveTrace);

    (List<LatLng>, List<int>)? res;
    if (trace.length >= 2) {
      try {
        res = await _googleSnap(
          trace,
          List<int>.generate(trace.length, (i) => i),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {
        res = null;
      }
    }
    if (_liveDisposed || session != _liveSessionId) return;

    List<LatLng>? path;
    if (res != null && res.$1.length >= 2) {
      final n = trace.length;
      path = [
        for (int k = 0; k < res.$1.length; k++)
          if (res.$2[k] >= n - 2) res.$1[k],
      ];
      if (path.isNotEmpty) {
        final snappedTo = path.last;
        double len = _calculateDistance(from, path.first);
        for (int k = 0; k < path.length - 1; k++) {
          len += _calculateDistance(path[k], path[k + 1]);
        }
        final straight = _calculateDistance(from, to);
        // Reject loops / far jumps (wrong road).
        // Reject loops and WRONG ROADS: GPS is off by ~5-25 m, so a road
        // point further than 35 m from the real fix is a parallel / side
        // road (that sent the car into fields next to the highway).
        final roadStraight = _calculateDistance(from, snappedTo);
        if (len > math.max(straight, roadStraight) * 1.5 + 30.0 ||
            _calculateDistance(snappedTo, to) > 35.0) {
          path = null;
        }
      } else {
        path = null;
      }
    }

    if (path != null) {
      // (The trace keeps the RAW fixes: feeding snapped points back made one
      // wrong snap stick to the wrong road for every next fix.)
      for (final p in path) {
        if (_calculateDistance(_liveWaypoints.last, p) >= 0.6) {
          _liveWaypoints.add(p);
        }
      }
      return;
    }

    // Google could not place it: use the road route to the fix. The route
    // starts and ends ON the road (its end is the nearest road point to the
    // fix), so the car still never leaves the road.
    try {
      final road = await _directionsService
          .getRoute(from, to, smooth: false)
          .timeout(const Duration(seconds: 4));
      if (_liveDisposed || session != _liveSessionId) return;
      if (road.length >= 2) {
        double len = 0;
        for (int k = 0; k < road.length - 1; k++) {
          len += _calculateDistance(road[k], road[k + 1]);
        }
        final end = road.last;
        final straight = _calculateDistance(from, to);
        if (len <= straight * 1.5 + 30.0 &&
            _calculateDistance(end, to) <= 35.0) {
          for (final p in road) {
            if (_calculateDistance(_liveWaypoints.last, p) >= 0.6) {
              _liveWaypoints.add(p);
            }
          }
          return;
        }
      }
    } catch (_) {}
    if (_liveDisposed || session != _liveSessionId) return;
    // Nothing on the road could be found: go to the fix itself.
    _liveWaypoints.add(to);
  }

  /// Puts a single point (vehicle shown for the first time / parked) on the
  /// nearest road (Google Roads nearestRoads). Null when not possible.
  Future<LatLng?> _nearestRoadPoint(LatLng p) async {
    final key = ApiConfig.googleMapKey;
    if (key.isEmpty || !_googleRoadsOk) return null;
    try {
      _osrmDio ??= dio_pkg.Dio(
        dio_pkg.BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (_) => true,
        ),
      );
      final res = await _osrmDio!.get(
        'https://roads.googleapis.com/v1/nearestRoads',
        queryParameters: {
          'points':
              '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}',
          'key': key,
        },
      );
      final data = res.data is String
          ? jsonDecode(res.data as String)
          : res.data;
      final sp = data is Map ? (data['snappedPoints'] as List?) : null;
      if (sp == null || sp.isEmpty || sp.first is! Map) return null;
      final loc = (sp.first as Map)['location'];
      if (loc is! Map) return null;
      final q = LatLng(
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
      return _calculateDistance(p, q) <= 40.0 ? q : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true when [deviceTime] is older than the newest fix already
  /// accepted. Otherwise records it as the newest fix. Unparseable or missing
  /// times are never treated as stale.
  bool _isOlderFix(String? deviceTime) {
    final t = _parseFixTime(deviceTime);
    if (t == null) return false;
    final last = _lastLiveFixTime;
    if (last != null && t.isBefore(last)) return true;
    _lastLiveFixTime = t;
    return false;
  }

  /// True when the device time is older than [_liveStaleAfter].
  /// Missing / unparseable times and future times are treated as fresh.
  bool _isStaleFix(String? deviceTime) {
    final t = _parseFixTime(deviceTime);
    if (t == null) return false;
    final age = DateTime.now().difference(t);
    return age > _liveStaleAfter;
  }

  DateTime? _parseFixTime(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty || s == 'null' || s == 'N/A') return null;

    // Epoch seconds / milliseconds
    if (RegExp(r'^\d{9,13}$').hasMatch(s)) {
      final n = int.tryParse(s);
      if (n == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(s.length >= 12 ? n : n * 1000);
    }

    // ISO style: 2026-09-29 13:01:05 / 2026-09-29T13:01:05Z
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // dd-MM-yyyy HH:mm[:ss] [AM/PM]
    final m = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?$',
    ).firstMatch(s);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final year = int.parse(m.group(3)!);
    var hour = int.parse(m.group(4)!);
    final minute = int.parse(m.group(5)!);
    final second = int.tryParse(m.group(6) ?? '0') ?? 0;
    final ampm = m.group(7)?.toUpperCase();
    if (ampm == 'PM' && hour < 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return DateTime(year, month, day, hour, minute, second);
  }

  void _snapLiveMarkerTo(
    LatLng location,
    double speedKmH, {
    double? courseDeg,
  }) {
    if (_useRoadEngine) {
      _rtSnapMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }
    _liveWaypoints
      ..clear()
      ..add(location);
    _liveWaypointIndex = 0;
    _liveWaypointFraction = 0.0;
    _liveTrace
      ..clear()
      ..add(location);
    // Put this first / jumped position on the road as well.
    final snapSession = _liveSessionId;
    _nearestRoadPoint(location).then((q) {
      if (q == null || _liveDisposed || snapSession != _liveSessionId) return;
      if (_liveWaypoints.length == 1 &&
          _calculateDistance(_liveWaypoints.first, location) < 0.5) {
        _liveWaypoints[0] = q;
        if (_liveTrace.isNotEmpty) _liveTrace[_liveTrace.length - 1] = q;
        liveMarkerPosition.value = q;
        if (isLiveLocked.value) _followLiveCamera(q);
      }
    });
    _currentLiveSpeedMs = speedKmH > 0 ? (speedKmH / 3.6) : 0.0;
    _lastReportedSpeedKmh = speedKmH;
    _lastAcceptedGps = location;
    _lastGpsTime = DateTime.now();
    final isMoving = speedKmH > 0;
    isLiveMoving.value = isMoving;
    final previousPos = liveMarkerPosition.value;
    liveMarkerPosition.value = location;
    // Heading only from a moving vehicle (course / jumps while parked are
    // noise and turned the car across the road).
    if (!isMoving) {
      // Parked and no heading yet: face the way it last drove (today's
      // route) instead of the default north.
      if (!_liveHeadingKnown) {
        final h = _headingFromToday();
        if (h != null) liveMarkerBearing.value = h;
      }
    } else if (courseDeg != null && courseDeg >= 0) {
      _liveHeadingKnown = true;
      liveMarkerBearing.value = courseDeg;
    } else if (previousPos != null &&
        _calculateDistance(previousPos, location) > 5.0) {
      // No course from the device: face the direction it jumped to.
      liveMarkerBearing.value = _getBearing(previousPos, location);
    }
    if (isLiveLocked.value) {
      _followLiveCamera(location);
    }
  }

  /// Point [meters] ahead of the car along the waypoint path (or the last
  /// waypoint if the path is shorter).
  LatLng? _pointAheadOnPath(double meters) {
    if (_liveWaypointIndex >= _liveWaypoints.length - 1) return null;
    final a0 = _liveWaypoints[_liveWaypointIndex];
    final b0 = _liveWaypoints[_liveWaypointIndex + 1];
    final t0 = _liveWaypointFraction.clamp(0.0, 1.0);
    LatLng cur = LatLng(
      a0.latitude + (b0.latitude - a0.latitude) * t0,
      a0.longitude + (b0.longitude - a0.longitude) * t0,
    );
    double left = meters;
    for (int i = _liveWaypointIndex + 1; i < _liveWaypoints.length; i++) {
      final nxt = _liveWaypoints[i];
      final d = _calculateDistance(cur, nxt);
      if (d >= left && d > 0) {
        final f = left / d;
        return LatLng(
          cur.latitude + (nxt.latitude - cur.latitude) * f,
          cur.longitude + (nxt.longitude - cur.longitude) * f,
        );
      }
      left -= d;
      cur = nxt;
    }
    return _liveWaypoints.last;
  }

  /// true = mobile-app road engine for the live car (below).
  static const bool _useRoadEngine = true;

  // =====================================================================
  // Live road engine (same model as the Airotrack mobile app).
  // * The car has ONE position (_rtPos). It only moves FORWARD along the
  //   road polyline (_rtQueue), so it cannot jump sideways or backwards.
  // * GPS never moves the car directly. Each GPS fix only re-requests the
  //   road for the recent GPS trace (map matching, up to 24 fixes), and the
  //   car's position is projected onto that road line.
  // * When no new road is available the car rolls on the last known road
  //   only as far as the latest GPS, never across fields.
  // =====================================================================
  LatLng? _rtPos;
  LatLng? _rtTarget;
  final List<LatLng> _rtQueue = [];
  final List<LatLng> _rtCorridor = [];
  final List<LatLng> _rtTrace = [];
  double _rtGlideMs = 0.0;
  double _rtLockedBearing = 0.0;
  double _rtUiHeading = 0.0;
  bool _rtHasHeading = false;
  bool _rtMoving = false;
  double _rtInferredKmh = 0.0;
  int _rtRequestId = 0;
  bool _rtFetchInFlight = false;
  DateTime? _rtLastFetchAt;
  LatLng? _rtPendingTarget;
  LatLng? _rtFailedTarget;
  DateTime? _rtFailCooldownUntil;
  LatLng? _rtLastMatchedTarget;

  static const double _rtSpeedTau = 0.50;
  static const double _rtMaxGlideMs = 45.0;
  static const double _rtMinRollMs = 0.6;
  static const double _rtStoppedCreepMs = 0.35;
  static const double _rtStoppedDeadbandM = 6.0;
  static const double _rtHeadingLookAheadM = 14.0;
  static const double _rtMaxHeadingDegPerSec = 60.0;
  static const double _rtWaypointMinM = 2.0;
  static const double _rtMinRouteM = 8.0;
  static const double _rtMaxBackwardDeg = 95.0;
  static const double _rtSnapBackMinLagM = 4.0;
  static const double _rtReverseStepM = 4.0;
  static const double _rtMinGpsBearingMoveM = 10.0;
  static const int _rtTraceMax = 24;
  static const double _rtMaxGpsToRoadM = 60.0;

  void _rtReset() {
    _rtPos = null;
    _rtTarget = null;
    _rtQueue.clear();
    _rtCorridor.clear();
    _rtTrace.clear();
    _rtGlideMs = 0.0;
    _rtHasHeading = false;
    _rtMoving = false;
    _rtInferredKmh = 0.0;
    _rtRequestId++;
    _rtFetchInFlight = false;
    _rtLastFetchAt = null;
    _rtPendingTarget = null;
    _rtFailedTarget = null;
    _rtFailCooldownUntil = null;
    _rtLastMatchedTarget = null;
  }

  // ---------------- GPS intake ----------------
  void _rtOnDevicePosition(
    LatLng location,
    double speedKmH, {
    String? status,
    double? courseDeg,
  }) {
    final now = DateTime.now();
    final previousGps = _lastAcceptedGps;
    final previousGpsTime = _lastGpsTime;

    if (_rtPos == null) {
      _rtSnapMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }
    // Very far jump (other trip / long gap): start again from there.
    if (_calculateDistance(_rtPos!, location) > 3000.0) {
      _rtSnapMarkerTo(location, speedKmH, courseDeg: courseDeg);
      return;
    }

    final inferred = _rtInferSpeedKmh(location, speedKmH, now);
    _lastReportedSpeedKmh = speedKmH;
    _rtInferredKmh = inferred;

    if (previousGpsTime != null) {
      final interval = now.difference(previousGpsTime).inMilliseconds / 1000.0;
      if (interval >= 0.8 && interval < 120.0) {
        _expectedPingSec = _expectedPingSec * 0.7 + interval * 0.3;
      }
    }

    // Device speed decides moving vs stopped (GPS jitter must not).
    _rtMoving = speedKmH > 0;
    isLiveMoving.value = _rtMoving;

    if (!_rtMoving) {
      final d = previousGps == null
          ? 0.0
          : _calculateDistance(previousGps, location);
      if (previousGps != null && d < _rtStoppedDeadbandM) {
        _lastGpsTime = now;
        return;
      }
      if (!_rtHasHeading &&
          courseDeg != null &&
          courseDeg >= 0 &&
          courseDeg <= 360) {
        _rtSetLockedBearing(courseDeg % 360);
      }
      _lastAcceptedGps = location;
      _lastGpsTime = now;
      _rtTarget = location;
      _rtRequestRoad(location, force: true);
      return;
    }

    if (previousGps != null && _rtIsLikelySnapBack(location, previousGps)) {
      _lastGpsTime = now;
      return;
    }

    _rtUpdateHeadingFromMovement(
      location,
      previousGps: previousGps,
      courseDeg: courseDeg,
    );

    _lastAcceptedGps = location;
    _lastGpsTime = now;
    _rtTarget = location;
    _rtRequestRoad(location, force: _rtQueue.length < 2);
  }

  void _rtSnapMarkerTo(LatLng location, double speedKmH, {double? courseDeg}) {
    _rtQueue.clear();
    _rtTrace.clear();
    final placed = _rtCorridor.length >= 2
        ? _rtClosestForwardPoint(location, _rtCorridor)
        : location;
    _rtPos = placed;
    _rtTarget = location;
    _lastAcceptedGps = location;
    _lastGpsTime = DateTime.now();
    _lastReportedSpeedKmh = speedKmH;
    _rtInferredKmh = speedKmH;
    _rtMoving = speedKmH > 0;
    isLiveMoving.value = _rtMoving;
    _rtGlideMs = speedKmH > 0
        ? (speedKmH / 3.6).clamp(0.0, _rtMaxGlideMs).toDouble()
        : 0.0;
    if (!_rtHasHeading) {
      if (courseDeg != null && courseDeg >= 0 && courseDeg <= 360) {
        _rtSetLockedBearing(courseDeg % 360);
      } else {
        final h = _headingFromToday();
        if (h != null) _rtSetLockedBearing(h);
      }
    }
    _rtTrace.add(location);
    _rtRequestRoad(location, force: true);
    _rtPublish(force: true);
  }

  // ---------------- Frame loop ----------------
  void _rtGlide(double dt) {
    final pos = _rtPos;
    if (pos == null || _rtTarget == null) return;

    if (_rtMoving) {
      final remaining = _rtRemainingMeters(pos);
      final target = _rtTargetSpeedMs(remaining);
      final alpha = 1.0 - math.exp(-dt / _rtSpeedTau);
      _rtGlideMs += (target - _rtGlideMs) * alpha;
      if (_rtGlideMs < _rtMinRollMs && remaining > 1.0) {
        _rtGlideMs = _rtMinRollMs;
      }
      if (_rtGlideMs < 0) _rtGlideMs = 0;

      var step = _rtGlideMs * dt;
      if (step > remaining) step = remaining;
      if (step > 0.0005) {
        if (_rtQueue.isNotEmpty) {
          _rtAdvance(step);
        } else if (_rtCorridor.length >= 2) {
          _rtContinueAlongKnownRoad(step);
        }
      }
      _rtMaybePrefetch(remaining);
    } else {
      _rtCreepWhileStopped(dt);
    }

    _rtUpdateHeading(dt);
    _rtUpdateKeepLeft(dt);
    _rtPublish();
  }

  /// Speed needed to use up the road buffer by the time the next fix is
  /// due (a little later, so it is still rolling when it arrives), kept
  /// near the speed the device reports.
  double _rtTargetSpeedMs(double remaining) {
    final reported = math.max(_lastReportedSpeedKmh, _rtInferredKmh) / 3.6;
    final horizon = (_expectedPingSec * 1.3).clamp(1.5, 60.0);
    var v = remaining / horizon;
    if (reported > 0.4) {
      v = v.clamp(reported * 0.3, reported * 1.8);
    } else {
      v = v.clamp(0.0, 14.0);
    }
    if (remaining < 2.0) {
      v = math.min(v, math.max(remaining * 1.2, _rtMinRollMs));
    }
    return v.clamp(0.0, _rtMaxGlideMs).toDouble();
  }

  void _rtAdvance(double step) {
    var pos = _rtPos!;
    var remaining = step;
    while (remaining > 0.001 && _rtQueue.isNotEmpty) {
      final next = _rtQueue.first;
      final dist = _calculateDistance(pos, next);
      if (dist < 0.05) {
        _rtQueue.removeAt(0);
        continue;
      }
      if (dist <= remaining) {
        pos = next;
        remaining -= dist;
        _rtQueue.removeAt(0);
      } else {
        final f = remaining / dist;
        pos = LatLng(
          pos.latitude + (next.latitude - pos.latitude) * f,
          pos.longitude + (next.longitude - pos.longitude) * f,
        );
        remaining = 0;
      }
    }
    _rtPos = pos;
  }

  void _rtContinueAlongKnownRoad(double step) {
    final target = _rtTarget;
    if (_rtCorridor.length < 2 || target == null) return;
    final gpsOnRoad = _rtClosestPointOnPolyline(target, _rtCorridor);
    if (_calculateDistance(target, gpsOnRoad) > _rtMaxGpsToRoadM) return;
    final onNow = _rtClosestPointOnPolyline(_rtPos!, _rtCorridor);
    if (_calculateDistance(_rtPos!, onNow) > 2.0) _rtPos = onNow;
    final ahead = _rtTrimAhead(_rtPos!, _rtCorridor);
    final limited = _rtTrimToUpdate(ahead, gpsOnRoad);
    if (limited.length < 2) return;
    _rtQueue
      ..clear()
      ..addAll(limited);
    _rtAdvance(step);
  }

  void _rtCreepWhileStopped(double dt) {
    _rtGlideMs = 0.0;
    if (_rtQueue.isEmpty) return;
    final remaining = _rtRemainingMeters(_rtPos!);
    if (remaining <= 1.5) return;
    _rtAdvance(math.min(_rtStoppedCreepMs * dt, remaining));
  }

  void _rtMaybePrefetch(double remaining) {
    final t = _rtTarget;
    if (t == null) return;
    final threshold = math.max(80.0, _rtGlideMs * _expectedPingSec);
    if (remaining >= threshold && _rtQueue.length >= 2) return;
    // Same fix already matched: nothing new to ask for.
    final last = _rtLastMatchedTarget;
    if (last != null &&
        _calculateDistance(last, t) < 1.0 &&
        _rtQueue.length >= 2) {
      return;
    }
    _rtRequestRoad(t, force: _rtQueue.length < 2);
  }

  // ---------------- Heading ----------------
  void _rtUpdateHeading(double dt) {
    if (_rtQueue.isNotEmpty) {
      final ahead = _rtBearingLookAhead(_rtPos!, _rtHeadingLookAheadM);
      if (ahead != null) {
        if (!_rtHasHeading) {
          _rtSetLockedBearing(ahead);
        } else {
          _rtLockedBearing = ahead;
        }
      }
    }
    if (!_rtHasHeading) return;
    final delta = _rtBearingDelta(_rtUiHeading, _rtLockedBearing);
    final maxStep = _rtMaxHeadingDegPerSec * dt;
    final step = delta.clamp(-maxStep, maxStep).toDouble();
    if (step.abs() < 0.02) return;
    _rtUiHeading = (_rtUiHeading + step) % 360;
    if (_rtUiHeading < 0) _rtUiHeading += 360;
    liveMarkerBearing.value = _rtUiHeading;
  }

  double? _rtBearingLookAhead(LatLng from, double meters) {
    if (_rtQueue.isEmpty) return null;
    var traveled = 0.0;
    var prev = from;
    LatLng? pick;
    for (final p in _rtQueue) {
      traveled += _calculateDistance(prev, p);
      prev = p;
      pick = p;
      if (traveled >= meters) break;
    }
    if (pick == null || _calculateDistance(from, pick) < 1.5) return null;
    return _getBearing(from, pick);
  }

  void _rtSetLockedBearing(double bearing) {
    bearing = bearing % 360;
    if (bearing < 0) bearing += 360;
    if (!_rtHasHeading) {
      _rtLockedBearing = bearing;
      _rtUiHeading = bearing;
      liveMarkerBearing.value = bearing;
      _rtHasHeading = true;
      return;
    }
    _rtLockedBearing = bearing;
  }

  void _rtUpdateHeadingFromMovement(
    LatLng location, {
    LatLng? previousGps,
    double? courseDeg,
  }) {
    if (_rtQueue.length >= 2 && _rtHasHeading) return;
    double? movementBearing;
    var movedM = 0.0;
    if (previousGps != null) {
      movedM = _calculateDistance(previousGps, location);
      if (movedM >= _rtMinGpsBearingMoveM) {
        movementBearing = _getBearing(previousGps, location);
      }
    }
    if (movementBearing == null && _rtPos != null) {
      movedM = _calculateDistance(_rtPos!, location);
      if (movedM >= _rtMinGpsBearingMoveM * 1.5) {
        movementBearing = _getBearing(_rtPos!, location);
      }
    }
    if (movementBearing != null) {
      if (_rtHasHeading) {
        final flip = _rtBearingDelta(_rtLockedBearing, movementBearing).abs();
        if (flip > 55.0 && movedM < 25.0) return;
      }
      _rtSetLockedBearing(movementBearing);
      return;
    }
    if (!_rtHasHeading &&
        courseDeg != null &&
        courseDeg >= 0 &&
        courseDeg <= 360) {
      _rtSetLockedBearing(courseDeg % 360);
    }
  }

  // ---------------- Publish: marker + camera in the same tick ----------
  void _rtPublish({bool force = false}) {
    final p = _rtPos;
    if (p == null) return;
    final shown = _rtKeepLeft(p);
    liveMarkerPosition.value = shown;
    if (isLiveLocked.value) _followLiveCamera(shown);
  }

  /// India drives on the LEFT. The road line is the middle of the road, so
  /// the car is drawn this far to the left of its direction of travel,
  /// in its own lane instead of on the middle / the other side.
  /// Wide roads (fast driving) get a full lane offset; narrow village roads
  /// only a small one, otherwise the car looked off the edge of the road.
  double _rtKeepLeftM = 1.5;

  void _rtUpdateKeepLeft(double dt) {
    final kmh = math.max(_lastReportedSpeedKmh, _rtInferredKmh);
    final target = (_rtMoving && kmh >= 40.0) ? 3.0 : 1.5;
    final a = 1.0 - math.exp(-dt / 1.5);
    _rtKeepLeftM += (target - _rtKeepLeftM) * a;
  }

  LatLng _rtKeepLeft(LatLng p) {
    if (!_rtHasHeading) return p;
    final b = (_rtUiHeading - 90.0) * math.pi / 180.0; // left of travel
    final dLat = _rtKeepLeftM * math.cos(b) / 111320.0;
    final dLng =
        _rtKeepLeftM *
        math.sin(b) /
        (111320.0 * math.cos(p.latitude * math.pi / 180.0));
    return LatLng(p.latitude + dLat, p.longitude + dLng);
  }

  // ---------------- Road (map matching on the GPS trace) ----------------
  void _rtRequestRoad(LatLng to, {bool force = false}) {
    _rtPushTrace(to);
    _rtPendingTarget = to;
    final pos = _rtPos;
    if (pos == null) return;
    if (!_rtCanRequest(to, force: force)) return;

    final straightM = _calculateDistance(pos, to);
    final queueEmpty = _rtQueue.length < 2;
    if (straightM < _rtMinRouteM && !queueEmpty) return;
    if (!queueEmpty && straightM < 15.0 && _rtRemainingMeters(pos) > 20.0) {
      return;
    }
    if (_rtHasHeading && _rtIsBehind(pos, to) && straightM < 50.0) return;

    _rtLastFetchAt = DateTime.now();
    _rtFetchInFlight = true;
    final requestId = ++_rtRequestId;
    final session = _liveSessionId;
    final toPt = to;
    final trace = <LatLng>[..._rtTrace];

    () async {
      try {
        List<LatLng> road = const [];
        if (trace.length >= 2) {
          // 1) Google Roads directly (plain request, works in the browser,
          //    same roads as the Google map - like the mobile app gets).
          road = await _rtMatchOnGoogle(trace);
          if (road.length < 2) {
            // 2) Fallback: DirectionsService (OSRM).
            road = await _directionsService
                .matchTrace(trace, radiusMeters: 50)
                .timeout(const Duration(seconds: 8));
            // DirectionsService returns the raw trace itself when no road
            // match was possible: that is NOT a road.
            if (_rtSameAsTrace(road, trace)) road = const [];
          }
        } else {
          // Single fix (first position): road route from it to itself is
          // not possible; ask the nearest road point instead.
          final q = await _nearestRoadPoint(toPt);
          if (q != null) road = [q, q];
        }
        if (trace.length >= 2 && !_rtRoadFollowsGps(road, trace)) {
          road = const [];
        }
        if (_liveDisposed || session != _liveSessionId) return;
        if (requestId != _rtRequestId && _rtQueue.length >= 2) return;
        if (road.length < 2) {
          _rtFailedTarget = toPt;
          _rtFailCooldownUntil = DateTime.now().add(const Duration(seconds: 3));
          return;
        }
        if (trace.length < 2) {
          // First position: put the car on the nearest road point.
          if (_rtQueue.isEmpty &&
              _rtPos != null &&
              _calculateDistance(_rtPos!, road.first) <= 40.0) {
            _rtPos = road.first;
            _rtPublish(force: true);
          }
          return;
        }
        _rtFailedTarget = null;
        _rtFailCooldownUntil = null;
        _rtLastMatchedTarget = toPt;
        _rtCorridor
          ..clear()
          ..addAll(road);

        var prepared = _rtOrientWithTravel(road);
        prepared = _rtDecimate(prepared, _rtWaypointMinM);
        final trimmed = _rtTrimToUpdate(prepared, toPt);
        if (trimmed.length >= 2) prepared = trimmed;
        if (prepared.length < 2) return;
        _rtAdopt(prepared);
      } catch (e) {
        debugPrint('[LiveTrack] road match failed: $e');
        _rtFailedTarget = toPt;
        _rtFailCooldownUntil = DateTime.now().add(const Duration(seconds: 3));
      } finally {
        _rtFetchInFlight = false;
        final pending = _rtPendingTarget;
        if (!_liveDisposed &&
            session == _liveSessionId &&
            pending != null &&
            _calculateDistance(pending, toPt) > 25.0) {
          _rtRequestRoad(pending, force: _rtQueue.length < 2);
        }
      }
    }();
  }

  /// Live GPS trace snapped on Google's roads (the roads drawn on the map).
  /// Empty when Google is not available, so the caller can fall back.
  Future<List<LatLng>> _rtMatchOnGoogle(List<LatLng> trace) async {
    try {
      final res = await _googleSnap(
        trace,
        List<int>.generate(trace.length, (i) => i),
      ).timeout(const Duration(seconds: 8));
      if (res == null || res.$1.length < 2) return const [];
      return res.$1;
    } catch (e) {
      debugPrint('[LiveTrack] Google road match failed: $e');
      return const [];
    }
  }

  bool _rtSameAsTrace(List<LatLng> road, List<LatLng> trace) {
    if (road.length != trace.length) return false;
    for (int i = 0; i < road.length; i++) {
      if (_calculateDistance(road[i], trace[i]) > 0.01) return false;
    }
    return true;
  }

  /// Car's current point projected onto the new road; only the road AHEAD
  /// of it is walked (never a shortcut back towards raw GPS).
  void _rtAdopt(List<LatLng> path) {
    if (path.length < 2 || _rtPos == null) return;
    final published = _rtPos!;
    final onNew = _rtClosestForwardPoint(published, path);
    final ahead = _rtTrimAhead(onNew, path);
    if (ahead.length < 2) return;
    if (_rtQueue.length >= 2) {
      final remainingNow = _rtRemainingMeters(published);
      final newRemaining = _rtPathLength(ahead);
      if (remainingNow > 20.0 &&
          newRemaining + 1.0 < remainingNow &&
          _calculateDistance(published, onNew) < 3.0) {
        return;
      }
    }
    _rtQueue
      ..clear()
      ..addAll(ahead);
    _rtPos = onNew;
  }

  bool _rtCanRequest(LatLng to, {required bool force}) {
    if (_rtFetchInFlight) return false;
    final now = DateTime.now();
    final failed = _rtFailedTarget;
    final cooldown = _rtFailCooldownUntil;
    if (failed != null &&
        cooldown != null &&
        now.isBefore(cooldown) &&
        _calculateDistance(failed, to) < 25.0) {
      return false;
    }
    final last = _rtLastFetchAt;
    if (last != null) {
      final minGapMs = force ? 800 : 1200;
      if (now.difference(last).inMilliseconds < minGapMs) return false;
    }
    return true;
  }

  bool _rtRoadFollowsGps(List<LatLng> road, List<LatLng> gps) {
    if (road.length < 2 || gps.isEmpty) return false;
    final recent = gps.length > 4 ? gps.sublist(gps.length - 4) : gps;
    for (final p in recent) {
      final on = _rtClosestPointOnPolyline(p, road);
      if (_calculateDistance(p, on) > _rtMaxGpsToRoadM) return false;
    }
    final traceLen = _rtPathLength(gps);
    final routeLen = _rtPathLength(road);
    if (traceLen > 40.0 && routeLen > traceLen * 4.0) return false;
    return true;
  }

  void _rtPushTrace(LatLng p) {
    if (_rtTrace.isNotEmpty && _calculateDistance(_rtTrace.last, p) < 1.5) {
      _rtTrace[_rtTrace.length - 1] = p;
      return;
    }
    _rtTrace.add(p);
    while (_rtTrace.length > _rtTraceMax) {
      _rtTrace.removeAt(0);
    }
  }

  List<LatLng> _rtOrientWithTravel(List<LatLng> path) {
    if (path.length < 2) return path;
    final pathBearing = _rtPathBearingOver(path, 30.0);
    if (pathBearing == null) return path;
    double? travel;
    if (_rtTrace.length >= 2) {
      final prev = _rtTrace[_rtTrace.length - 2];
      final curr = _rtTrace.last;
      if (_calculateDistance(prev, curr) >= 5.0)
        travel = _getBearing(prev, curr);
    }
    travel ??= _rtHasHeading ? _rtLockedBearing : null;
    if (travel == null) return path;
    final vsTravel = _rtBearingDelta(travel, pathBearing).abs();
    if (vsTravel <= 100.0) return path;
    final reversed = path.reversed.toList();
    final rev = _rtPathBearingOver(reversed, 30.0);
    if (rev == null) return path;
    final vsRev = _rtBearingDelta(travel, rev).abs();
    return (vsRev + 25.0 < vsTravel) ? reversed : path;
  }

  double? _rtPathBearingOver(List<LatLng> path, double meters) {
    if (path.length < 2) return null;
    var traveled = 0.0;
    var i = 1;
    while (i < path.length && traveled < meters) {
      traveled += _calculateDistance(path[i - 1], path[i]);
      i++;
    }
    final end = path[math.min(i - 1, path.length - 1)];
    if (_calculateDistance(path.first, end) < 2.0) {
      return _getBearing(path[path.length - 2], path.last);
    }
    return _getBearing(path.first, end);
  }

  List<LatLng> _rtDecimate(List<LatLng> path, double minMeters) {
    if (path.length <= 2) return path;
    final out = <LatLng>[path.first];
    for (var i = 1; i < path.length - 1; i++) {
      if (_calculateDistance(out.last, path[i]) >= minMeters) out.add(path[i]);
    }
    if (_calculateDistance(out.last, path.last) >= 1.0 || out.length < 2) {
      out.add(path.last);
    } else {
      out[out.length - 1] = path.last;
    }
    return out;
  }

  List<LatLng> _rtTrimToUpdate(List<LatLng> path, LatLng update) {
    if (path.length < 2) return path;
    final hit = _rtClosestSegment(update, path);
    final out = <LatLng>[];
    for (var i = 0; i <= hit.index; i++) {
      out.add(path[i]);
    }
    if (out.isEmpty || _calculateDistance(out.last, hit.point) >= 0.5) {
      out.add(hit.point);
    } else {
      out[out.length - 1] = hit.point;
    }
    return out.length >= 2 ? out : path;
  }

  List<LatLng> _rtTrimAhead(LatLng from, List<LatLng> route) {
    if (route.length < 2) return route;
    final hit = _rtClosestSegment(from, route);
    final out = <LatLng>[hit.point];
    for (var i = hit.index + 1; i < route.length; i++) {
      if (_calculateDistance(out.last, route[i]) >= 0.4) out.add(route[i]);
    }
    return out;
  }

  double _rtPathLength(List<LatLng> path) {
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      total += _calculateDistance(path[i - 1], path[i]);
    }
    return total;
  }

  double _rtRemainingMeters(LatLng current) {
    if (_rtQueue.isEmpty) {
      final t = _rtTarget;
      if (_rtCorridor.length < 2 || t == null) return 0.0;
      final gpsOnRoad = _rtClosestPointOnPolyline(t, _rtCorridor);
      if (_calculateDistance(t, gpsOnRoad) > _rtMaxGpsToRoadM) return 0.0;
      final ahead = _rtTrimAhead(current, _rtCorridor);
      return _rtPathLength(_rtTrimToUpdate(ahead, gpsOnRoad));
    }
    var total = _calculateDistance(current, _rtQueue.first);
    for (var i = 1; i < _rtQueue.length; i++) {
      total += _calculateDistance(_rtQueue[i - 1], _rtQueue[i]);
    }
    return total;
  }

  LatLng _rtClosestPointOnPolyline(LatLng p, List<LatLng> poly) {
    if (poly.isEmpty) return p;
    if (poly.length == 1) return poly.first;
    return _rtClosestSegment(p, poly).point;
  }

  LatLng _rtClosestForwardPoint(LatLng p, List<LatLng> poly) {
    if (poly.length < 2) return poly.isEmpty ? p : poly.first;
    final hits = <({int index, LatLng point, double distance})>[];
    var bestD = double.infinity;
    for (var i = 0; i < poly.length - 1; i++) {
      final projected = _rtProject(p, poly[i], poly[i + 1]);
      final d = _calculateDistance(p, projected);
      hits.add((index: i, point: projected, distance: d));
      if (d < bestD) bestD = d;
    }
    var pick = hits.first;
    var bestScore = double.infinity;
    for (final hit in hits) {
      if (hit.distance > bestD + 12.0) continue;
      var score = hit.distance;
      final a = poly[hit.index];
      final b = poly[hit.index + 1];
      if (_rtHasHeading && _calculateDistance(a, b) > 1.0) {
        final turn = _rtBearingDelta(_rtLockedBearing, _getBearing(a, b)).abs();
        if (turn > 80) score += 40;
      }
      if (score < bestScore) {
        bestScore = score;
        pick = hit;
      }
    }
    return pick.point;
  }

  ({int index, LatLng point, double distance}) _rtClosestSegment(
    LatLng p,
    List<LatLng> poly,
  ) {
    var bestIndex = 0;
    var best = poly.first;
    var bestDist = double.infinity;
    for (var i = 0; i < poly.length - 1; i++) {
      final projected = _rtProject(p, poly[i], poly[i + 1]);
      final d = _calculateDistance(p, projected);
      if (d < bestDist) {
        bestDist = d;
        best = projected;
        bestIndex = i;
      }
    }
    return (index: bestIndex, point: best, distance: bestDist);
  }

  LatLng _rtProject(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    if (dx == 0 && dy == 0) return a;
    final t =
        (((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
                (dx * dx + dy * dy))
            .clamp(0.0, 1.0);
    return LatLng(a.latitude + dy * t, a.longitude + dx * t);
  }

  bool _rtIsForwardOf(LatLng point, LatLng origin) {
    if (!_rtHasHeading) return true;
    return _rtBearingDelta(
          _rtLockedBearing,
          _getBearing(origin, point),
        ).abs() <=
        _rtMaxBackwardDeg;
  }

  bool _rtIsBehind(LatLng current, LatLng point) {
    if (!_rtHasHeading) return false;
    return _rtBearingDelta(
          _rtLockedBearing,
          _getBearing(current, point),
        ).abs() >
        _rtMaxBackwardDeg;
  }

  bool _rtIsLikelySnapBack(LatLng location, LatLng previousGps) {
    final animated = _rtPos;
    if (!_rtHasHeading || animated == null) return false;
    if (!_rtIsBehind(animated, location)) return false;
    final lagM = _calculateDistance(animated, location);
    if (lagM < _rtSnapBackMinLagM) return false;
    final gpsStepM = _calculateDistance(previousGps, location);
    if (gpsStepM < 1.0) return true;
    final gpsMovingBackward =
        !_rtIsForwardOf(location, previousGps) && gpsStepM >= _rtReverseStepM;
    return !gpsMovingBackward;
  }

  double _rtBearingDelta(double from, double to) =>
      ((to - from + 540) % 360) - 180;

  double _rtInferSpeedKmh(LatLng location, double reportedKmh, DateTime now) {
    if (_lastAcceptedGps == null || _lastGpsTime == null) return reportedKmh;
    final deltaM = _calculateDistance(_lastAcceptedGps!, location);
    if (deltaM < 1.0) return reportedKmh;
    final seconds = now.difference(_lastGpsTime!).inMilliseconds / 1000.0;
    if (seconds <= 0) return reportedKmh;
    return math.max(reportedKmh, (deltaM / seconds) * 3.6);
  }

  void _startLiveAnimationLoop() {
    _stopLiveAnimationLoop();
    _lastLiveTickTime = DateTime.now();
    _liveAnimationTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_liveDisposed) return;
      final now = DateTime.now();
      final dt = _lastLiveTickTime == null
          ? 0.016
          : (now.difference(_lastLiveTickTime!).inMicroseconds / 1000000.0)
                .clamp(0.001, 0.1);
      _lastLiveTickTime = now;
      _advanceLiveFrame(dt);
    });
  }

  void _stopLiveAnimationLoop() {
    _liveAnimationTimer?.cancel();
    _liveAnimationTimer = null;
    _lastLiveTickTime = null;
  }

  void _advanceLiveFrame(double dt) {
    if (_useRoadEngine) {
      _rtGlide(dt);
      return;
    }
    if (_liveWaypoints.isEmpty) return;

    if (_liveWaypoints.length == 1) {
      liveMarkerPosition.value = _liveWaypoints.first;
      if (isLiveLocked.value) {
        _followLiveCamera(_liveWaypoints.first);
      }
      return;
    }

    if (_liveWaypointIndex >= _liveWaypoints.length - 1) {
      final dest = _liveWaypoints.last;
      liveMarkerPosition.value = dest;
      _currentLiveSpeedMs = 0.0;
      if (isLiveLocked.value) {
        _followLiveCamera(dest);
      }
      return;
    }

    // Compute remaining distance in waypoints
    double remainingMeters = 0.0;
    final a0 = _liveWaypoints[_liveWaypointIndex];
    final b0 = _liveWaypoints[_liveWaypointIndex + 1];
    final segDist0 = _calculateDistance(a0, b0);
    final t0 = _liveWaypointFraction.clamp(0.0, 1.0);
    remainingMeters += segDist0 * (1.0 - t0);
    for (int i = _liveWaypointIndex + 1; i < _liveWaypoints.length - 1; i++) {
      remainingMeters += _calculateDistance(
        _liveWaypoints[i],
        _liveWaypoints[i + 1],
      );
    }

    // Target speed: spread the distance to the newest point over the time
    // until the next point is expected, so the car is still moving when it
    // arrives. If the next point is late, the car keeps creeping slowly
    // towards the last point (never reaching it and standing still) and
    // speeds up again as soon as the new point comes in.
    final sinceFix = _lastGpsTime == null
        ? 0.0
        : DateTime.now().difference(_lastGpsTime!).inMilliseconds / 1000.0;
    // The car is planned to reach the newest point only AFTER the next one
    // is due (1.6 x the usual gap), so normally the next point arrives while
    // it is still moving. If the next point is late, it keeps slowing down
    // smoothly (never a sudden stop) and speeds up again when it arrives.
    final ping = _expectedPingSec.clamp(2.0, 90.0);
    final horizon = ping * 1.6;
    final timeLeft = horizon - sinceFix;
    final creepTau = (ping * 0.6).clamp(4.0, 40.0);

    double targetMps;
    if (!isLiveMoving.value && _lastReportedSpeedKmh <= 0) {
      // Parked: settle on the point.
      targetMps = math.max(1.0, remainingMeters / 1.5);
    } else if (timeLeft > creepTau) {
      targetMps = remainingMeters / timeLeft;
    } else {
      // Late point: slow creep (remaining distance shrinks gradually).
      targetMps = remainingMeters / creepTau;
    }
    targetMps = targetMps.clamp(0.0, 45.0);

    // Smooth speed change
    final alpha = 1.0 - math.exp(-dt / 0.35);
    _currentLiveSpeedMs += (targetMps - _currentLiveSpeedMs) * alpha;

    double distanceBudget = _currentLiveSpeedMs * dt;

    // Advance along waypoint queue
    while (distanceBudget > 0 &&
        _liveWaypointIndex < _liveWaypoints.length - 1) {
      final a = _liveWaypoints[_liveWaypointIndex];
      final b = _liveWaypoints[_liveWaypointIndex + 1];
      final segMeters = _calculateDistance(a, b);
      if (segMeters <= 1e-4) {
        _liveWaypointIndex++;
        _liveWaypointFraction = 0.0;
        continue;
      }
      final currentT = _liveWaypointFraction.clamp(0.0, 1.0);
      final remainingSeg = segMeters * (1.0 - currentT);
      if (distanceBudget >= remainingSeg) {
        distanceBudget -= remainingSeg;
        _liveWaypointIndex++;
        _liveWaypointFraction = 0.0;
      } else {
        _liveWaypointFraction = (currentT + distanceBudget / segMeters).clamp(
          0.0,
          1.0,
        );
        distanceBudget = 0.0;
      }
    }

    // Interpolate marker position & bearing
    if (_liveWaypointIndex >= _liveWaypoints.length - 1) {
      final dest = _liveWaypoints.last;
      liveMarkerPosition.value = dest;
      if (isLiveLocked.value) {
        _followLiveCamera(dest);
      }
    } else {
      final a = _liveWaypoints[_liveWaypointIndex];
      final b = _liveWaypoints[_liveWaypointIndex + 1];
      final t = _liveWaypointFraction.clamp(0.0, 1.0);
      final interpolated = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      liveMarkerPosition.value = interpolated;

      // Heading = direction of travel. Very short road segments (< 2 m, from
      // road snapping) can point backwards, so they don't change the heading.
      // Only while actually driving: a parked car keeps the direction it
      // was driving in (it used to turn across the road on GPS drift).
      final driving = isLiveMoving.value || _lastReportedSpeedKmh > 0;
      if (driving && _calculateDistance(a, b) >= 3.0) {
        _liveHeadingKnown = true;
        // Face a point ~15 m ahead on the path, not just this tiny segment,
        // so small zig-zags of the road geometry don't turn the car sideways.
        final targetBearing = _getBearing(
          interpolated,
          _pointAheadOnPath(15.0) ?? b,
        );
        final smooth = 1.0 - math.exp(-dt / 0.15);
        liveMarkerBearing.value = _lerpBearing(
          liveMarkerBearing.value,
          targetBearing,
          smooth,
        );
      }

      if (isLiveLocked.value) {
        _followLiveCamera(interpolated);
      }
    }

    // Memory cleanup: trim passed waypoints
    if (_liveWaypointIndex > 30) {
      final keepFrom = _liveWaypointIndex;
      _liveWaypoints.removeRange(0, keepFrom);
      _liveWaypointIndex = 0;
    }
  }

  void _followLiveCamera(LatLng point) {
    if (!isLiveLocked.value) return;
    try {
      var zoom = 16.0;
      try {
        zoom = liveMapController.camera.zoom;
      } catch (_) {}
      if (zoom < 13.0) zoom = 16.0;

      liveMapController.move(point, zoom);
    } catch (_) {}
  }

  Future<void> _requestRoadPath(LatLng from, LatLng to) async {
    if (_calculateDistance(from, to) < 3.0 || _roadFetchInFlight) return;
    _roadFetchInFlight = true;
    final int session = _liveSessionId;
    try {
      final road = await _directionsService.getRoute(from, to, smooth: false);
      if (_liveDisposed || session != _liveSessionId || road.length < 2) return;

      // Reject detours (one-way / wrong-side snapping) that would send the
      // marker far away and back, which looks like a jump.
      final straight = _calculateDistance(from, to);
      // Tight rule: a short hop must not become a loop (toll plazas,
      // junctions, divided roads gave U-turn routes that made the car drive
      // sideways / backwards and look stopped across the road).
      if (_polylineLengthMeters(road) > straight * 1.5 + 30.0) return;

      // FIX: locate the exact from→to segment still in the queue. The old
      // code replaced the whole queue from the marker's current index and
      // kept the old fraction on a different segment, so the marker skipped
      // ahead to the new road start.
      int seg = -1;
      for (int i = _liveWaypoints.length - 2; i >= 0; i--) {
        if (_calculateDistance(_liveWaypoints[i], from) < 1.0 &&
            _calculateDistance(_liveWaypoints[i + 1], to) < 1.0) {
          seg = i;
          break;
        }
      }
      if (seg < 0 || seg < _liveWaypointIndex) return; // already passed

      // Road geometry between the two fixes (endpoints are the fixes themselves).
      final interior = <LatLng>[];
      for (int i = 1; i < road.length - 1; i++) {
        final p = road[i];
        if (_calculateDistance(p, from) < 1.0 ||
            _calculateDistance(p, to) < 1.0) {
          continue;
        }
        if (interior.isEmpty || _calculateDistance(interior.last, p) >= 0.6) {
          interior.add(p);
        }
      }

      if (seg > _liveWaypointIndex) {
        // Marker hasn't reached this segment yet: splice road in place.
        // Index and fraction stay valid, so there is no visual jump.
        if (interior.isNotEmpty) {
          _liveWaypoints.insertAll(seg + 1, interior);
        }
        return;
      }

      // Marker is currently on this segment: continue from where it is now.
      final currentPos = liveMarkerPosition.value ?? from;
      final roadNoEnd = road.length > 2
          ? road.sublist(0, road.length - 1)
          : road;
      final ahead = _trimRouteAhead(
        currentPos,
        roadNoEnd,
      ).where((p) => _calculateDistance(p, to) >= 1.0).toList();
      final head = _liveWaypoints.sublist(0, seg);
      final tail = _liveWaypoints.sublist(seg + 1); // starts with `to`
      _liveWaypoints
        ..clear()
        ..addAll([...head, currentPos, ...ahead, ...tail]);
      _liveWaypointIndex = head.length;
      _liveWaypointFraction = 0.0;
    } catch (e) {
      debugPrint('[LiveTrack] Road fetch error: $e');
    } finally {
      _roadFetchInFlight = false;
    }
  }

  double _polylineLengthMeters(List<LatLng> pts) {
    double total = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      total += _calculateDistance(pts[i], pts[i + 1]);
    }
    return total;
  }

  List<LatLng> _trimRouteAhead(LatLng from, List<LatLng> route) {
    if (route.isEmpty) return route;
    if (route.length == 1) return List<LatLng>.from(route);

    // FIX: pick the closest point on any segment (not just the segment after
    // the closest vertex), so the projected start never lands ahead of the car.
    var bestSeg = 0;
    var bestDist = double.infinity;
    var bestPoint = route.first;
    for (var i = 0; i < route.length - 1; i++) {
      final p = _projectOnSegment(from, route[i], route[i + 1]);
      final d = _calculateDistance(from, p);
      if (d < bestDist) {
        bestDist = d;
        bestSeg = i;
        bestPoint = p;
      }
    }

    final out = <LatLng>[bestPoint];
    for (var i = bestSeg + 1; i < route.length; i++) {
      if (_calculateDistance(out.last, route[i]) >= 0.6) {
        out.add(route[i]);
      }
    }
    return out;
  }

  LatLng _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;
    final dx = bx - ax;
    final dy = by - ay;
    if (dx == 0 && dy == 0) return a;
    final t = (((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)).clamp(
      0.0,
      1.0,
    );
    return LatLng(ay + dy * t, ax + dx * t);
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const radius = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180) *
            math.cos(p2.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radius * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  void recenterLiveMap() {
    isLiveLocked.value = true;
    final pt =
        liveMarkerPosition.value ??
        (vehicleDetail.value.latitude != null &&
                vehicleDetail.value.longitude != null
            ? LatLng(
                vehicleDetail.value.latitude!,
                vehicleDetail.value.longitude!,
              )
            : null);
    if (pt != null) {
      _followLiveCamera(pt);
    }
  }

  void zoomInLiveMap() => _zoomLive(1.0);

  void zoomOutLiveMap() => _zoomLive(-1.0);

  /// + / - buttons: zoom around the car while following it (so it never
  /// leaves the screen), around the map centre otherwise.
  void _zoomLive(double step) {
    try {
      final cam = liveMapController.camera;
      final car = liveMarkerPosition.value;
      final center = (isLiveLocked.value && car != null) ? car : cam.center;
      liveMapController.move(center, (cam.zoom + step).clamp(3.0, 19.0));
    } catch (_) {}
  }

  double? _lastLiveCamZoom;

  /// Map moved. A finger DRAG (pan) stops following the vehicle; a PINCH /
  /// double-tap ZOOM keeps following it (zooming on the phone used to stop
  /// following, so the car drove off the screen).
  // `camera` is MapPosition (flutter_map 6) or MapCamera (7+); both have zoom.
  void onLiveCameraChanged(dynamic camera, bool hasGesture) {
    final prevZoom = _lastLiveCamZoom;
    final zoom = (camera.zoom as num?)?.toDouble();
    if (zoom != null) _lastLiveCamZoom = zoom;
    if (!hasGesture || !isLiveLocked.value) return;
    final zooming =
        prevZoom != null && zoom != null && (zoom - prevZoom).abs() > 0.001;
    if (zooming) {
      // Keep the car in the centre while zooming.
      final car = liveMarkerPosition.value;
      if (car != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            liveMapController.move(car, liveMapController.camera.zoom);
          } catch (_) {}
        });
      }
      return;
    }
    isLiveLocked.value = false; // panned away by hand
  }

  void stopLiveTracking() {
    // Invalidate any in-flight start/poll/road request so it can't restart
    // timers or the socket after the user left the live tab.
    _liveSessionId++;
    _liveTrackingImei = null;
    _stopLiveAnimationLoop();
    _stopLivePollingTimer();
    unawaited(_liveTrackWs.disconnect());
    isLiveTrackingConnected.value = false;
  }
}
