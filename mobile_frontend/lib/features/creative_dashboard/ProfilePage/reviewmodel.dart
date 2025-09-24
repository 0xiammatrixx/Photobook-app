class Review {
  final String userName;
  final String userProfileUrl;
  final int rating; // 1–5
  final String title;
  final String text;
  final DateTime date;

  Review({
    required this.userName,
    required this.userProfileUrl,
    required this.rating,
    required this.title,
    required this.text,
    required this.date,
  });
}
