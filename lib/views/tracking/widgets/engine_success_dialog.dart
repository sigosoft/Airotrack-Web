import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';

class EngineSuccessDialog extends StatelessWidget {
  final bool isStopped;

  const EngineSuccessDialog({
    super.key,
    required this.isStopped,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Tick PNG Image Asset (Sucess tick.png)
            Image.asset(
              AppAssets.successTick,
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              isStopped ? 'Engine Stopped Successfully' : 'Engine Resumed Successfully',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle Description
            Text(
              isStopped
                  ? 'The vehicle engine has been turned off.'
                  : 'The vehicle engine has been successfully resumed.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Full Width Solid Cyan 'Ok' Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3E0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ok',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
