class Review {
  final String userName;
  final String? userProfileUrl;
  final int rating; // 1–5
  final String title;
  final String text;
  final DateTime date;

  Review({
    required this.userName,
    this.userProfileUrl,
    required this.rating,
    required this.title,
    required this.text,
    required this.date,
  });

  /// Flexible parser for review objects from the API — tolerates
  /// snake_case/camelCase and a nested `reviewer` object.
  factory Review.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] is Map
        ? Map<String, dynamic>.from(json['reviewer'])
        : json;

    final rating = int.tryParse(
      (json['rating'] ?? json['stars'] ?? '0').toString(),
    );

    DateTime date;
    try {
      date = DateTime.parse(
        (json['created_at'] ?? json['createdAt'] ?? json['date'] ?? '')
            .toString(),
      );
    } catch (_) {
      date = DateTime.now();
    }

    return Review(
      userName:
          (reviewer['name'] ??
                  json['clientName'] ??
                  json['client_name'] ??
                  json['user_name'] ??
                  json['reviewer_name'] ??
                  'Client')
              .toString(),
      userProfileUrl:
          (reviewer['profile_photo_url'] ??
                  reviewer['avatar_url'] ??
                  json['user_avatar_url'] ??
                  json['client_avatar_url'])
              ?.toString(),
      rating: rating ?? 0,
      title: (json['title'] ?? json['headline'] ?? '').toString(),
      text: (json['text'] ?? json['comment'] ?? json['review'] ?? '')
          .toString(),
      date: date,
    );
  }
}
