import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/expense_controller.dart';
import '../../../utils/app_toast.dart';

/// Add Expense (add_expense) or, with [existing], Edit Expense
/// (update_expense). Same layout as the original Add Expense dialog.
class ExpenseFormDialog extends StatefulWidget {
  final ExpenseItem? existing;

  const ExpenseFormDialog({super.key, this.existing});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final ExpenseController controller = Get.find<ExpenseController>();

  String? _vehicle;
  String? _type;
  String? _payment;
  DateTime _date = DateTime.now();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _vehicle = e.vehicleNumber.isEmpty ? null : e.vehicleNumber;
      _type = e.typeKey.isEmpty ? null : e.typeKey;
      _payment = e.paymentKey.isEmpty ? null : e.paymentKey;
      _date = e.expenseDate ?? DateTime.now();
      _quantity.text = e.quantity == null
          ? ''
          : ExpenseItem.formatNum(e.quantity);
      _amount.text = ExpenseItem.formatNum(e.amount);
      _description.text = e.description;
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
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

  Future<void> _submit() async {
    if (_vehicle == null) {
      AppToast.show('Please select a vehicle', isError: true);
      return;
    }
    if (_type == null) {
      AppToast.show('Please select an expense type', isError: true);
      return;
    }
    final amount = _amount.text.trim();
    if ((num.tryParse(amount) ?? 0) <= 0) {
      AppToast.show('Please enter the amount', isError: true);
      return;
    }
    if (_payment == null) {
      AppToast.show('Please select a payment method', isError: true);
      return;
    }
    final ok = await controller.saveExpense(
      id: widget.existing?.id,
      vehicleNumber: _vehicle!,
      expenseDate: _date,
      expenseType: _type!,
      amount: amount,
      paymentMethod: _payment!,
      quantity: _quantity.text.trim(),
      description: _description.text.trim(),
      imageBytes: _imageBytes,
      imageName: _imageName,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Expense' : 'Add Expense',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Row 1: Vehicle & Date
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          label: 'Vehicle',
                          child: Obx(() {
                            final options = controller.vehicles
                                .map((v) => v.vehicleNumber)
                                .toList();
                            if (_vehicle != null &&
                                !options.contains(_vehicle)) {
                              options.insert(0, _vehicle!);
                            }
                            return _dropdown(
                              hint: 'Select Vehicle',
                              value: _vehicle,
                              items: {for (final o in options) o: o},
                              onChanged: (v) => setState(() => _vehicle = v),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _formField(
                          label: 'Date',
                          child: InkWell(
                            onTap: _pickDate,
                            child: _box(
                              child: Row(
                                children: [
                                  Text(
                                    ExpenseController.displayDate(_date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF344054),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 16,
                                    color: Color(0xFF1D2939),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 2: Expense Type & Quantity
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          label: 'Expense Type',
                          child: Obx(
                            () => _dropdown(
                              hint: 'Select Expense Type',
                              value: _type,
                              items: {
                                for (final t in controller.expenseTypes)
                                  t.key: t.label,
                              },
                              onChanged: (v) => setState(() => _type = v),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _formField(
                          label: 'Quantity',
                          child: _input(_quantity, 'Enter Quantity'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Amount & Payment Method
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          label: 'Amount',
                          child: _input(_amount, 'Enter Amount'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _formField(
                          label: 'Payment Method',
                          child: Obx(
                            () => _dropdown(
                              hint: 'Select Payment Method',
                              value: _payment,
                              items: {
                                for (final p in controller.paymentMethods)
                                  p.key: p.label,
                              },
                              onChanged: (v) => setState(() => _payment = v),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 4: Description
                  _formField(
                    label: 'Description',
                    child: TextField(
                      controller: _description,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF344054),
                      ),
                      decoration: _decoration('Enter Description'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Row 5: Upload Image
                  _formField(
                    label: 'Upload Image',
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEAECF0),
                            width: 1,
                          ),
                        ),
                        child: _imagePreview(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Row 6: Cancel & Submit
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFEAECF0),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(
                          () => InkWell(
                            onTap: controller.isSaving.value ? null : _submit,
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: controller.isSaving.value
                                    ? const Color(0xFF7FD1EF)
                                    : const Color(0xFF00A3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Floating Close 'X'
          Positioned(
            top: -12,
            right: -12,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD0D5DD),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF1D2939),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePreview() {
    final existingUrl = widget.existing?.imageUrl;
    Widget? image;
    if (_imageBytes != null) {
      image = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (existingUrl != null) {
      image = Image.network(
        existingUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.broken_image_outlined, color: Color(0xFF98A2B3)),
      );
    }
    if (image == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 28, color: Color(0xFF00A3E0)),
          SizedBox(height: 6),
          Text(
            'Upload Image',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF98A2B3),
            ),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
        if (_imageBytes != null)
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
    );
  }

  Widget _formField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _box({required Widget child}) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: child,
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _box(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          value: items.containsKey(value) ? value : null,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Color(0xFFB0B7C3)),
          ),
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            size: 22,
            color: Color(0xFF00A3E0),
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
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

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB0B7C3)),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF00A3E0), width: 1.5),
    ),
  );

  Widget _input(TextEditingController c, String hint) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: const TextStyle(fontSize: 12, color: Color(0xFF344054)),
        decoration: _decoration(hint),
      ),
    );
  }
}
