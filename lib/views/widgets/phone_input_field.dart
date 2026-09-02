import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import 'indian_flag_icon.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

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
              const SizedBox(width: 14),
              // Flag Icon
              const IndianFlagIcon(width: 22, height: 15),
              const SizedBox(width: 8),
              // Country Code
              Text(
                AppStrings.defaultCountryCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
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
                  controller: controller,
                  onChanged: onChanged,
                  onEditingComplete: onEditingComplete,
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
              errorText!,
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
