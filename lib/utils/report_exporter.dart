import 'app_toast.dart';
import 'download_helper.dart';

class ReportExporter {
  ReportExporter._();

  static String _escape(dynamic val) {
    if (val == null) return '';
    String s = val.toString().trim();
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _buildCsv(List<String> headers, List<List<dynamic>> rows) {
    final sb = StringBuffer();
    sb.writeln(headers.map(_escape).join(','));
    for (final row in rows) {
      sb.writeln(row.map(_escape).join(','));
    }
    return sb.toString();
  }

  static String _cleanFileName(String title, String start, String end) {
    String sanitize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return '${sanitize(title)}_${sanitize(start)}_to_${sanitize(end)}.csv';
  }

  /// 1. Export Ignition Reports
  static void exportIgnitionReport({
    required List<Map<String, dynamic>> items,
    required String startDate,
    required String endDate,
  }) {
    if (items.isEmpty) {
      AppToast.show('No ignition report data to download', isError: true);
      return;
    }

    final headers = [
      'Sl No',
      'Vehicle',
      'Ignition Status',
      'Date & Time',
      'Location',
      'Latitude',
      'Longitude',
    ];

    final rows = <List<dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final isIgn = it['isIgnitionOn'] == true;
      rows.add([
        i + 1,
        it['vehicle'] ?? '',
        isIgn ? 'Ignition ON' : 'Ignition OFF',
        it['timestamp'] ?? it['created_at'] ?? '',
        it['location'] ?? it['address'] ?? '',
        it['latitude'] ?? '',
        it['longitude'] ?? '',
      ]);
    }

    final csv = _buildCsv(headers, rows);
    final fileName = _cleanFileName('Ignition_Report', startDate, endDate);
    downloadCsv(csv, fileName);
    AppToast.show('Ignition report downloaded successfully');
  }

  /// 2. Export Stoppage Reports
  static void exportStoppageReport({
    required List<Map<String, dynamic>> items,
    required String startDate,
    required String endDate,
  }) {
    if (items.isEmpty) {
      AppToast.show('No stoppage report data to download', isError: true);
      return;
    }

    final headers = [
      'Sl No',
      'Vehicle',
      'Stoppage Duration',
      'Start Time',
      'End Time',
      'Location',
      'Latitude',
      'Longitude',
    ];

    final rows = <List<dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      rows.add([
        i + 1,
        it['vehicle'] ?? '',
        it['duration'] ?? '',
        it['startTime'] ?? it['start_time'] ?? '',
        it['endTime'] ?? it['end_time'] ?? '',
        it['location'] ?? it['address'] ?? '',
        it['latitude'] ?? '',
        it['longitude'] ?? '',
      ]);
    }

    final csv = _buildCsv(headers, rows);
    final fileName = _cleanFileName('Stoppage_Report', startDate, endDate);
    downloadCsv(csv, fileName);
    AppToast.show('Stoppage report downloaded successfully');
  }

  /// 3. Export Trip Reports
  static void exportTripReport({
    required List<Map<String, dynamic>> items,
    required String startDate,
    required String endDate,
  }) {
    if (items.isEmpty) {
      AppToast.show('No trip report data to download', isError: true);
      return;
    }

    final headers = [
      'Sl No',
      'Vehicle',
      'Trip',
      'Distance',
      'Duration',
      'Start Time',
      'End Time',
      'Start Location',
      'End Location',
      'Average Speed',
      'Maximum Speed',
    ];

    final rows = <List<dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      rows.add([
        i + 1,
        it['vehicle'] ?? '',
        it['badge'] ?? it['trip'] ?? 'Trip ${i + 1}',
        it['distance'] ?? '',
        it['duration'] ?? '',
        it['startTime'] ?? it['start_time'] ?? '',
        it['endTime'] ?? it['end_time'] ?? '',
        it['startLocation'] ?? it['start_location'] ?? '',
        it['endLocation'] ?? it['end_location'] ?? '',
        it['avgSpeed'] ?? it['avg_speed'] ?? '',
        it['maxSpeed'] ?? it['max_speed'] ?? '',
      ]);
    }

    final csv = _buildCsv(headers, rows);
    final fileName = _cleanFileName('Trip_Report', startDate, endDate);
    downloadCsv(csv, fileName);
    AppToast.show('Trip report downloaded successfully');
  }

  /// 4. Export Summary Reports
  static void exportSummaryReport({
    required List<Map<String, dynamic>> items,
    required String startDate,
    required String endDate,
  }) {
    if (items.isEmpty) {
      AppToast.show('No summary report data to download', isError: true);
      return;
    }

    final headers = [
      'Sl No',
      'Vehicle',
      'Total Distance',
      'Running Duration',
      'Idle Duration',
      'Stopped Duration',
      'Inactive Duration',
      'Average Speed',
      'Maximum Speed',
    ];

    final rows = <List<dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      rows.add([
        i + 1,
        it['vehicle'] ?? '',
        it['distance'] ?? it['total_distance'] ?? '',
        it['runningTime'] ?? it['running_duration'] ?? '',
        it['idleTime'] ?? it['idle_duration'] ?? '',
        it['stopTime'] ?? it['stopped_duration'] ?? '',
        it['inactiveTime'] ?? it['inactive_duration'] ?? '',
        it['avgSpeed'] ?? it['avg_speed'] ?? '',
        it['maxSpeed'] ?? it['max_speed'] ?? '',
      ]);
    }

    final csv = _buildCsv(headers, rows);
    final fileName = _cleanFileName('Summary_Report', startDate, endDate);
    downloadCsv(csv, fileName);
    AppToast.show('Summary report downloaded successfully');
  }

  /// 5. Export Over Speed Reports
  static void exportOverSpeedReport({
    required List<Map<String, dynamic>> items,
    required String startDate,
    required String endDate,
  }) {
    if (items.isEmpty) {
      AppToast.show('No overspeed report data to download', isError: true);
      return;
    }

    final headers = [
      'Sl No',
      'Vehicle',
      'Reported Speed',
      'Speed Limit',
      'Date & Time',
      'Location',
      'Latitude',
      'Longitude',
    ];

    final rows = <List<dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      rows.add([
        i + 1,
        it['vehicle'] ?? '',
        it['speed'] ?? '',
        it['speedLimit'] ?? it['speed_limit'] ?? '',
        it['timestamp'] ?? it['created_at'] ?? '',
        it['location'] ?? it['address'] ?? '',
        it['latitude'] ?? '',
        it['longitude'] ?? '',
      ]);
    }

    final csv = _buildCsv(headers, rows);
    final fileName = _cleanFileName('OverSpeed_Report', startDate, endDate);
    downloadCsv(csv, fileName);
    AppToast.show('Over speed report downloaded successfully');
  }

  /// 6. Export Geofence Reports
  static void exportGeofenceReport({
    required List<Map<String, dynamic>> items,
    required String startDate,
    required String endDate,
  }) {
    if (items.isEmpty) {
      AppToast.show('No geofence report data to download', isError: true);
      return;
    }

    final headers = [
      'Sl No',
      'Vehicle',
      'Geofence Name',
      'Event Type',
      'Date & Time',
      'Location',
      'Latitude',
      'Longitude',
    ];

    final rows = <List<dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      rows.add([
        i + 1,
        it['vehicle'] ?? '',
        it['geofence'] ?? it['geofence_name'] ?? '',
        it['event'] ?? it['geofence_event'] ?? '',
        it['timestamp'] ?? it['created_at'] ?? '',
        it['location'] ?? it['address'] ?? '',
        it['latitude'] ?? '',
        it['longitude'] ?? '',
      ]);
    }

    final csv = _buildCsv(headers, rows);
    final fileName = _cleanFileName('Geofence_Report', startDate, endDate);
    downloadCsv(csv, fileName);
    AppToast.show('Geofence report downloaded successfully');
  }

  /// 7. Export Daily Reports
  static void exportDailyReport({
    required List<Map<String, dynamic>> items,
    required String startDate,
    required String endDate,
  }) {
    if (items.isEmpty) {
      AppToast.show('No daily report data to download', isError: true);
      return;
    }

    final headers = [
      'Sl No',
      'Vehicle',
      'Date',
      'Distance Traveled',
      'Running Time',
      'Idle Time',
      'Stop Time',
      'Max Speed',
      'Average Speed',
    ];

    final rows = <List<dynamic>>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      rows.add([
        i + 1,
        it['vehicle'] ?? '',
        it['date'] ?? it['dateStr'] ?? '',
        it['distance'] ?? it['total_distance'] ?? '',
        it['runningTime'] ?? it['running_duration'] ?? '',
        it['idleTime'] ?? it['idle_duration'] ?? '',
        it['stopTime'] ?? it['stopped_duration'] ?? '',
        it['maxSpeed'] ?? it['max_speed'] ?? '',
        it['avgSpeed'] ?? it['avg_speed'] ?? '',
      ]);
    }

    final csv = _buildCsv(headers, rows);
    final fileName = _cleanFileName('Daily_Report', startDate, endDate);
    downloadCsv(csv, fileName);
    AppToast.show('Daily report downloaded successfully');
  }
}
