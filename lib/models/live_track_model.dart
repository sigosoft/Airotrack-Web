class LiveTrackSnapshotModel {
  final bool? status;
  final String? message;
  final LiveTrackSnapshotData? data;

  LiveTrackSnapshotModel({
    this.status,
    this.message,
    this.data,
  });

  factory LiveTrackSnapshotModel.fromJson(Map<String, dynamic> json) {
    return LiveTrackSnapshotModel(
      status: json['status'] is bool
          ? json['status'] as bool
          : json['status']?.toString() == 'true',
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? LiveTrackSnapshotData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LiveTrackSnapshotData {
  final LiveVehicleInfo? vehicleInfo;
  final LiveCurrentPosition? currentPosition;
  final LiveTodayStatistics? todayStatistics;
  final LiveWebsocketInfo? websocket;
  final LiveWebsocketConfig? websocketConfig;

  LiveTrackSnapshotData({
    this.vehicleInfo,
    this.currentPosition,
    this.todayStatistics,
    this.websocket,
    this.websocketConfig,
  });

  factory LiveTrackSnapshotData.fromJson(Map<String, dynamic> json) {
    return LiveTrackSnapshotData(
      vehicleInfo: json['vehicle_info'] is Map<String, dynamic>
          ? LiveVehicleInfo.fromJson(json['vehicle_info'] as Map<String, dynamic>)
          : null,
      currentPosition: json['current_position'] is Map<String, dynamic>
          ? LiveCurrentPosition.fromJson(
              json['current_position'] as Map<String, dynamic>)
          : null,
      todayStatistics: json['today_statistics'] is Map<String, dynamic>
          ? LiveTodayStatistics.fromJson(
              json['today_statistics'] as Map<String, dynamic>)
          : null,
      websocket: json['websocket'] is Map<String, dynamic>
          ? LiveWebsocketInfo.fromJson(json['websocket'] as Map<String, dynamic>)
          : null,
      websocketConfig: json['websocket_config'] is Map<String, dynamic>
          ? LiveWebsocketConfig.fromJson(
              json['websocket_config'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get hasWebSocketConnectionConfig {
    final url = websocketConfig?.websocketUrl;
    final key = websocketConfig?.appKey;
    return url != null && url.isNotEmpty && key != null && key.isNotEmpty;
  }

  String? channelFor(String imei) {
    if (websocket?.channel != null && websocket!.channel!.isNotEmpty) {
      return websocket!.channel!.replaceAll('{imei}', imei);
    }
    return 'device.$imei';
  }

  String? eventNameFor() {
    if (websocket?.eventName != null && websocket!.eventName!.isNotEmpty) {
      return websocket!.eventName;
    }
    return 'device.update';
  }

  LiveTrackData toLiveTrackData() {
    return LiveTrackData(
      vehicleInfo: vehicleInfo,
      currentPosition: currentPosition,
      currentStatus: currentPosition?.derivedStatus,
      todayStatistics: todayStatistics,
    );
  }
}

class LiveWebsocketConfig {
  final String? websocketUrl;
  final String? appKey;
  final int? port;
  final String? host;
  final String? scheme;

  LiveWebsocketConfig({
    this.websocketUrl,
    this.appKey,
    this.port,
    this.host,
    this.scheme,
  });

  factory LiveWebsocketConfig.fromJson(Map<String, dynamic> json) {
    return LiveWebsocketConfig(
      websocketUrl: json['websocket_url']?.toString() ??
          json['ws_url']?.toString() ??
          json['url']?.toString(),
      appKey: json['app_key']?.toString() ?? json['key']?.toString(),
      port: json['port'] is int
          ? json['port'] as int
          : int.tryParse(json['port']?.toString() ?? ''),
      host: json['host']?.toString(),
      scheme: json['scheme']?.toString(),
    );
  }
}

class LiveWebsocketInfo {
  final String? channel;
  final String? eventName;

  LiveWebsocketInfo({
    this.channel,
    this.eventName,
  });

  factory LiveWebsocketInfo.fromJson(Map<String, dynamic> json) {
    return LiveWebsocketInfo(
      channel: json['channel']?.toString(),
      eventName: json['event']?.toString() ?? json['event_name']?.toString(),
    );
  }
}

class LiveCurrentPosition {
  final String? imei;
  final String? latitude;
  final String? longitude;
  final double? speed;
  final String? deviceTime;
  final int? ignition;
  final int? power;
  final String? mode;
  final String? kilometer;
  final num? odometer;
  final String? altitude;
  final String? gsmSignalStrength;
  final String? network;
  final String? lastUpdate;
  final double? course;

  LiveCurrentPosition({
    this.imei,
    this.latitude,
    this.longitude,
    this.speed,
    this.deviceTime,
    this.ignition,
    this.power,
    this.mode,
    this.kilometer,
    this.odometer,
    this.altitude,
    this.gsmSignalStrength,
    this.network,
    this.lastUpdate,
    this.course,
  });

  factory LiveCurrentPosition.fromJson(Map<String, dynamic> json) {
    final rawSpeed = json['speed'];
    final speedVal = rawSpeed is num
        ? rawSpeed.toDouble()
        : double.tryParse(rawSpeed?.toString() ?? '');

    final rawCourse = json['course'] ??
        json['angle'] ??
        json['heading'] ??
        json['direction'];
    final courseVal = rawCourse is num
        ? rawCourse.toDouble()
        : double.tryParse(rawCourse?.toString() ?? '');

    return LiveCurrentPosition(
      imei: json['imei']?.toString(),
      latitude: (json['latitude'] ?? json['lat'])?.toString(),
      longitude: (json['longitude'] ?? json['lng'] ?? json['lon'])?.toString(),
      speed: speedVal,
      deviceTime: json['devicetime']?.toString() ?? json['device_time']?.toString(),
      ignition: json['ignition'] is int
          ? json['ignition'] as int
          : int.tryParse(json['ignition']?.toString() ?? ''),
      power: json['power'] is int
          ? json['power'] as int
          : int.tryParse(json['power']?.toString() ?? ''),
      mode: json['mode']?.toString(),
      kilometer: json['kilometer']?.toString(),
      odometer: json['odometer'] is num
          ? json['odometer'] as num
          : num.tryParse(json['odometer']?.toString() ?? ''),
      altitude: json['altitude']?.toString(),
      gsmSignalStrength: json['gsm_signal_strength']?.toString(),
      network: json['network']?.toString(),
      lastUpdate: json['last_update']?.toString(),
      course: courseVal,
    );
  }

  bool get isIgnitionOn => ignition == 1;
  bool get isPowerOn => power == 1;

  String get derivedStatus {
    if (speed != null && speed! > 0) {
      return 'Running';
    }
    if (isIgnitionOn) {
      return 'Idle';
    }
    return 'Stopped';
  }
}

class LiveVehicleInfo {
  final int? id;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? totalKilometersTraveled;

  LiveVehicleInfo({
    this.id,
    this.vehicleNumber,
    this.vehicleType,
    this.totalKilometersTraveled,
  });

  factory LiveVehicleInfo.fromJson(Map<String, dynamic> json) {
    return LiveVehicleInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      vehicleNumber: json['vehicle_number']?.toString() ?? json['plate_number']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      totalKilometersTraveled: json['total_kilometers_traveled']?.toString(),
    );
  }
}

class LiveTodayStatistics {
  final double? totalKilometersToday;
  final double? avgSpeed;
  final double? maxSpeed;
  final String? displayStoppedDuration;
  final String? displayIdleDuration;
  final String? displayRunningDuration;
  final String? displayInactiveDuration;

  LiveTodayStatistics({
    this.totalKilometersToday,
    this.avgSpeed,
    this.maxSpeed,
    this.displayStoppedDuration,
    this.displayIdleDuration,
    this.displayRunningDuration,
    this.displayInactiveDuration,
  });

  factory LiveTodayStatistics.fromJson(Map<String, dynamic> json) {
    return LiveTodayStatistics(
      totalKilometersToday: (json['total_kilometers_today'] is num)
          ? (json['total_kilometers_today'] as num).toDouble()
          : double.tryParse(json['total_kilometers_today']?.toString() ?? ''),
      avgSpeed: (json['avg_speed'] is num)
          ? (json['avg_speed'] as num).toDouble()
          : double.tryParse(json['avg_speed']?.toString() ?? ''),
      maxSpeed: (json['max_speed'] is num)
          ? (json['max_speed'] as num).toDouble()
          : double.tryParse(json['max_speed']?.toString() ?? ''),
      displayStoppedDuration: json['stopped_duration']?.toString() ?? '00:00:00',
      displayIdleDuration: json['idle_duration']?.toString() ?? '00:00:00',
      displayRunningDuration: json['running_duration']?.toString() ?? '00:00:00',
      displayInactiveDuration: json['inactive_duration']?.toString() ?? '00:00:00',
    );
  }
}

class LiveTrackData {
  final LiveVehicleInfo? vehicleInfo;
  final LiveCurrentPosition? currentPosition;
  final String? currentStatus;
  final LiveTodayStatistics? todayStatistics;

  LiveTrackData({
    this.vehicleInfo,
    this.currentPosition,
    this.currentStatus,
    this.todayStatistics,
  });
}
