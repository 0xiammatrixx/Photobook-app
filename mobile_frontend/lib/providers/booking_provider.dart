import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/BookScreen/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  BookingModel booking = BookingModel();

  void setRole(String value) {
    booking.role = value;
    notifyListeners();
  }

  void setEventType(String value) {
    booking.eventType = value;
    notifyListeners();
  }

  void setPackage(String value) {
    booking.package = value;
    notifyListeners();
  }

  void setRateCardItemId(String value) {
    booking.rateCardItemId = value;
    notifyListeners();
  }

  void setPackagePrice(double? value) {
    booking.packagePrice = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    booking.date = value;
    notifyListeners();
  }

  void setTimeRange(String start, String end) {
    booking.timeStart = start;
    booking.timeEnd = end;
    notifyListeners();
  }

  /// Legacy — used by the old booking page only.
  void setTime(String value) {
    booking.time = value;
    notifyListeners();
  }

  void setLocationType(String value) {
    booking.locationType = value;
    notifyListeners();
  }

  void setLocation(String value) {
    booking.location = value;
    notifyListeners();
  }

  void setUseStudioLocation(bool value) {
    booking.useStudioLocation = value;
    notifyListeners();
  }

  void setNumberOfOutfits(int? value) {
    booking.numberOfOutfits = value;
    notifyListeners();
  }

  void setNumberOfShootingLocations(int? value) {
    booking.numberOfShootingLocations = value;
    notifyListeners();
  }

  void setDeliverableType(String? value) {
    booking.deliverableType = value;
    notifyListeners();
  }

  void setNote(String value) {
    booking.note = value;
    notifyListeners();
  }

  void reset() {
    booking = BookingModel();
    notifyListeners();
  }

  void setEventTypeId(int? id) {
    booking.eventTypeId = id;
    notifyListeners();
  }

  /// Prime the form for a custom offer.
  void loadFromOffer({
    required String creativeId,
    required double price,
    required String priceLabel,
    String? offerId,
    String? note,
  }) {
    booking = BookingModel(
      creativeId: creativeId,
      isFromOffer: true,
      offerId: offerId,
      offerPrice: price,
      offerPriceLabel: priceLabel,
      note: note,
    );
    notifyListeners();
  }
}
