import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/reminder_controller.dart';
import 'create_reminder_dialog.dart';

class ReminderHeader extends StatelessWidget {
  const ReminderHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ReminderController controller = Get.find<ReminderController>();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back Arrow + Title
          Row(
            children: [
              InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF1D2939),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Add Reminder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D2939),
                ),
              ),
            ],
          ),

          // Right: Search Vehicles Pill + Add Reminder Button
          Row(
            children: [
              // Search Vehicles Pill Box (Single Seamless Container, No Inner Layers)
              SizedBox(
                width: 320,
                child: TextField(
                  onChanged: (val) => controller.searchQuery.value = val,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF344054),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Vehicles',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A2B3),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF00A3E0), width: 1.5),
                    ),
                    suffixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF98A2B3),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Add Reminder Cyan Button (Triggers CreateReminderDialog)
              SizedBox(
                width: 140,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CreateReminderDialog(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3E0),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Add Reminder',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
