import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/vehicle_detail_controller.dart';
import '../../../utils/app_toast.dart';

class UpdateOdometerDialog extends StatefulWidget {
  const UpdateOdometerDialog({super.key});

  @override
  State<UpdateOdometerDialog> createState() => _UpdateOdometerDialogState();
}

class _UpdateOdometerDialogState extends State<UpdateOdometerDialog> {
  final TextEditingController odometerController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<VehicleDetailController>()) {
      final currentOdo =
          Get.find<VehicleDetailController>().vehicleDetail.value.odometerDigits;
      final clean = int.tryParse(currentOdo);
      if (clean != null && clean > 0) {
        odometerController.text = clean.toString();
      }
    }
  }

  @override
  void dispose() {
    odometerController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateOdometer() async {
    final text = odometerController.text.trim();
    if (text.isEmpty) {
      AppToast.show('Please enter an odometer value', isError: true);
      return;
    }

    final val = double.tryParse(text);
    if (val == null || val < 0) {
      AppToast.show('Please enter a valid numeric value', isError: true);
      return;
    }

    String targetImei = '';
    if (Get.isRegistered<VehicleDetailController>()) {
      targetImei = Get.find<VehicleDetailController>().activeImei;
    }
    if (targetImei.isEmpty && Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.vehicles.isNotEmpty) {
        targetImei = home.vehicles.first.deviceId;
      }
    }

    if (targetImei.isEmpty) {
      AppToast.show('Unable to identify vehicle device', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (Get.isRegistered<VehicleDetailController>()) {
        final success = await Get.find<VehicleDetailController>()
            .updateOdometer(targetImei, val);
        if (success && mounted) {
          Get.back();
        }
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  'Update Odometer',
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

            // 2. Odometer Input Box (Single Seamless Box, No Inner Layers)
            TextField(
              controller: odometerController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
              decoration: InputDecoration(
                hintText: 'Enter new odometer value (km)',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF98A2B3),
                ),
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

            // 3. Bottom Action Buttons Row (Cancel vs Update)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Get.back(),
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
                      onPressed: _isLoading ? null : _handleUpdateOdometer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update',
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
