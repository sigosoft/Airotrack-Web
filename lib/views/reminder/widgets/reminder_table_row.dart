import 'package:flutter/material.dart';

import '../../../models/reminder_model.dart';

class ReminderTableRow extends StatelessWidget {
  final ReminderItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReminderTableRow({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F4F7), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Column 1: Type (Car Icon + Oil Change text)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFF00A3E0),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  item.type,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
              ],
            ),
          ),

          // Column 2: Period (5000 Km text)
          Expanded(
            flex: 3,
            child: Text(
              item.period,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF344054),
              ),
            ),
          ),

          // Column 3: Quick Actions (Edit & Delete Icons)
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBEE3F8), width: 1),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF00A3E0),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECDCA), width: 1),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFF04438),
                      size: 16,
                    ),
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
