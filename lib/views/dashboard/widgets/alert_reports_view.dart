import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/dashboard_controller.dart';
import '../../../services/app_settings.dart';
import '../../../utils/report_exporter.dart';

/// Reports > Alert Reports (GET reports/alerts), like the mobile app's
/// Alert Reports: one vehicle, a date range, every alert it raised.
/// The API returns all rows at once, so paging and the alert-type filter
/// happen here.
class AlertReportsView extends StatefulWidget {
  const AlertReportsView({super.key});

  @override
  State<AlertReportsView> createState() => _AlertReportsViewState();
}

class _AlertReportsViewState extends State<AlertReportsView> {
  static const int _pageSize = 10;
  int _page = 1;
  String _type = ''; // '' = all alert types

  DashboardController get controller => Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    controller.fetchAlertReports();
  }

  void _reload() {
    setState(() {
      _page = 1;
      _type = '';
    });
    controller.fetchAlertReports();
  }

  List<Map<String, dynamic>> get _filtered => _type.isEmpty
      ? controller.alertReports.toList()
      : controller.alertReports.where((r) => r['alert'] == _type).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                child: Obx(() {
                  // Rebuild on unit / time format changes too.
                  AppSettings.to.use24HourTime.value;
                  if (controller.isAlertReportLoading.value) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00A3E0),
                        ),
                      ),
                    );
                  }
                  final rows = _filtered;
                  if (rows.isEmpty) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(
                          'No alert reports found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    );
                  }
                  final totalPages = (rows.length / _pageSize).ceil();
                  final page = _page.clamp(1, totalPages);
                  final start = (page - 1) * _pageSize;
                  final pageRows = rows.sublist(
                    start,
                    (start + _pageSize).clamp(0, rows.length),
                  );
                  final total = controller.alertReportTotal.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _type.isEmpty && total > rows.length
                            ? 'Showing the latest ${rows.length} of $total alerts'
                            : '${rows.length} alerts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pageRows.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: c.maxWidth < 768 ? 1 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 104,
                              ),
                          itemBuilder: (_, i) => _card(pageRows[i]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (totalPages > 1) _pager(page, totalPages),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final filters = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Obx(() => _vehicleDropdown()),
            Obx(() => _typeDropdown()),
          ],
        );
        final dates = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Obx(() => _dateBox(context, controller.reportStartDate.value, true)),
            Obx(() => _dateBox(context, controller.reportEndDate.value, false)),
            _exportButton(),
          ],
        );
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 16 : 24,
            vertical: 10,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [filters, const SizedBox(height: 8), dates],
                )
              : Row(children: [filters, const Spacer(), dates]),
        );
      },
    );
  }

  Widget _box({required Widget child, double? width}) => Container(
    width: width,
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _vehicleDropdown() {
    final vehicles = controller.homeController.vehicles;
    if (vehicles.isEmpty) {
      return _box(
        width: 220,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No vehicles',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF98A2B3)),
          ),
        ),
      );
    }
    final idx = controller.selectedVehicleIndex.value < vehicles.length
        ? controller.selectedVehicleIndex.value
        : 0;
    return _box(
      width: 220,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: idx,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF344054)),
          items: [
            for (var i = 0; i < vehicles.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  vehicles[i].plateNumber,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (i) {
            if (i == null) return;
            controller.selectedVehicleIndex.value = i;
            controller.selectedVehicleImei.value = vehicles[i].deviceId;
            _reload();
          },
        ),
      ),
    );
  }

  Widget _typeDropdown() {
    final types = <String, String>{};
    for (final r in controller.alertReports) {
      types.putIfAbsent(r['alert'].toString(), () => r['event'].toString());
    }
    final sorted = types.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return _box(
      width: 200,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: types.containsKey(_type) ? _type : '',
          icon: const Icon(Icons.filter_list_rounded, size: 18),
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF344054)),
          items: [
            const DropdownMenuItem(value: '', child: Text('All Alerts')),
            for (final e in sorted)
              DropdownMenuItem(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() {
            _type = v ?? '';
            _page = 1;
          }),
        ),
      ),
    );
  }

  Widget _exportButton() => InkWell(
    onTap: () => ReportExporter.exportAlertReport(
      items: _filtered,
      startDate: controller.reportStartDate.value,
      endDate: controller.reportEndDate.value,
    ),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: const Icon(
        Icons.description_outlined,
        size: 20,
        color: Color(0xFFF59E0B),
      ),
    ),
  );

  static ({IconData icon, Color color}) _style(String alert) {
    final a = alert.toLowerCase();
    if (a.contains('ignitionon')) {
      return (icon: Icons.key_rounded, color: const Color(0xFF12B76A));
    }
    if (a.contains('ignitionoff')) {
      return (icon: Icons.key_off_rounded, color: const Color(0xFFF04438));
    }
    if (a.contains('speed')) {
      return (icon: Icons.speed_rounded, color: const Color(0xFFF79009));
    }
    if (a.contains('geofence') || a.contains('fence')) {
      return (icon: Icons.fence_rounded, color: const Color(0xFF7A5AF8));
    }
    if (a.contains('power') || a.contains('wire') || a.contains('battery')) {
      return (icon: Icons.power_rounded, color: const Color(0xFFF04438));
    }
    return (
      icon: Icons.notifications_active_outlined,
      color: const Color(0xFF00A3E0),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final s = _style(item['alert']?.toString() ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(s.icon, size: 18, color: s.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['event']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2939),
                        ),
                      ),
                    ),
                    Text(
                      item['vehicle']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475467),
                      ),
                    ),
                  ],
                ),
                Text(
                  item['content']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475467),
                    height: 1.25,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF98A2B3),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppSettings.to.dateTime(
                        item['datetime']?.toString(),
                        seconds: true,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pager(int page, int totalPages) {
    // A window of up to 7 page numbers around the current page.
    var first = (page - 3).clamp(1, totalPages);
    final last = (first + 6).clamp(1, totalPages);
    first = (last - 6).clamp(1, totalPages);
    Widget num(int i) => InkWell(
      onTap: () => setState(() => _page = i),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: page == i ? const Color(0xFF00A3E0) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$i',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: page == i ? Colors.white : const Color(0xFF344054),
          ),
        ),
      ),
    );
    Widget link(String label, int target) => InkWell(
      onTap: () => setState(() => _page = target),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00A3E0),
          ),
        ),
      ),
    );
    return Center(
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (page > 1) link('PREV', page - 1),
          for (var i = first; i <= last; i++) num(i),
          if (page < totalPages) link('NEXT', page + 1),
        ],
      ),
    );
  }

  Widget _dateBox(BuildContext context, String dateStr, bool isStart) {
    return InkWell(
      onTap: () async {
        final current = AppSettings.parseDateTime(dateStr) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: current,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF00A3E0),
                onPrimary: Colors.white,
                onSurface: Color(0xFF1D2939),
              ),
            ),
            child: child!,
          ),
        );
        if (picked == null) return;
        String two(int v) => v.toString().padLeft(2, '0');
        final d = '${two(picked.day)}-${two(picked.month)}-${picked.year}';
        DateTime day(String s) {
          final p = AppSettings.parseDateTime(s) ?? DateTime.now();
          return DateTime(p.year, p.month, p.day);
        }

        if (isStart) {
          controller.reportStartDate.value = '$d 12:00 AM';
          if (picked.isAfter(day(controller.reportEndDate.value))) {
            controller.reportEndDate.value = '$d 11:59 PM';
          }
        } else {
          controller.reportEndDate.value = '$d 11:59 PM';
          if (picked.isBefore(day(controller.reportStartDate.value))) {
            controller.reportStartDate.value = '$d 12:00 AM';
          }
        }
        _reload();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 15,
              color: Color(0xFF667085),
            ),
            const SizedBox(width: 6),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
