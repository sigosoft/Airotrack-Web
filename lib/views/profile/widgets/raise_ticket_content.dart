import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/support_ticket_controller.dart';
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

  final SupportTicketController _tickets =
      Get.isRegistered<SupportTicketController>()
      ? Get.find<SupportTicketController>()
      : Get.put(SupportTicketController());

  /// POST add_support_ticket with the vehicle, type key, message and image.
  Future<void> _submit() async {
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
    final ok = await _tickets.submitTicket(
      vehicleNumber: _vehicle!,
      type: _type!,
      message: _message.text.trim(),
      imageBytes: _imageBytes,
      imageName: _imageName,
    );
    if (ok && mounted) {
      setState(() {
        _type = null;
        _message.clear();
        _imageBytes = null;
        _imageName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = CustomMediaQuery.isMobile(context);

    return Obx(() {
      // Vehicles from GET /vehicles; falls back to the home list.
      final HomeController? homeController = Get.isRegistered<HomeController>()
          ? Get.find<HomeController>()
          : null;
      final vehicleOptions = _tickets.vehicles.isNotEmpty
          ? _tickets.vehicles.map((v) => v.vehicleNumber).toList()
          : homeController != null && homeController.vehicles.isNotEmpty
          ? homeController.vehicles
                .map((v) => v.plateNumber)
                .where((p) => p.trim().isNotEmpty)
                .toList()
          : <String>[];

      // Ticket types from GET /support_ticket_options: key -> label.
      final typeOptions = {
        for (final t in _tickets.ticketTypes) t.key: t.label,
      };

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
                        value: typeOptions.containsKey(_type) ? _type : null,
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
                        items: typeOptions.entries.map((t) {
                          return DropdownMenuItem<String>(
                            value: t.key,
                            child: Text(
                              t.value,
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
                      onPressed: _tickets.isSubmitting.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3E0),
                        disabledBackgroundColor: const Color(0xFF7FD1EF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: _tickets.isSubmitting.value
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 6. My Tickets (GET support_tickets)
                  _buildMyTickets(isMobile),
                  const SizedBox(height: 90),
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
    });
  }

  Widget _buildMyTickets(bool isMobile) {
    final list = _tickets.tickets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Tickets',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 12),
        if (_tickets.isLoadingTickets.value && list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00A3E0)),
            ),
          )
        else if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No tickets raised yet.',
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
          )
        else
          ...list.map((t) => _ticketCard(t, isMobile)),
        if (_tickets.lastPage.value > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: _tickets.currentPage.value > 1
                      ? () => _tickets.loadTickets(
                          page: _tickets.currentPage.value - 1,
                        )
                      : null,
                  child: const Text('PREV'),
                ),
                Text(
                  '${_tickets.currentPage.value} / ${_tickets.lastPage.value}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF344054),
                  ),
                ),
                TextButton(
                  onPressed:
                      _tickets.currentPage.value < _tickets.lastPage.value
                      ? () => _tickets.loadTickets(
                          page: _tickets.currentPage.value + 1,
                        )
                      : null,
                  child: const Text('NEXT'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _ticketCard(SupportTicket t, bool isMobile) {
    // Status colours: 1 Pending, 2 Processing, 3 Solved, 4 Closed.
    final Color statusColor = switch (t.statusKey) {
      '1' => const Color(0xFFF79009),
      '2' => const Color(0xFF00A3E0),
      '3' => const Color(0xFF12B76A),
      _ => const Color(0xFF667085),
    };
    final d = t.createdAt;
    final date = d == null
        ? ''
        : '${d.day.toString().padLeft(2, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-${d.year}';

    return Container(
      width: isMobile ? double.infinity : 560,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${t.id}  ${t.vehicleNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t.statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [t.typeLabel, date].where((s) => s.isNotEmpty).join('  •  '),
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 6),
          Text(
            t.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF344054)),
          ),
        ],
      ),
    );
  }
}
