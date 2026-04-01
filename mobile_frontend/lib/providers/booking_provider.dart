import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/BookScreen/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  final String baseUrl = 'https://api.photobookhq.com/api';
  BookingModel booking = BookingModel();

  void setEventType(String value) {
    booking.eventType = value;
    notifyListeners();
  }

  void setPackage(String value) {
    booking.package = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    booking.date = value;
    notifyListeners();
  }

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

  void reset() {
    booking = BookingModel();
    notifyListeners();
  }

  void setEventTypeId(int? id) {
  booking.eventTypeId = id;
  notifyListeners();
}
  
}
