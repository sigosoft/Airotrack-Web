import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../controllers/expense_controller.dart';
import '../../../controllers/reminder_controller.dart'
    show showConfirmDeleteDialog;
import 'expense_form_dialog.dart';

/// Dashboard > Expenses. Data from GET expenses (keyword, from_date, to_date,
/// page, limit); add / edit / delete through expense_form_dialog.
class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  static const _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1D2939),
  );

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.isRegistered<ExpenseController>()
        ? Get.find<ExpenseController>()
        : Get.put(ExpenseController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Header Bar (Search Box + Date Pickers + Add Expense Button)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 768;

              Widget buildSearchBox({double? width}) {
                return SizedBox(
                  width: width,
                  height: 38,
                  child: TextField(
                    onChanged: (v) => controller.searchQuery.value = v,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF344054),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search Vehicles',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF98A2B3),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                );
              }

              Widget buildDateAndAddExpenseGroup() {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: isNarrow
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => _buildDatePickerBox(
                          context,
                          controller.fromDate.value,
                          placeholder: 'From Date',
                          onPicked: (d) => controller.setDateRange(
                            from: d,
                            to: controller.toDate.value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(
                        () => _buildDatePickerBox(
                          context,
                          controller.toDate.value,
                          placeholder: 'To Date',
                          onPicked: (d) => controller.setDateRange(
                            from: controller.fromDate.value,
                            to: d,
                          ),
                        ),
                      ),
                      Obx(
                        () =>
                            (controller.fromDate.value != null ||
                                controller.toDate.value != null)
                            ? IconButton(
                                tooltip: 'Clear dates',
                                onPressed: () => controller.setDateRange(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF667085),
                                ),
                              )
                            : const SizedBox(width: 12),
                      ),
                      // Add Expense Button
                      InkWell(
                        onTap: () => showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => const ExpenseFormDialog(),
                        ),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Add Expense',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 16 : 24,
                  vertical: isNarrow ? 10 : 11,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
                  ),
                ),
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSearchBox(width: double.infinity),
                          const SizedBox(height: 10),
                          buildDateAndAddExpenseGroup(),
                        ],
                      )
                    : SizedBox(
                        height: 38,
                        child: Row(
                          children: [
                            buildSearchBox(width: 300),
                            const Spacer(),
                            buildDateAndAddExpenseGroup(),
                          ],
                        ),
                      ),
              );
            },
          ),

          // 2. Main Table Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Total amount of the filtered expenses
                  Obx(() {
                    final total = controller.totalAmount.value;
                    if (total == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Total Amount: ${ExpenseItem.formatNum(total)}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2939),
                        ),
                      ),
                    );
                  }),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double tableWidth = constraints.maxWidth < 850
                          ? 850
                          : constraints.maxWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFEAECF0),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeaderRow(),
                                Obx(() {
                                  final list = controller.expenses;
                                  if (controller.isLoading.value &&
                                      list.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 48,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF00A3E0),
                                        ),
                                      ),
                                    );
                                  }
                                  if (list.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 48,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No expenses recorded',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: [
                                      for (int i = 0; i < list.length; i++) ...[
                                        _buildTableRow(
                                          context,
                                          controller,
                                          list[i],
                                        ),
                                        if (i < list.length - 1)
                                          const Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Color(0xFFEAECF0),
                                          ),
                                      ],
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Pagination Footer
          Obx(() {
            final totalPages = controller.lastPage.value;
            final selected = controller.currentPage.value;
            if (totalPages <= 1) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= totalPages; i++) ...[
                      InkWell(
                        onTap: () => controller.changePage(i),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected == i
                                ? const Color(0xFF00A3E0)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$i',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: selected == i
                                  ? Colors.white
                                  : const Color(0xFF344054),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const SizedBox(width: 8),
                    if (selected < totalPages)
                      InkWell(
                        onTap: controller.nextPage,
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A3E0),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0), width: 1)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Vehicle', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Date', style: _headerStyle)),
          Expanded(flex: 1, child: Text('Type', style: _headerStyle)),
          Expanded(
            flex: 1,
            child: Center(child: Text('Quantity', style: _headerStyle)),
          ),
          Expanded(
            flex: 1,
            child: Center(child: Text('Amount', style: _headerStyle)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('Payment Type', style: _headerStyle)),
          ),
          Expanded(
            flex: 1,
            child: Center(child: Text('Image', style: _headerStyle)),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Actions', style: _headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    ExpenseController controller,
    ExpenseItem item,
  ) {
    const cellStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: Color(0xFF344054),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // Vehicle
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Image.asset(
                  AppAssets.carImage,
                  width: 18,
                  height: 18,
                  color: const Color(0xFF00A3E0),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.vehicleNumber,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              ExpenseController.displayDate(item.expenseDate),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475467),
                height: 1.3,
              ),
            ),
          ),

          // Type
          Expanded(flex: 1, child: Text(item.typeLabel, style: cellStyle)),

          // Quantity
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                ExpenseItem.formatNum(item.quantity),
                style: cellStyle,
              ),
            ),
          ),

          // Amount
          Expanded(
            flex: 1,
            child: Center(
              child: Text(ExpenseItem.formatNum(item.amount), style: cellStyle),
            ),
          ),

          // Payment Type
          Expanded(
            flex: 2,
            child: Center(child: Text(item.paymentLabel, style: cellStyle)),
          ),

          // Receipt Image
          Expanded(
            flex: 1,
            child: Center(
              child: item.imageUrl == null
                  ? const Text('-', style: cellStyle)
                  : InkWell(
                      onTap: () => _showImage(context, item.imageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          item.imageUrl!,
                          width: 44,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            size: 20,
                            color: Color(0xFF98A2B3),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Actions: Edit & Delete
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF00A3E0),
                  background: const Color(0xFFF0F9FF),
                  border: const Color(0xFFBEE3F8),
                  onTap: () async {
                    final fresh = await controller.viewExpense(item);
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => ExpenseFormDialog(existing: fresh),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _actionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFF04438),
                  background: const Color(0xFFFEF3F2),
                  border: const Color(0xFFFECDCA),
                  onTap: () async {
                    final ok = await showConfirmDeleteDialog(
                      context,
                      title: 'Delete Expense',
                      message:
                          'Delete the ${item.typeLabel} expense of '
                          '${ExpenseItem.formatNum(item.amount)} for '
                          '${item.vehicleNumber}?',
                    );
                    if (ok == true) await controller.deleteExpense(item);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color background,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 1),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  void _showImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Could not load the image'),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerBox(
    BuildContext context,
    DateTime? date, {
    required String placeholder,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 15,
              color: Color(0xFF667085),
            ),
            const SizedBox(width: 6),
            Text(
              date == null ? placeholder : ExpenseController.displayDate(date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: date == null
                    ? const Color(0xFF98A2B3)
                    : const Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
