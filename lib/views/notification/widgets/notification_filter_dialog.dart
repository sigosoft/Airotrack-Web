import 'package:flutter/material.dart';

import '../../../controllers/notification_controller.dart';

/// Notifications > Filter: Event Types and Vehicles, as on the mobile app's
/// filter sheet (dates are picked in the header).
class NotificationFilterDialog extends StatefulWidget {
  final NotificationController controller;
  const NotificationFilterDialog({super.key, required this.controller});

  @override
  State<NotificationFilterDialog> createState() =>
      _NotificationFilterDialogState();
}

class _NotificationFilterDialogState extends State<NotificationFilterDialog> {
  static const _blue = Color(0xFF00A3E0);
  int _tab = 0; // 0 = Event Types, 1 = Vehicles
  late Set<String> _events;
  late Set<String> _vehicles;
  String _vehicleQuery = '';

  NotificationController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    // Nothing selected on the page means "all": start with every box ticked.
    _events = c.selectedEventTypes.isEmpty
        ? c.eventTypeOptions.toSet()
        : c.selectedEventTypes.toSet();
    _vehicles = c.selectedVehicles.isEmpty
        ? c.vehicleOptions.toSet()
        : c.selectedVehicles.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final options = _tab == 0
        ? c.eventTypeOptions
        : c.vehicleOptions
              .where(
                (v) => v.toLowerCase().contains(_vehicleQuery.toLowerCase()),
              )
              .toList();
    final selected = _tab == 0 ? _events : _vehicles;
    final allLabel = _tab == 0 ? 'All Events' : 'All Vehicles';
    final allOn = options.isNotEmpty && options.every(selected.contains);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 80,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _tabButton('Event Types', 0),
                const SizedBox(width: 8),
                _tabButton('Vehicles', 1),
              ],
            ),
            const SizedBox(height: 12),
            if (_tab == 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _vehicleQuery = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search Vehicles',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFEAECF0)),
                    ),
                  ),
                ),
              ),
            _check(
              allLabel,
              allOn,
              () => setState(() {
                if (allOn) {
                  selected.removeAll(options);
                } else {
                  selected.addAll(options);
                }
              }),
              bold: true,
            ),
            const Divider(height: 12),
            Flexible(
              child: options.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nothing to filter yet',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final o in options)
                          _check(
                            o,
                            selected.contains(o),
                            () => setState(() {
                              if (!selected.remove(o)) selected.add(o);
                            }),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      c.clearFilters();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Color(0xFF344054)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      c.applyFilters(eventTypes: _events, vehicles: _vehicles);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: _blue,
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final on = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: on ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? _blue : const Color(0xFFE4E7EC)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: on ? Colors.white : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }

  Widget _check(
    String label,
    bool value,
    VoidCallback onTap, {
    bool bold = false,
  }) => InkWell(
    onTap: onTap,
    child: Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (_) => onTap(),
          activeColor: _blue,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF344054),
            ),
          ),
        ),
      ],
    ),
  );
}
