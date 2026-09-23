import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../utils/country_data.dart';
import 'country_picker_dialog.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final String? countryCode;
  final ValueChanged<CountryInfo>? onCountryChanged;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.countryCode,
    this.onCountryChanged,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryInfo _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = CountryData.findByDialCode(widget.countryCode);
  }

  @override
  void didUpdateWidget(covariant PhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countryCode != null && widget.countryCode != oldWidget.countryCode) {
      _selectedCountry = CountryData.findByDialCode(widget.countryCode);
    }
  }

  void _handleCountrySelection() async {
    final picked = await CountryPickerDialog.show(
      context,
      selectedCountry: _selectedCountry,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedCountry = picked;
      });
      widget.onCountryChanged?.call(picked);
    }
  }

  void _onTextChanged(String value) {
    // 1. Auto-detect country if input has a country prefix (+971, 00971, +1, etc.)
    final detected = CountryData.detectCountryAndNumber(value);
    if (detected != null) {
      setState(() {
        _selectedCountry = detected.country;
      });
      widget.onCountryChanged?.call(detected.country);
      widget.controller.value = TextEditingValue(
        text: detected.cleanNumber,
        selection: TextSelection.collapsed(offset: detected.cleanNumber.length),
      );
      widget.onChanged?.call(detected.cleanNumber);
      return;
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.borderError : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),

              // Country Code & Flag Selector Button
              InkWell(
                onTap: _handleCountrySelection,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.dialCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Vertical Divider Pipe
              Container(
                width: 1,
                height: 22,
                color: AppColors.divider,
              ),
              const SizedBox(width: 12),

              // Input Field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onChanged: _onTextChanged,
                  onEditingComplete: widget.onEditingComplete,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    hintText: AppStrings.enterPhoneNumber,
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: AppColors.borderError,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
