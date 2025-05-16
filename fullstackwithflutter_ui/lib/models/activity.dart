class Activity {
  final int id;
  final String? type;
  final String? description;
  final int? userId;
  final String? userName;
  final DateTime createdDate;
  final String? details;
  final String? icon;
  final String? color;

  Activity({
    required this.id,
    this.type,
    this.description,
    this.userId,
    this.userName,
    required this.createdDate,
    this.details,
    this.icon,
    this.color,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      type: json['type'],
      description: json['description'],
      userId: json['userId'],
      userName: json['userName'],
      createdDate: DateTime.parse(json['createdDate']),
      details: json['details'],
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'userId': userId,
      'userName': userName,
      'createdDate': createdDate.toIso8601String(),
      'details': details,
      'icon': icon,
      'color': color,
    };
  }
}
