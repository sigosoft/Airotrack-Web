import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_assets.dart';
import '../../../controllers/dashboard_controller.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  int _selectedPage = 1;

  final List<Map<String, dynamic>> _expensesList = [
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025\n05:38:08 PM',
      'type': 'Food',
      'quantity': '01',
      'amount': '200 INR',
      'paymentType': 'Online',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025\n05:38:08 PM',
      'type': 'Food',
      'quantity': '01',
      'amount': '200 INR',
      'paymentType': 'Online',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025\n05:38:08 PM',
      'type': 'Food',
      'quantity': '01',
      'amount': '200 INR',
      'paymentType': 'Online',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025\n05:38:08 PM',
      'type': 'Food',
      'quantity': '01',
      'amount': '200 INR',
      'paymentType': 'Online',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025\n05:38:08 PM',
      'type': 'Food',
      'quantity': '01',
      'amount': '200 INR',
      'paymentType': 'Online',
    },
    {
      'vehicle': 'KL 07 D 0518',
      'dateTime': 'Oct 17, 2025\n05:38:08 PM',
      'type': 'Food',
      'quantity': '01',
      'amount': '200 INR',
      'paymentType': 'Online',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Header Bar (Search Box + Date Pickers + Add Expense Button)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEAECF0), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Search Vehicles Search Bar
                Container(
                  width: 300,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Search Vehicles',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Start Date & End Date Range Pickers
                Obx(
                  () => _buildDatePickerBox(controller.reportStartDate.value),
                ),
                const SizedBox(width: 12),
                Obx(() => _buildDatePickerBox(controller.reportEndDate.value)),
                const SizedBox(width: 16),

                // Add Expense Button
                InkWell(
                  onTap: () => _showAddExpenseDialog(context),
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
          ),

          // 2. Main Table Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFEAECF0), width: 1),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Vehicle',
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
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
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
                            flex: 1,
                            child: Center(
                              child: Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                'Payment Type',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Image',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Rows
                    for (int i = 0; i < _expensesList.length; i++) ...[
                      _buildTableRow(_expensesList[i]),
                      if (i < _expensesList.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFEAECF0),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Pagination Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 10; i++) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPage = i;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedPage == i
                            ? const Color(0xFF00A3E0)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _selectedPage == i
                              ? Colors.white
                              : const Color(0xFF344054),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                const SizedBox(width: 8),

                // NEXT Button
                InkWell(
                  onTap: () {
                    if (_selectedPage < 10) {
                      setState(() {
                        _selectedPage++;
                      });
                    }
                  },
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
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
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
                Text(
                  item['vehicle'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2939),
                  ),
                ),
              ],
            ),
          ),

          // Date & Time
          Expanded(
            flex: 2,
            child: Text(
              item['dateTime'],
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475467),
                height: 1.3,
              ),
            ),
          ),

          // Type
          Expanded(
            flex: 1,
            child: Text(
              item['type'],
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF344054),
              ),
            ),
          ),

          // Quantity
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                item['quantity'],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF344054),
                ),
              ),
            ),
          ),

          // Amount
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                item['amount'],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF344054),
                ),
              ),
            ),
          ),

          // Payment Type
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                item['paymentType'],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF344054),
                ),
              ),
            ),
          ),

          // Receipt Image Asset
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  AppAssets.printImage,
                  width: 44,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerBox(String dateStr) {
    return Container(
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
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main White Dialog Container
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Add Expense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Row 1: Vehicle (Left) & Date (Right)
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Vehicle',
                            child: _buildDropdownField('Select Vehicle'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Date',
                            child:
                                _buildDatePickerInput('13 Oct 2025 10:40 Am'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 2: Expense Type (Left) & Quantity (Right)
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Expense Type',
                            child: _buildDropdownField('Select Expense Type'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Quantity',
                            child: _buildTextInputField('Enter Quantity'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 3: Amount (Left) & Payment Method (Right)
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Amount',
                            child: _buildTextInputField('Enter Amount'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Payment Method',
                            child:
                                _buildDropdownField('Select Payment Method'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 4: Description (Full Width Multiline)
                    _buildFormField(
                      label: 'Description',
                      child: Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFEAECF0), width: 1),
                        ),
                        child: const Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Enter Description',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFFB0B7C3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Row 5: Upload Image Box
                    _buildFormField(
                      label: 'Upload Image',
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFEAECF0), width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.image_outlined,
                              size: 28,
                              color: Color(0xFF00A3E0),
                            ),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Row 6: Action Buttons (Cancel & Submit)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
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
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
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
                      ],
                    ),
                  ],
                ),
              ),

              // Floating Close 'X' Button on Top-Right Corner
              Positioned(
                top: -12,
                right: -12,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFD0D5DD), width: 1.5),
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
      },
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
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

  Widget _buildDropdownField(String placeholder) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Row(
        children: [
          Text(
            placeholder,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB0B7C3),
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.arrow_drop_down_rounded,
            size: 22,
            color: Color(0xFF00A3E0),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputField(String placeholder) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          placeholder,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFB0B7C3),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerInput(String placeholder) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1),
      ),
      child: Row(
        children: [
          Text(
            placeholder,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF98A2B3),
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
    );
  }
}
