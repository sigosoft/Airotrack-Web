import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/reminder_controller.dart';
import '../../../models/reminder_model.dart';
import '../../../utils/app_toast.dart';

/// Add Reminder (add_vehicle_reminder) or, with [existing], Edit Reminder
/// (update_vehicle_reminder).
class CreateReminderDialog extends StatefulWidget {
  final ReminderItem? existing;

  const CreateReminderDialog({super.key, this.existing});

  @override
  State<CreateReminderDialog> createState() => _CreateReminderDialogState();
}

class _CreateReminderDialogState extends State<CreateReminderDialog> {
  final ReminderController controller = Get.find<ReminderController>();

  String? selectedVehicle;
  String? selectedType;
  final TextEditingController startOdometerController = TextEditingController();
  final TextEditingController periodController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      selectedVehicle = e.vehicleNumber.isEmpty ? null : e.vehicleNumber;
      selectedType = e.typeKey.isEmpty ? null : e.typeKey;
      startOdometerController.text = ReminderItem.formatNum(e.startOdometer);
      periodController.text = ReminderItem.formatNum(e.periodKm);
      remarksController.text = e.remarks;
    } else {
      selectedVehicle = controller.currentVehicleNumber;
    }
  }

  @override
  void dispose() {
    startOdometerController.dispose();
    periodController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (selectedVehicle == null || selectedVehicle!.isEmpty) {
      AppToast.show('Please select a vehicle', isError: true);
      return;
    }
    if (selectedType == null) {
      AppToast.show('Please select a reminder type', isError: true);
      return;
    }
    final start = startOdometerController.text.trim();
    final period = periodController.text.trim();
    if (start.isEmpty || num.tryParse(start) == null) {
      AppToast.show('Please enter the starting odometer', isError: true);
      return;
    }
    if (period.isEmpty || (num.tryParse(period) ?? 0) <= 0) {
      AppToast.show('Please enter the odometer period', isError: true);
      return;
    }
    final ok = await controller.saveReminder(
      id: widget.existing?.id,
      vehicleNumber: selectedVehicle!,
      type: selectedType!,
      startOdometer: start,
      period: period,
      remarks: remarksController.text.trim(),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Title & Close 'X' Icon Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Reminder' : 'Add Reminder',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F4F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Vehicle Dropdown (vehicles API)
              _label('Select Vehicle'),
              const SizedBox(height: 6),
              Obx(() {
                final options = controller.vehicles
                    .map((v) => v.vehicleNumber)
                    .toList();
                if (selectedVehicle != null &&
                    !options.contains(selectedVehicle)) {
                  options.insert(0, selectedVehicle!);
                }
                return _dropdown(
                  hint: 'Select Vehicle',
                  value: selectedVehicle,
                  items: {for (final o in options) o: o},
                  onChanged: (v) => setState(() => selectedVehicle = v),
                );
              }),
              const SizedBox(height: 16),

              // 3. Select Type Dropdown (reminder_types API)
              _label('Select Type'),
              const SizedBox(height: 6),
              Obx(() {
                final items = {
                  for (final t in controller.reminderTypes) t.key: t.label,
                };
                if (selectedType != null &&
                    !items.containsKey(selectedType) &&
                    widget.existing != null) {
                  items[selectedType!] = widget.existing!.typeLabel;
                }
                return _dropdown(
                  hint: 'Select Reminder Type',
                  value: selectedType,
                  items: items,
                  onChanged: (v) => setState(() => selectedType = v),
                );
              }),
              const SizedBox(height: 16),

              // 4. Start Input Field
              _label('Start'),
              const SizedBox(height: 6),
              _textField(
                controller: startOdometerController,
                hint: 'Enter Starting Odometer',
                numeric: true,
              ),
              const SizedBox(height: 16),

              // 5. Period Input Field
              _label('Period'),
              const SizedBox(height: 6),
              _textField(
                controller: periodController,
                hint: 'Enter the Odometer Period for Alerts',
                numeric: true,
              ),
              const SizedBox(height: 16),

              // 6. Remarks (optional)
              _label('Remarks'),
              const SizedBox(height: 6),
              _textField(
                controller: remarksController,
                hint: 'Enter Remarks (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // 7. Bottom Action Buttons Row (Cancel vs Submit)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFD0D5DD),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isSaving.value ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A3E0),
                            disabledBackgroundColor: const Color(0xFF7FD1EF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isSaving.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF344054),
    ),
  );

  Widget _dropdown({
    required String hint,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
          ),
          value: items.containsKey(value) ? value : null,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0xFF0288D1),
            size: 26,
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF344054),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00A3E0), width: 1.5),
        ),
      ),
    );
  }
}
