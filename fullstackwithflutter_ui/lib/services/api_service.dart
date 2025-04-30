import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Android emülatörü için 10.0.2.2 kullanılır (localhost yerine)
  // Gerçek cihazlar için bilgisayarınızın IP adresini kullanın (örn: 192.168.1.X)
  // Web için localhost kullanılabilir
  static String baseUrl = 'https://localhost:7159/api';

  // Platformu kontrol edip uygun URL'yi ayarlayan metod
  static void configurePlatformSpecificUrl({String? customUrl}) {
    if (customUrl != null && customUrl.isNotEmpty) {
      baseUrl = customUrl;
      return;
    }

    if (kIsWeb) {
      // Web platformunda localhost kullanılabilir
      baseUrl = 'https://localhost:7159/api';
    } else if (Platform.isAndroid) {
      // Android emülatörü için 10.0.2.2 kullanılır (localhost yerine)
      baseUrl = 'https://10.0.2.2:7159/api';
    } else if (Platform.isIOS) {
      // iOS simülatörü için localhost kullanılabilir
      baseUrl = 'https://localhost:7159/api';
    } else {
      // Diğer platformlar için varsayılan olarak localhost kullanılır
      baseUrl = 'https://localhost:7159/api';
    }
  }

  // Token saklama anahtarı
  static const String _tokenKey = 'auth_token';

  // Token al
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Token kaydet
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Token sil (logout için)
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Users/GetAllUsers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // Debug: API'den gelen veriyi yazdır
        print('API Response: $decodedData');
        print('API Response Type: ${decodedData.runtimeType}');

        // API'den gelen veri bir liste ise
        if (decodedData is List) {
          return decodedData.map((json) => User.fromJson(json)).toList();
        }
        // API'den gelen veri bir nesne ise ve 'data' alanı içeriyorsa
        else if (decodedData is Map && decodedData.containsKey('data')) {
          final dynamic data = decodedData['data'];
          print('Data field: $data');
          print('Data field type: ${data.runtimeType}');

          // data bir liste ise
          if (data is List) {
            return data.map((json) => User.fromJson(json)).toList();
          }
          // data bir nesne ise ve 'items' veya benzer bir alanı varsa
          else if (data is Map && data.containsKey('items')) {
            final List<dynamic> items = data['items'];
            return items.map((json) => User.fromJson(json)).toList();
          }
          // Diğer durumlar için boş liste dön
          else {
            print('Data field is not a list or does not contain items');
            return [];
          }
        }
        // Diğer durumlar için boş liste dön
        else {
          print('API response is not a list or does not contain data field');
          return [];
        }
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('API bağlantı hatası: $e');
    }
  }

  // Kullanıcı kayıt (Register)
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required DateTime birthDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/Register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'birthDate': birthDate.toIso8601String(),
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Başarılı kayıt
        return {
          'success': true,
          'message': 'Kayıt başarılı',
          'data': data,
        };
      } else {
        // Hata durumu
        return {
          'success': false,
          'message': data['message'] ?? 'Kayıt sırasında bir hata oluştu',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Kullanıcı girişi (Login)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/Login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Başarılı giriş
        if (data.containsKey('token')) {
          // Token'i kaydet
          await saveToken(data['token']);

          // Kullanıcı bilgilerini kaydet
          if (data.containsKey('user')) {
            await saveUserData(data['user'] as Map<String, dynamic>);
          } else {
            // Eğer API kullanıcı bilgilerini dönmüyorsa, email'i kaydedelim
            await saveUserData({
              'email': email,
              'fullName': email.split('@')[0], // Basit bir varsayılan isim
              'phoneNumber': '',
            });
          }
        }

        return {
          'success': true,
          'message': 'Giriş başarılı',
          'data': data,
        };
      } else {
        // Hata durumu
        return {
          'success': false,
          'message': data['message'] ?? 'Giriş sırasında bir hata oluştu',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Şifre sıfırlama isteği
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/ForgotPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Sıfırlama bağlantısı gönderildi',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? 'Şifre sıfırlama sırasında bir hata oluştu',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Şifre sıfırlama (yeni şifre ile)
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/ResetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'newPassword': newPassword,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Şifre başarıyla sıfırlandı',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? 'Şifre sıfırlama sırasında bir hata oluştu',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Mevcut kullanıcı bilgilerini al
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // Token'i al
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Oturum açılmamış',
          'data': null,
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/Users/GetCurrentUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));

        // Debug: API'den gelen veriyi yazdır
        print('Current User API Response: $data');

        return {
          'success': true,
          'message': 'Kullanıcı bilgileri alındı',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Kullanıcı bilgileri alınamadı: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('Error getting current user: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Kullanıcı bilgilerini kaydet (SharedPreferences'a)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  // Kullanıcı bilgilerini al (SharedPreferences'dan)
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }

    return null;
  }

  // Çıkış yap (Logout)
  Future<bool> logout() async {
    try {
      // Token'i ve kullanıcı bilgilerini sil
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove('user_data');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Yeni hasta ekle
  Future<Map<String, dynamic>> addUser(User user) async {
    try {
      // Token'i al
      final token = await getToken();

      // Backend'in beklediği endpoint'i kullan
      final response = await http.post(
        Uri.parse('$baseUrl/Users/CreateNewUser'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      // Yanıtı işle
      try {
        // Yanıt boş değilse parse et
        if (response.body.isNotEmpty) {
          final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));

          // API yanıt formatını kontrol et
          if (data is Map && data.containsKey('status')) {
            return {
              'success': data['status'] == true,
              'message': data['message'] ?? 'İşlem tamamlandı',
              'data': data['data'],
            };
          }
        }

        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': 'Hasta başarıyla eklendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Hasta eklenirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        print('Error parsing response: $e');

        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': 'Hasta başarıyla eklendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Hasta eklenirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      print('Error adding user: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Hasta bilgilerini güncelle
  Future<Map<String, dynamic>> updateUser(User user) async {
    try {
      // Token'i al
      final token = await getToken();

      // Backend'in beklediği endpoint'i kullan
      final response = await http.put(
        Uri.parse('$baseUrl/Users/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      // Yanıtı işle
      try {
        // Yanıt boş değilse parse et
        if (response.body.isNotEmpty) {
          final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));

          // API yanıt formatını kontrol et
          if (data is Map && data.containsKey('status')) {
            return {
              'success': data['status'] == true,
              'message': data['message'] ?? 'İşlem tamamlandı',
              'data': data['data'],
            };
          }
        }

        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Hasta bilgileri başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Hasta güncellenirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        print('Error parsing response: $e');

        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Hasta bilgileri başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Hasta güncellenirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      print('Error updating user: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Hasta sil
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      // Token'i al
      final token = await getToken();

      // Standart endpoint'i deneyelim
      final response = await http.delete(
        Uri.parse('$baseUrl/Users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Yanıtı işle
      try {
        // Yanıt boş değilse parse et
        if (response.body.isNotEmpty) {
          final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));

          // API yanıt formatını kontrol et
          if (data is Map && data.containsKey('status')) {
            return {
              'success': data['status'] == true,
              'message': data['message'] ?? 'İşlem tamamlandı',
              'data': data['data'],
            };
          }
        }

        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Hasta başarıyla silindi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Hasta silinirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        print('Error parsing response: $e');

        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Hasta başarıyla silindi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Hasta silinirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      print('Error deleting user: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }
}
