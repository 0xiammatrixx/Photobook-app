import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/profileservice.dart';

class RateCardItem {
  final String id;
  final String serviceName;
  final String quantityLabel;
  final int? quantityMax;
  final String pricingMode;
  final double? pricingAmount;
  final String currencyCode;
  final int? sortOrder;

  final String description;
  final List<String> categories;
  final List<String> whatsIncluded;
  final String deliveryTime;

  RateCardItem({
    required this.id,
    required this.serviceName,
    required this.quantityLabel,
    this.quantityMax,
    required this.pricingMode,
    this.pricingAmount,
    this.currencyCode = "NGN",
    this.sortOrder,

    this.description = "",
    this.categories = const [],
    this.whatsIncluded = const [],
    this.deliveryTime = "",
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

      description: json["description"] ?? "",
      categories: List<String>.from(json["categories"] ?? []),
      whatsIncluded: List<String>.from(
          (json["whats_included"] ?? json["whatsIncluded"]) ?? []),
      deliveryTime: (json["delivery_time"] ?? json["deliveryTime"] ?? "") as String,
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

  /// Load a specific photographer's public rate card (client view).
  Future<void> loadPhotographerRateCard({
    required String photographerId,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _service.getPhotographerRateCard(photographerId);
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
      description: item.description,
      categories: item.categories,
      whatsIncluded: item.whatsIncluded,
      deliveryTime: item.deliveryTime,
    );
    if (success) await loadMyRateCard(token: token);
    return success;
  }

  Future<bool> editItem({
    required String token,
    required String itemId,
    required RateCardItem item,
  }) async {
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
      description: item.description,
      categories: item.categories,
      whatsIncluded: item.whatsIncluded,
      deliveryTime: item.deliveryTime,
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
