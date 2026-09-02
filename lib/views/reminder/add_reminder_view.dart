import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/reminder_controller.dart';
import 'widgets/reminder_header.dart';
import 'widgets/reminder_table_row.dart';

class AddReminderView extends StatelessWidget {
  const AddReminderView({super.key});

  @override
  Widget build(BuildContext context) {
    final ReminderController controller = Get.put(ReminderController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Top Header Bar
          const ReminderHeader(),

          // 2. Data Table
          Expanded(
            child: Column(
              children: [
                // Table Header Row
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE4E7EC), width: 1),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Period',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D2939),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows Stack
                Expanded(
                  child: Obx(() {
                    final list = controller.reminders;

                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'No reminders added yet.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];

                        return ReminderTableRow(
                          item: item,
                          onEdit: () => controller.editReminder(item),
                          onDelete: () => controller.deleteReminder(item),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),

          // 3. Bottom 1-10 Pagination Bar
          Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Obx(() {
              final activePage = controller.currentPage.value;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(10, (pageIndex) {
                    final pageNum = pageIndex + 1;
                    final isSelected = activePage == pageNum;

                    return InkWell(
                      onTap: () => controller.changePage(pageNum),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00A3E0) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$pageNum',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF344054),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: controller.nextPage,
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A3E0),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
