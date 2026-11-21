import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../services/lookups_service.dart';
import '../utils/app_toast.dart';

/// An expense from expenses / view_expense.
class ExpenseItem {
  final String id;
  final String vehicleNumber;
  final DateTime? expenseDate;
  final String typeKey;
  final String typeLabel;
  final num? quantity;
  final num amount;
  final String paymentKey;
  final String paymentLabel;
  final String description;

  /// Full image URL, or null.
  final String? imageUrl;

  const ExpenseItem({
    required this.id,
    required this.vehicleNumber,
    required this.expenseDate,
    required this.typeKey,
    required this.typeLabel,
    required this.quantity,
    required this.amount,
    required this.paymentKey,
    required this.paymentLabel,
    required this.description,
    required this.imageUrl,
  });

  static String _str(dynamic v) {
    final s = (v ?? '').toString();
    return s == 'null' ? '' : s;
  }

  factory ExpenseItem.fromJson(Map json) {
    // The API stores the date as local midnight in UTC
    // (e.g. 2026-11-20 -> 2026-11-19T18:30:00Z), so show it in local time.
    final rawDate = _str(json['expense_date']);
    return ExpenseItem(
      id: _str(json['id']),
      vehicleNumber: _str(json['vehicle_number']),
      expenseDate: DateTime.tryParse(rawDate)?.toLocal(),
      typeKey: _str(json['expense_type']),
      typeLabel: _str(json['expense_type_label'] ?? json['expense_type']),
      quantity: num.tryParse(_str(json['quantity'])),
      amount: num.tryParse(_str(json['amount'])) ?? 0,
      paymentKey: _str(json['payment_method']),
      paymentLabel: _str(
        json['payment_method_label'] ?? json['payment_method'],
      ),
      description: _str(json['description']),
      imageUrl: ApiConfig.storageFileUrl(json['image']),
    );
  }

  static String formatNum(num? n) {
    if (n == null) return '-';
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }
}

/// Dashboard > Expenses: expense_options, expenses (list),
/// add / view / update / delete_expense.
class ExpenseController extends GetxController {
  static const int pageSize = 10;

  final expenses = <ExpenseItem>[].obs;
  final expenseTypes = <LookupOption>[].obs;
  final paymentMethods = <LookupOption>[].obs;
  final vehicles = <VehicleOption>[].obs;

  final searchQuery = ''.obs;
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();

  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final totalAmount = RxnNum();

  final isLoading = false.obs;
  final isSaving = false.obs;

  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce(
      searchQuery,
      (_) => loadExpenses(page: 1),
      time: const Duration(milliseconds: 400),
    );
    loadOptions();
    loadVehicles();
    loadExpenses(page: 1);
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  static String apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String displayDate(DateTime? d) {
    if (d == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> loadOptions() async {
    try {
      final response = await DioClient().get(ApiEndPoints.expenseOptions);
      final data = LookupsService.dataOf(response);
      if (data is Map) {
        expenseTypes.assignAll(LookupOption.listFrom(data['types']));
        paymentMethods.assignAll(
          LookupOption.listFrom(data['payment_methods']),
        );
      }
    } catch (e) {
      debugPrint('[Expenses] expense_options failed: $e');
    }
  }

  Future<void> loadVehicles() async {
    vehicles.assignAll(await LookupsService.vehicles());
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    fromDate.value = from;
    toDate.value = to;
    loadExpenses(page: 1);
  }

  Future<void> loadExpenses({int? page}) async {
    final p = page ?? currentPage.value;
    isLoading.value = true;
    try {
      final query = <String, dynamic>{'limit': pageSize, 'page': p};
      final keyword = searchQuery.value.trim();
      if (keyword.isNotEmpty) query['keyword'] = keyword;
      if (fromDate.value != null) query['from_date'] = apiDate(fromDate.value!);
      if (toDate.value != null) query['to_date'] = apiDate(toDate.value!);

      final response = await DioClient().get(
        ApiEndPoints.expenses,
        queryParameters: query,
      );
      if (!LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(
            response,
            fallback: 'Could not load expenses',
          ),
          isError: true,
        );
        return;
      }
      final data = LookupsService.dataOf(response);
      final list = data is Map ? data['expenses'] : null;
      expenses.assignAll(
        list is List
            ? list.whereType<Map>().map(ExpenseItem.fromJson).toList()
            : <ExpenseItem>[],
      );
      totalAmount.value = data is Map
          ? num.tryParse('${data['total_amount']}')
          : null;
      final pagination = data is Map ? data['pagination'] : null;
      if (pagination is Map) {
        currentPage.value = int.tryParse('${pagination['current_page']}') ?? p;
        lastPage.value = int.tryParse('${pagination['last_page']}') ?? 1;
      } else {
        currentPage.value = p;
        lastPage.value = 1;
      }
    } catch (e) {
      AppToast.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void changePage(int page) {
    if (page != currentPage.value) loadExpenses(page: page);
  }

  void nextPage() {
    if (currentPage.value < lastPage.value) {
      loadExpenses(page: currentPage.value + 1);
    }
  }

  /// GET view_expense?id= (falls back to [item] if the call fails).
  Future<ExpenseItem> viewExpense(ExpenseItem item) async {
    try {
      final response = await DioClient().get(
        ApiEndPoints.viewExpense,
        queryParameters: {'id': item.id},
      );
      final data = LookupsService.dataOf(response);
      if (LookupsService.isOk(response) &&
          data is Map &&
          data['expense'] is Map) {
        return ExpenseItem.fromJson(data['expense'] as Map);
      }
    } catch (e) {
      debugPrint('[Expenses] view_expense failed: $e');
    }
    return item;
  }

  /// Add (when [id] is null) or update an expense. Returns true on success.
  Future<bool> saveExpense({
    String? id,
    required String vehicleNumber,
    required DateTime expenseDate,
    required String expenseType,
    required String amount,
    required String paymentMethod,
    String quantity = '',
    String description = '',
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final form = FormData.fromMap({
        'id': ?id,
        'vehicle_number': vehicleNumber,
        'expense_date': apiDate(expenseDate),
        'expense_type': expenseType,
        'quantity': quantity,
        'amount': amount,
        'payment_method': paymentMethod,
        'description': description,
      });
      if (imageBytes != null) {
        form.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              imageBytes,
              filename: (imageName == null || imageName.isEmpty)
                  ? 'expense.jpg'
                  : imageName,
            ),
          ),
        );
      }
      final response = await DioClient().post(
        id == null ? ApiEndPoints.addExpense : ApiEndPoints.updateExpense,
        body: form,
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(
            response,
            fallback: id == null ? 'Expense added' : 'Expense updated',
          ),
        );
        await loadExpenses(page: id == null ? 1 : currentPage.value);
        return true;
      }
      AppToast.show(
        LookupsService.messageOf(response, fallback: 'Could not save expense'),
        isError: true,
      );
      return false;
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// POST delete_expense. Returns true on success.
  Future<bool> deleteExpense(ExpenseItem item) async {
    try {
      final response = await DioClient().post(
        ApiEndPoints.deleteExpense,
        body: FormData.fromMap({'id': item.id}),
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(response, fallback: 'Expense deleted'),
        );
        final page = expenses.length == 1 && currentPage.value > 1
            ? currentPage.value - 1
            : currentPage.value;
        await loadExpenses(page: page);
        return true;
      }
      AppToast.show(
        LookupsService.messageOf(
          response,
          fallback: 'Could not delete expense',
        ),
        isError: true,
      );
    } catch (e) {
      AppToast.showErrorMessage(e);
    }
    return false;
  }
}
