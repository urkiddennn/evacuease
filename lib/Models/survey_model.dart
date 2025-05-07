class Survey {
  final String title;
  final String? description;
  final String? link;
  final DateTime createdAt;

  Survey({required this.title, this.description, this.link, required this.createdAt});

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      link: json['link'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
