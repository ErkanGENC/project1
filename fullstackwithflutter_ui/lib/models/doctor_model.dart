class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String email;
  final String phoneNumber;
  final bool isAvailable;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.email,
    required this.phoneNumber,
    this.isAvailable = true,
    this.createdDate,
    this.updatedDate,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // API'den gelen veri yapısına göre farklı alanları kontrol et
    DateTime? createdDate;
    DateTime? updatedDate;

    // Tarih alanlarını işle
    if (json['createdDate'] != null) {
      try {
        createdDate = DateTime.parse(json['createdDate']);
      } catch (e) {
        // Tarih ayrıştırma hatası
      }
    }

    if (json['updatedDate'] != null) {
      try {
        updatedDate = DateTime.parse(json['updatedDate']);
      } catch (e) {
        // Tarih ayrıştırma hatası
      }
    }

    return Doctor(
      id: json['id'] ?? json['doctorId'] ?? json['doctor_id'] ?? 0,
      name: json['name'] ?? json['fullName'] ?? json['full_name'] ?? 'İsimsiz',
      specialization:
          json['specialization'] ?? json['specialty'] ?? 'Belirtilmemiş',
      email: json['email'] ?? json['mail'] ?? 'E-posta yok',
      phoneNumber: json['phoneNumber'] ??
          json['phone_number'] ??
          json['phone'] ??
          json['mobileNumber'] ??
          'Telefon numarası yok',
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      createdDate: createdDate,
      updatedDate: updatedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'email': email,
      'phoneNumber': phoneNumber,
      'isAvailable': isAvailable,
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
      if (updatedDate != null) 'updatedDate': updatedDate!.toIso8601String(),
    };
  }
}
