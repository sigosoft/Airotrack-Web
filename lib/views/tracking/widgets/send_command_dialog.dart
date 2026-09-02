import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'engine_success_dialog.dart';

class SendCommandDialog extends StatefulWidget {
  final String vehicleNumber;

  const SendCommandDialog({
    super.key,
    this.vehicleNumber = 'KL 07 D 0518',
  });

  @override
  State<SendCommandDialog> createState() => _SendCommandDialogState();
}

class _SendCommandDialogState extends State<SendCommandDialog> {
  int selectedCommand = 0; // 0: Stop Engine, 1: Resume Engine

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
            // 1. Header Title
            Text(
              'Send Command - ${widget.vehicleNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2939),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Command Options Cards Row (Stop Engine vs Resume Engine)
            Row(
              children: [
                // Stop Engine Card Option
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedCommand = 0),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedCommand == 0
                                  ? const Color(0xFF00A3E0)
                                  : const Color(0xFFEAECF0),
                              width: selectedCommand == 0 ? 1.5 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEE4E2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFFF04438),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Stop Engine',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Radio Button Indicator
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedCommand == 0
                                  ? const Color(0xFF00A3E0)
                                  : const Color(0xFFD0D5DD),
                              width: selectedCommand == 0 ? 6 : 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Resume Engine Card Option
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedCommand = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedCommand == 1
                                  ? const Color(0xFF00A3E0)
                                  : const Color(0xFFEAECF0),
                              width: selectedCommand == 1 ? 1.5 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD1FADF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_open_rounded,
                                  color: Color(0xFF12B76A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Resume Engine',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Radio Button Indicator
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedCommand == 1
                                  ? const Color(0xFF00A3E0)
                                  : const Color(0xFFD0D5DD),
                              width: selectedCommand == 1 ? 6 : 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Warning Note Text
            const Text(
              'Note: For emergency use only. Please do not use in areas where GSM network connectivity is poor.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF667085),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),

            // 4. Bottom Action Buttons Row (Cancel vs Send)
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
                        final isStop = selectedCommand == 0;
                        Get.back();
                        showDialog(
                          context: context,
                          builder: (context) => EngineSuccessDialog(
                            isStopped: isStop,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Send',
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
