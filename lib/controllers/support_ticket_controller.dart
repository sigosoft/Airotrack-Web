import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../config/api_config.dart';
import '../config/dio_client.dart';
import '../services/lookups_service.dart';
import '../utils/app_toast.dart';

/// A ticket from support_tickets.
class SupportTicket {
  final String id;
  final String vehicleNumber;
  final String typeLabel;
  final String message;
  final String statusKey;
  final String statusLabel;
  final DateTime? createdAt;
  final String? imageUrl;

  const SupportTicket({
    required this.id,
    required this.vehicleNumber,
    required this.typeLabel,
    required this.message,
    required this.statusKey,
    required this.statusLabel,
    required this.createdAt,
    required this.imageUrl,
  });

  static String _str(dynamic v) {
    final s = (v ?? '').toString();
    return s == 'null' ? '' : s;
  }

  factory SupportTicket.fromJson(Map json) => SupportTicket(
    id: _str(json['id']),
    vehicleNumber: _str(json['vehicle_number']),
    typeLabel: _str(json['type_label'] ?? json['type']),
    message: _str(json['message']),
    statusKey: _str(json['status']),
    statusLabel: _str(json['status_label'] ?? json['status']),
    createdAt: DateTime.tryParse(_str(json['created_at']))?.toLocal(),
    imageUrl: ApiConfig.storageFileUrl(json['image']),
  );
}

/// Profile > Raise Ticket: support_ticket_options, add_support_ticket,
/// support_tickets (the user's tickets under the form).
class SupportTicketController extends GetxController {
  static const int pageSize = 10;

  final ticketTypes = <LookupOption>[].obs;
  final ticketStatuses = <LookupOption>[].obs;
  final vehicles = <VehicleOption>[].obs;

  final tickets = <SupportTicket>[].obs;
  final currentPage = 1.obs;
  final lastPage = 1.obs;

  final isLoadingTickets = false.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOptions();
    loadVehicles();
    loadTickets(page: 1);
  }

  Future<void> loadOptions() async {
    try {
      final response = await DioClient().get(ApiEndPoints.supportTicketOptions);
      final data = LookupsService.dataOf(response);
      if (data is Map) {
        ticketTypes.assignAll(LookupOption.listFrom(data['types']));
        ticketStatuses.assignAll(LookupOption.listFrom(data['statuses']));
      }
    } catch (e) {
      debugPrint('[Tickets] support_ticket_options failed: $e');
    }
  }

  Future<void> loadVehicles() async {
    vehicles.assignAll(await LookupsService.vehicles());
  }

  Future<void> loadTickets({int? page}) async {
    final p = page ?? currentPage.value;
    isLoadingTickets.value = true;
    try {
      final response = await DioClient().get(
        ApiEndPoints.supportTickets,
        queryParameters: {'limit': pageSize, 'page': p},
      );
      if (!LookupsService.isOk(response)) return;
      final data = LookupsService.dataOf(response);
      final list = data is Map ? data['tickets'] : null;
      tickets.assignAll(
        list is List
            ? list.whereType<Map>().map(SupportTicket.fromJson).toList()
            : <SupportTicket>[],
      );
      final pagination = data is Map ? data['pagination'] : null;
      if (pagination is Map) {
        currentPage.value = int.tryParse('${pagination['current_page']}') ?? p;
        lastPage.value = int.tryParse('${pagination['last_page']}') ?? 1;
      }
    } catch (e) {
      debugPrint('[Tickets] support_tickets failed: $e');
    } finally {
      isLoadingTickets.value = false;
    }
  }

  /// POST add_support_ticket. contact_no is left to the server, which uses
  /// the account's mobile number. Returns true on success.
  Future<bool> submitTicket({
    required String vehicleNumber,
    required String type,
    required String message,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final form = FormData.fromMap({
        'vehicle_number': vehicleNumber,
        'type': type,
        'message': message,
      });
      if (imageBytes != null) {
        form.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              imageBytes,
              filename: (imageName == null || imageName.isEmpty)
                  ? 'ticket.jpg'
                  : imageName,
            ),
          ),
        );
      }
      final response = await DioClient().post(
        ApiEndPoints.addSupportTicket,
        body: form,
      );
      if (LookupsService.isOk(response)) {
        AppToast.show(
          LookupsService.messageOf(response, fallback: 'Ticket raised'),
        );
        await loadTickets(page: 1);
        return true;
      }
      AppToast.show(
        LookupsService.messageOf(response, fallback: 'Could not raise ticket'),
        isError: true,
      );
      return false;
    } catch (e) {
      AppToast.showErrorMessage(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
