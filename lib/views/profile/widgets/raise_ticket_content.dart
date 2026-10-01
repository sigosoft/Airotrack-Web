import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../utils/app_toast.dart';
import '../../../utils/custom_media_query.dart';

class RaiseTicketContent extends StatefulWidget {
  const RaiseTicketContent({super.key});

  @override
  State<RaiseTicketContent> createState() => _RaiseTicketContentState();
}

class _RaiseTicketContentState extends State<RaiseTicketContent> {
  String? _vehicle;
  String? _type;
  final TextEditingController _message = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (e) {
      AppToast.show('Could not open the gallery', isError: true);
    }
  }

  void _submit() {
    if (_vehicle == null) {
      AppToast.show('Please select a vehicle', isError: true);
      return;
    }
    if (_type == null) {
      AppToast.show('Please select a type', isError: true);
      return;
    }
    if (_message.text.trim().isEmpty) {
      AppToast.show('Please enter a message', isError: true);
      return;
    }
    // There is no Raise Ticket API yet: nothing can be sent. When the API
    // is available, send _vehicle, _type, _message.text and _imageBytes
    // (_imageName) here.
    AppToast.show(
      'Ticket service is not available yet. Please call or WhatsApp us.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final ProfileController controller = Get.find<ProfileController>();
    final isMobile = CustomMediaQuery.isMobile(context);

    final HomeController? homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final vehicleOptions =
        homeController != null && homeController.vehicles.isNotEmpty
        ? homeController.vehicles
              .map((v) => v.plateNumber)
              .where((p) => p.trim().isNotEmpty)
              .toList()
        : <String>[];

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
            padding: EdgeInsets.all(isMobile ? 14 : 24),
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
                    border: Border.all(
                      color: const Color(0xFFE4E7EC),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: vehicleOptions.contains(_vehicle)
                          ? _vehicle
                          : null,
                      hint: const Text(
                        'Select Vehicle',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF98A2B3),
                        ),
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF344054),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _vehicle = val),
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
                    border: Border.all(
                      color: const Color(0xFFE4E7EC),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _type,
                      hint: const Text(
                        'Select Type',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF98A2B3),
                        ),
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF344054),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _type = val),
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
                  controller: _message,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF344054),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFFE4E7EC),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFF00A3E0),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Upload Image Picker Box
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE4E7EC),
                        width: 1,
                      ),
                    ),
                    // Picked image shown in the same box (tap to change, x to
                    // remove); empty box looks exactly as before.
                    child: _imageBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _imageBytes = null;
                                    _imageName = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0x99000000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
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
                  width: isMobile ? double.infinity : 340,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _submit,
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
