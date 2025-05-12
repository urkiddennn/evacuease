class Survey {
  final String title;
  final String? link;
  final DateTime createdAt;

  Survey({
    required this.title,
    this.link,
    required this.createdAt,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      title: json['title'] ?? 'Untitled Survey',
      link: json['link'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
