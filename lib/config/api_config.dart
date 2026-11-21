class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://api-dev.airotrack.in/website/';

  /// Public storage for uploaded files (expense / ticket images). The API
  /// returns paths like `expenses/abc.png`; they are served from
  /// `<host>/storage/expenses/abc.png`.
  static String get storageUrl =>
      baseUrl.replaceFirst(RegExp(r'website/?$'), 'storage/');

  /// Full URL for a stored file path from the API (already-full URLs pass through).
  static String? storageFileUrl(dynamic path) {
    final p = (path ?? '').toString().trim();
    if (p.isEmpty || p == 'null') return null;
    if (p.startsWith('http')) return p;
    return '$storageUrl${p.startsWith('/') ? p.substring(1) : p}';
  }
  static String imageUrl =
      "https://ourworks.co.in/saimpex-backend/public/storage/";

  static const String mapboxAccessToken =
      'pk.eyJ1Ijoic2FpbXBleGRldmxvcG1lbnQiLCJhIjoiY21rZXg1ZDA4MGFjZDNqcXptZmN6eXJwYyJ9.MhqmUUhQgPHXj-0nwnz9ww';

  static const String googleMapKey = 'AIzaSyAUlzhkvYVB3FFJH3Cwx7DojTBCgViBMAw';

  static const String googleMapTileUrl =
      'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  static const List<String> googleMapSubdomains = ['0', '1', '2', '3'];
}

class ApiEndPoints {
  static String login = "login";
  static String home = "home";
  static String alerts = "alerts";
  static String alertsReport = "reports/alerts";
  static String profile = "profile";
  static String updateProfile = "update_profile";
  static String changePassword = "changePassword";
  static String deleteAccount = "delete_account";
  static String dashboard = "dashboard";
  static String statistics = "statistics";
  static String vehicleHistory = "track_vehicle";
  static String liveTrack = "live_track";
  static String liveTrackSnapshot = "live_track_snapshot";
  static String updateOdometer = "update_odometer";
  static String addGeofence = "add_geofence";
  static String updateGeofence = "update_geofence";
  static String deleteGeofence = "delete_geofence";
  static String geofences = "geofences";
  static String geofenceSyncedVehicles = "geofence_synced_vehicles";
  static String geofenceUnsyncedVehicles = "geofence_unsynced_vehicles";

  /// Sync selected vehicles onto a geofence: geofence_id + vehicle_ids[]
  static String syncGeofenceVehicles = "sync_geofence_vehicles";

  /// Sync selected geofences onto a vehicle: vehicle_id + geofence_ids[]
  static String syncVehicleGeofences = "sync_vehicle_geofences";
  static String vehicleSyncedGeofences = "vehicle_synced_geofences";
  static String vehicleUnsyncedGeofences = "vehicle_unsynced_geofences";

  /// Linked geofences for a vehicle (full geometry for map display).
  static String vehicleGeofences = "vehicle_geofences";
  static String ignitionReport = "reports/ignition";
  static String stoppageReport = "reports/stoppage";
  static String tripReport = "reports/trip";
  static String dailyReport = "reports/daily";
  static String summaryReport = "reports/summary";
  static String overspeedReport = "reports/overspeed";
  static String geofenceReport = "reports/geofence";

  /// Ends the session on the server (GET, bearer token).
  static String logout = "logout";

  /// Company vehicles: data.vehicles[] {id, vehicle_number, imei}
  static String vehicles = "vehicles";

  // Configure Alerts
  /// data.alerts[] {key, label}
  static String alertTypes = "alert_types";

  /// ?imei= -> data {imei, is_configured, alerts: [key, ...]}
  static String vehicleAlerts = "vehicle_alerts";

  /// POST imei + alerts[] (repeated)
  static String updateVehicleAlerts = "update_vehicle_alerts";

  // Vehicle reminders
  /// data.types[] {key, label}
  static String reminderTypes = "reminder_types";

  /// ?limit&page&keyword&type -> data {reminders[], pagination}
  static String vehicleReminders = "vehicle_reminders";
  static String addVehicleReminder = "add_vehicle_reminder";
  static String viewVehicleReminder = "view_vehicle_reminder";
  static String updateVehicleReminder = "update_vehicle_reminder";
  static String deleteVehicleReminder = "delete_vehicle_reminder";

  // Support tickets
  /// data {types[], statuses[]} each {key, label}
  static String supportTicketOptions = "support_ticket_options";

  /// ?keyword&status&type&period&from_date&to_date&page&limit
  static String supportTickets = "support_tickets";
  static String addSupportTicket = "add_support_ticket";

  // Expenses
  /// data {types[], payment_methods[]} each {key, label}
  static String expenseOptions = "expense_options";

  /// ?keyword&expense_type&payment_method&period&from_date&to_date&page&limit
  /// -> data {total_amount, expenses[], pagination}
  static String expenses = "expenses";
  static String addExpense = "add_expense";
  static String viewExpense = "view_expense";
  static String updateExpense = "update_expense";
  static String deleteExpense = "delete_expense";
}
