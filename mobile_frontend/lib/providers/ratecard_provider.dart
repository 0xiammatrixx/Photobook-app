import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/profileservice.dart';

class RateCardItem {
  final String id;
  final String serviceName;
  final String quantityLabel;
  final int? quantityMax;
  final String pricingMode; // "fixed" or "contact"
  final double? pricingAmount;
  final String currencyCode;
  final int? sortOrder;

  RateCardItem({
    required this.id,
    required this.serviceName,
    required this.quantityLabel,
    this.quantityMax,
    required this.pricingMode,
    this.pricingAmount,
    this.currencyCode = "NGN",
    this.sortOrder,
  });

  factory RateCardItem.fromJson(Map<String, dynamic> json) {
    return RateCardItem(
      id: json['id'],
      serviceName: json['service_name'] ?? json['serviceName'] ?? '',
      quantityLabel: json['quantity_label'] ?? json['quantityLabel'] ?? '',
      quantityMax: json['quantity_max'] ?? json['quantityMax'],
      pricingMode: json['pricing_mode'] ?? json['pricingMode'] ?? 'fixed',
      pricingAmount: double.tryParse(
        (json['pricing_amount'] ?? json['pricingAmount'] ?? '').toString(),
      ),
      currencyCode: json['currency_code'] ?? json['currencyCode'] ?? 'NGN',
      sortOrder: json['sort_order'] ?? json['sortOrder'],
    );
  }
}

class RateCardProvider extends ChangeNotifier {
  final _service = ProfilePortfolioService();
  List<RateCardItem> _services = [];
  bool isLoading = false;

  List<RateCardItem> get services => _services;

  Future<void> loadMyRateCard({required String token}) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _service.getMyRateCard(token: token);
      print("📦 Raw rate card response: $data");
      _services = data.map((e) => RateCardItem.fromJson(e)).toList();
    } catch (e) {
      print("❌ Failed to load rate card: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem({
    required String token,
    required RateCardItem item,
  }) async {
    final success = await _service.addRateCardItem(
      token: token,
      serviceName: item.serviceName,
      quantityLabel: item.quantityLabel,
      quantityMax: item.quantityMax,
      pricingMode: item.pricingMode,
      pricingAmount: item.pricingAmount,
      currencyCode: item.currencyCode,
      sortOrder: item.sortOrder,
    );
    if (success) await loadMyRateCard(token: token);
    return success;
  }

  Future<bool> editItem({required String token, required String itemId, required RateCardItem item}) async {
  final success = await _service.updateRateCardItem(
    token: token,
    itemId: itemId,
    serviceName: item.serviceName,
    quantityLabel: item.quantityLabel,
    quantityMax: item.quantityMax,
    pricingMode: item.pricingMode,
    pricingAmount: item.pricingAmount,
    currencyCode: item.currencyCode,
    sortOrder: item.sortOrder,
  );
  if (success) await loadMyRateCard(token: token);
  return success;
}

  Future<bool> deleteItem({
    required String token,
    required String itemId,
  }) async {
    final success = await _service.deleteRateCardItem(
      token: token,
      itemId: itemId,
    );
    if (success) {
      _services.removeWhere((e) => e.id == itemId);
      notifyListeners();
    }
    return success;
  }
}
