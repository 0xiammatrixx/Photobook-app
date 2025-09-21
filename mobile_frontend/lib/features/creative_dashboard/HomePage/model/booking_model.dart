class Booking {
  final String name;
  final String type;
  final DateTime date;
  final String location;
  final String time;

  Booking({
    required this.name,
    required this.type,
    required this.date,
    required this.location,
    required this.time,
  });
}

class Activity {
  final String message;
  final String time;

  Activity({
    required this.message,
    required this.time,
  });
}
