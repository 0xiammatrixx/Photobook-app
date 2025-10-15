import 'package:flutter/material.dart';

class RateCardItem {
  final String service;
  final String qty;
  final String pricing;

  RateCardItem({required this.service, required this.qty, required this.pricing});
}

class RateCardProvider extends ChangeNotifier {
  List<RateCardItem> _services = [];

  List<RateCardItem> get services => _services;

  void setServices(List<RateCardItem> newServices) {
    _services = newServices;
    notifyListeners(); // notifies all UI listening
  }

  void addService(RateCardItem item) {
    _services.add(item);
    notifyListeners();
  }

  void updateService(int index, RateCardItem newItem) {
    _services[index] = newItem;
    notifyListeners();
  }
}
