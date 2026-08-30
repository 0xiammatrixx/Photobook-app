/// Booking model — supports the three creative roles, custom-offer mode,
/// and all the extra fields from the sessions API.
class BookingModel {
  String? creativeId;
  String? role; // 'photographer' | 'videographer' | 'content_creator'
  String? eventType; // generic: Event Type or Content Type
  String? package; // package display name from the rate card
  String? rateCardItemId; // UUID of the selected rate card item
  double? packagePrice; // rate card pricing_amount
  DateTime? date;
  String? timeStart; // "HH:mm" 24h
  String? timeEnd; // "HH:mm" 24h
  String? locationType; // Indoor / Outdoor / Remote
  String? location;
  String? time; // legacy alias — kept for the old booking page
  bool useStudioLocation = false;
  int? numberOfOutfits;
  int? numberOfShootingLocations;
  String? deliverableType;
  String? note;
  int? eventTypeId;

  // Custom offer mode — fields locked in from the offer.
  bool isFromOffer = false;
  String? offerId;
  double? offerPrice;
  String? offerPriceLabel;

  BookingModel({
    this.creativeId,
    this.role,
    this.eventType,
    this.package,
    this.rateCardItemId,
    this.packagePrice,
    this.date,
    this.timeStart,
    this.timeEnd,
    this.locationType,
    this.location,
    this.useStudioLocation = false,
    this.numberOfOutfits,
    this.numberOfShootingLocations,
    this.deliverableType,
    this.note,
    this.eventTypeId,
    this.isFromOffer = false,
    this.offerId,
    this.offerPrice,
    this.offerPriceLabel,
  });

  /// Estimated duration in minutes from the time range.
  int? get estimatedDurationMinutes {
    if (timeStart == null || timeEnd == null) return null;
    final start = _parseTime(timeStart!);
    final end = _parseTime(timeEnd!);
    if (start == null || end == null) return null;
    final diff = end.difference(start);
    return diff.isNegative ? diff.inMinutes + 1440 : diff.inMinutes;
  }

  static DateTime? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(2000, 1, 1, h, m);
  }
}