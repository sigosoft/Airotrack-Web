import 'package:flutter/material.dart';
import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';

class NotificationHeader extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;

  const NotificationHeader({
    super.key,
    this.onSearchChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: AIR TRACK Logo
          Image.asset(
            AppAssets.logo,
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Row(
              children: const [
                Icon(Icons.location_on, color: AppColors.buttonBlue, size: 28),
                SizedBox(width: 6),
                Text(
                  'AIR TRACK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Middle: Search Vehicles Input Field (Single Pill Container)
          Container(
            width: 320,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF344054)),
              decoration: const InputDecoration(
                hintText: 'Search Vehicles',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w400,
                ),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF98A2B3),
                  size: 20,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                filled: false,
              ),
            ),
          ),

          // Right: Date Pickers & Filter Button
          Row(
            children: [
              _buildDatePickerPill('28-08-2025 12:00 AM'),
              const SizedBox(width: 10),
              _buildDatePickerPill('28-08-2025 12:00 AM'),
              const SizedBox(width: 10),
              // Filter Button
              InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 38,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF344054),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerPill(String dateText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Color(0xFF344054),
          ),
          const SizedBox(width: 8),
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }
}
