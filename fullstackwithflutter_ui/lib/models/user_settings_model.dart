class UserSettings {
  final int id;
  final int userId;
  bool isDarkMode;
  String fontFamily;
  double fontSize;
  String language;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  UserSettings({
    this.id = 0,
    required this.userId,
    this.isDarkMode = false,
    this.fontFamily = 'Default',
    this.fontSize = 1.0,
    this.language = 'tr',
    this.createdDate,
    this.updatedDate,
  });

  // JSON'dan UserSettings nesnesine dönüştürme
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    // Tarih alanlarını işle
    DateTime? createdDate;
    if (json['createdDate'] != null) {
      try {
        createdDate = DateTime.parse(json['createdDate']);
      } catch (e) {
        // Tarih ayrıştırma hatası
      }
    }

    DateTime? updatedDate;
    if (json['updatedDate'] != null) {
      try {
        updatedDate = DateTime.parse(json['updatedDate']);
      } catch (e) {
        // Tarih ayrıştırma hatası
      }
    }

    return UserSettings(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      isDarkMode: json['isDarkMode'] ?? false,
      fontFamily: json['fontFamily'] ?? 'Default',
      fontSize: json['fontSize']?.toDouble() ?? 1.0,
      language: json['language'] ?? 'tr',
      createdDate: createdDate,
      updatedDate: updatedDate,
    );
  }

  // UserSettings nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'isDarkMode': isDarkMode,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'language': language,
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
      if (updatedDate != null) 'updatedDate': updatedDate!.toIso8601String(),
    };
  }

  // Ayarları kopyalama
  UserSettings copyWith({
    int? id,
    int? userId,
    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    String? language,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      language: language ?? this.language,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}
