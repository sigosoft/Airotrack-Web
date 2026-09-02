class VehicleStatusSummary {
  final String title;
  final int count;
  final int colorHex;
  final int lightBgHex;

  VehicleStatusSummary({
    required this.title,
    required this.count,
    required this.colorHex,
    required this.lightBgHex,
  });
}

class VehicleItem {
  final String registrationNumber;
  final String status;
  final bool isSelected;

  VehicleItem({
    required this.registrationNumber,
    this.status = 'Running',
    this.isSelected = false,
  });
}

class EngineHourDataPoint {
  final String date;
  final double hours;

  EngineHourDataPoint({required this.date, required this.hours});
}

class TravelDistanceDataPoint {
  final String date;
  final double distanceKm;
  final double maxKm;

  TravelDistanceDataPoint({
    required this.date,
    required this.distanceKm,
    this.maxKm = 144.0,
  });
}

class DashboardModel {
  final String userName;
  final List<VehicleStatusSummary> summaryList;
  final List<VehicleItem> vehicleList;
  final List<EngineHourDataPoint> engineHoursData;
  final List<TravelDistanceDataPoint> travelDistanceData;

  DashboardModel({
    this.userName = 'John Doe',
    required this.summaryList,
    required this.vehicleList,
    required this.engineHoursData,
    required this.travelDistanceData,
  });
}
