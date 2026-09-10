import 'package:flutter/material.dart';
import '../../../constants/app_assets.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/custom_media_query.dart';

class NotificationHeader extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;

  const NotificationHeader({super.key, this.onSearchChanged, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = CustomMediaQuery.isMobile(context);

    if (isMobile) {
      return SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1)),
          ),
          child: Column(
            children: [
              // Row 1: Drawer Menu Icon + Logo + Search Box
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF344054),
                        size: 24,
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    AppAssets.logo,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Row(
                      children: const [
                        Icon(
                          Icons.location_on,
                          color: AppColors.buttonBlue,
                          size: 24,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AIR TRACK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        onChanged: onSearchChanged,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: const InputDecoration(
                          hintText: 'Search notification',
                          hintStyle: TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF667085),
                            size: 18,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: Filter Button
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF344054),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onFilterTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF667085),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1)),
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
                  Icon(
                    Icons.location_on,
                    color: AppColors.buttonBlue,
                    size: 28,
                  ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
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
                      border: Border.all(
                        color: const Color(0xFFD0D5DD),
                        width: 1,
                      ),
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
