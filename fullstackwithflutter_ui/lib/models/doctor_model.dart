class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String email;
  final String phoneNumber;
  final bool isAvailable;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.email,
    required this.phoneNumber,
    required this.isAvailable,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // API'den gelen veriyi yazdır (debug için)
    print('Doctor.fromJson: $json');

    return Doctor(
      id: json['id'] ?? json['doctorId'] ?? json['doctor_id'] ?? 0,
      name: json['name'] ?? json['fullName'] ?? json['full_name'] ?? 'İsimsiz',
      specialization: json['specialization'] ?? json['specialty'] ?? 'Belirtilmemiş',
      email: json['email'] ?? json['mail'] ?? 'E-posta yok',
      phoneNumber: json['phoneNumber'] ??
          json['phone_number'] ??
          json['phone'] ??
          json['mobileNumber'] ??
          'Telefon numarası yok',
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
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
    };
  }
}
