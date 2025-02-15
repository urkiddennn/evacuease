class Messages {
  final String id;
  final String name;

  final String subject;
  final String type;
  final String message;
  final String createdAt;
  final String updatedAt;
  final int v;

  Messages({
    required this.id,
    required this.name,
    required this.subject,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Messages.fromJson(Map<String, dynamic> json) {
    return Messages(
      id: json['_id'],
      name: json['name'],
      subject: json['subject'],
      type: json['type'],
      message: json['message'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }
}
