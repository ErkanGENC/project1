class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final int? doctorId;
  final String? doctorName;
  final String? specialization;
  String role; // Kullanıcı rolü: 'user', 'doctor', 'admin'

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.createdDate,
    this.updatedDate,
    this.doctorId,
    this.doctorName,
    this.specialization,
    this.role = 'user', // Varsayılan rol: user
  });

  factory User.fromJson(Map<String, dynamic> json) {
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

    // Doktor bilgilerini kontrol et
    int? doctorId;
    String? doctorName;
    String? specialization;

    if (json['doctorId'] != null) {
      doctorId = json['doctorId'] is String
          ? int.tryParse(json['doctorId'])
          : json['doctorId'];
    }

    doctorName = json['doctorName'] ?? json['doctor_name'];
    specialization = json['specialization'] ?? json['doctor_specialization'];

    // Rol bilgisini kontrol et
    String role = 'user'; // Varsayılan rol

    // API'den gelen rol bilgisini kontrol et
    if (json['role'] != null) {
      role = json['role'];
    }

    return User(
      id: json['id'] ?? json['userId'] ?? json['user_id'] ?? 0,
      fullName:
          json['fullName'] ?? json['full_name'] ?? json['name'] ?? 'İsimsiz',
      email: json['email'] ?? json['mail'] ?? 'E-posta yok',
      phoneNumber: json['phoneNumber'] ??
          json['phone_number'] ??
          json['phone'] ??
          json['mobileNumber'] ??
          'Telefon numarası yok',
      createdDate: createdDate,
      updatedDate: updatedDate,
      doctorId: doctorId,
      doctorName: doctorName,
      specialization: specialization,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobileNumber': phoneNumber, // API'nin beklediği alan adı
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
      if (updatedDate != null) 'updatedDate': updatedDate!.toIso8601String(),
      if (doctorId != null) 'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      if (specialization != null) 'specialization': specialization,
      'role': role,
    };
  }
}
