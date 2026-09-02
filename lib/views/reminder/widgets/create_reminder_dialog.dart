import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_toast.dart';

class CreateReminderDialog extends StatefulWidget {
  const CreateReminderDialog({super.key});

  @override
  State<CreateReminderDialog> createState() => _CreateReminderDialogState();
}

class _CreateReminderDialogState extends State<CreateReminderDialog> {
  String? selectedType;
  final TextEditingController startOdometerController = TextEditingController();
  final TextEditingController periodController = TextEditingController();

  final typeOptions = [
    'Oil Change',
    'Tire Rotation',
    'Insurance Renewal',
    'General Service',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Title & Close 'X' Icon Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Reminder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
                InkWell(
                  onTap: () => Get.back(),
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

            // 2. Select Type Dropdown
            const Text(
              'Select Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            Container(
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
                  hint: const Text(
                    'Select Reminder Type',
                    style: TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
                  ),
                  value: selectedType,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Color(0xFF0288D1),
                    size: 26,
                  ),
                  items: typeOptions.map((t) {
                    return DropdownMenuItem<String>(
                      value: t,
                      child: Text(
                        t,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedType = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Start Input Field (Single Seamless Box)
            const Text(
              'Start',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: startOdometerController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
              decoration: InputDecoration(
                hintText: 'Enter Starting Odometer',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            ),
            const SizedBox(height: 16),

            // 4. Period Input Field (Single Seamless Box)
            const Text(
              'Period',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: periodController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
              decoration: InputDecoration(
                hintText: 'Enter the Odometer Period for Alerts',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            ),
            const SizedBox(height: 24),

            // 5. Bottom Action Buttons Row (Cancel vs Submit)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
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
                    child: ElevatedButton(
                      onPressed: () {
                        AppToast.show('Reminder created successfully');
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
