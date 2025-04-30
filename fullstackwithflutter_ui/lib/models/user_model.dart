class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // API'den gelen veriyi yazdır (debug için)
    print('User.fromJson: $json');

    // API'den gelen veri yapısına göre farklı alanları kontrol et
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobileNumber': phoneNumber, // API'nin beklediği alan adı
    };
  }
}
