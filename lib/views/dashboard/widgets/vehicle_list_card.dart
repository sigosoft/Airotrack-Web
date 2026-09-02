import 'package:flutter/material.dart';
import '../../../models/dashboard_model.dart';

class VehicleListCard extends StatelessWidget {
  final List<VehicleItem> vehicleList;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const VehicleListCard({
    super.key,
    required this.vehicleList,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Vehicles',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(vehicleList.length, (index) {
            final isSelected = selectedIndex == index;
            final item = vehicleList[index];

            return InkWell(
              onTap: () => onSelect(index),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE0F2FE) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.registrationNumber,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF1D2939) : const Color(0xFF475467),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
