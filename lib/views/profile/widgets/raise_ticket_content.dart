import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/profile_controller.dart';

class RaiseTicketContent extends StatelessWidget {
  const RaiseTicketContent({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    final vehicleOptions = [
      'KL 07 D 0518',
      'KL 07 D 0519',
      'KL 07 D 0520',
      'KL 07 D 0521',
    ];

    final typeOptions = [
      'Technical Support',
      'Device Issue',
      'Billing Query',
      'Feature Request',
      'Other',
    ];

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          // Scrollable Form Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title Header
                const Text(
                  'Raise Ticket',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Select Vehicle Dropdown
                const Text(
                  'Select Vehicle',
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text(
                        'Select Vehicle',
                        style: TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF667085),
                      ),
                      items: vehicleOptions.map((v) {
                        return DropdownMenuItem<String>(
                          value: v,
                          child: Text(
                            v,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {},
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Type Dropdown
                const Text(
                  'Type',
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text(
                        'Select Type',
                        style: TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF667085),
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
                      onChanged: (val) {},
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Message Area
                const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF344054),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF00A3E0), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Upload Image Picker Box
                InkWell(
                  onTap: () {
                    // Upload Image Picker Handler
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE4E7EC), width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.image_rounded,
                          size: 38,
                          color: Color(0xFF42A5F5),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Upload Image',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Submit Button
                SizedBox(
                  width: 340,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      // Submit Ticket Handler
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3E0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // 6. Bottom Right Floating Action Buttons (Phone Call & WhatsApp PNG Image)
          Positioned(
            right: 24,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green Phone Call Circle Button
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x29000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // WhatsApp PNG Image Button (whatsapp.png)
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    AppAssets.whatsapp,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
