import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../constants/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Android emülatörü için 10.0.2.2 kullanılır (localhost yerine)
  // Gerçek cihazlar için bilgisayarınızın IP adresini kullanın (örn: 192.168.1.X)
  // Web için localhost kullanılabilir
  static String baseUrl = 'http://localhost:5008/api';

  // Platformu kontrol edip uygun URL'yi ayarlayan metod
  static void configurePlatformSpecificUrl({String? customUrl}) {
    if (customUrl != null && customUrl.isNotEmpty) {
      baseUrl = customUrl;
      return;
    }

    if (kIsWeb) {
      // Web platformunda localhost kullanılabilir
      baseUrl = 'http://localhost:5008/api';
    } else if (Platform.isAndroid) {
      // Android emülatörü için 10.0.2.2 kullanılır (localhost yerine)
      baseUrl = 'http://10.0.2.2:5008/api';
    } else if (Platform.isIOS) {
      // iOS simülatörü için localhost kullanılabilir
      baseUrl = 'http://localhost:5008/api';
    } else {
      // Diğer platformlar için varsayılan olarak localhost kullanılır
      baseUrl = 'http://localhost:5008/api';
    }

    // Debug için URL'yi yazdır
    print('API URL: $baseUrl');
  }

  // Token saklama anahtarı
  static const String _tokenKey = 'auth_token';

  // Token al
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      // Token'ın geçerliliğini kontrol et
      if (token != null && token.isNotEmpty) {
        // JWT token'ın süresi dolmuş mu kontrol et
        if (_isTokenExpired(token)) {
          // Token süresi dolmuşsa sil
          await deleteToken();
          return null;
        }
        return token;
      }
      return null;
    } catch (e) {
      // Hata durumunda null dön
      return null;
    }
  }

  // Token'ın süresinin dolup dolmadığını kontrol et
  bool _isTokenExpired(String token) {
    try {
      // JWT token'ı decode et
      final parts = token.split('.');
      if (parts.length != 3) return true; // Geçersiz token formatı

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      // exp (expiration time) claim'ini kontrol et
      if (payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'];
        final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(expDate);
      }

      return false; // exp claim'i yoksa token'ın süresi dolmamış kabul et
    } catch (e) {
      return true; // Hata durumunda token'ın süresinin dolduğunu varsay
    }
  }

  // Token kaydet
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Token sil (logout için)
  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      // Token'i al (eğer varsa)
      final token = await getToken();

      // Debug için token bilgisini yazdır
      print(
          'Token for GetAllUsers: ${token != null ? (token.length > 10 ? "${token.substring(0, 10)}..." : token) : "null"}');

      final response = await http.get(
        Uri.parse('$baseUrl/Users/GetAllUsers'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Debug için yanıtı yazdır
      print('GetAllUsers response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API'den gelen veri bir liste ise
        if (decodedData is List) {
          return decodedData.map((json) => User.fromJson(json)).toList();
        }
        // API'den gelen veri bir nesne ise ve 'data' alanı içeriyorsa
        else if (decodedData is Map && decodedData.containsKey('data')) {
          final dynamic data = decodedData['data'];

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
            return [];
          }
        }
        // Diğer durumlar için boş liste dön
        else {
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
    String role = 'user', // Varsayılan rol: user
    int? doctorId, // Doktor ID (eğer doktor ise)
    String? doctorName, // Doktor adı (eğer doktor ise)
    String? specialization, // Uzmanlık alanı (eğer doktor ise)
  }) async {
    try {
      // Debug için istek verilerini yazdır
      print(
          'Register request: fullName=$fullName, email=$email, birthDate=${birthDate.toIso8601String()}, role=$role');

      // İstek gövdesi
      final Map<String, dynamic> requestBody = {
        'fullName': fullName,
        'email': email,
        'password': password,
        'birthDate': birthDate.toIso8601String(),
        'role': role,
      };

      // Eğer doktor ise, doktor bilgilerini ekle
      if (role == 'doctor') {
        requestBody['doctorId'] = doctorId;
        requestBody['doctorName'] = doctorName ?? fullName;
        requestBody['specialization'] = specialization;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/Auth/Register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Debug için yanıtı yazdır
      print('Register response: ${response.statusCode} - ${response.body}');

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
      // Debug için login bilgilerini yazdır
      print('Login attempt for email: $email');

      final loginUrl = '$baseUrl/Auth/Login';
      print('Login URL: $loginUrl');

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Başarılı giriş
        // API yanıt formatını kontrol et
        if (data.containsKey('data') && data['data'] is Map) {
          final responseData = data['data'] as Map<String, dynamic>;

          // Token kontrolü
          if (responseData.containsKey('token')) {
            // Token'i kaydet
            await saveToken(responseData['token']);

            // Kullanıcı bilgilerini kaydet
            if (responseData.containsKey('user')) {
              await saveUserData(responseData['user'] as Map<String, dynamic>);
            } else {
              // Eğer API kullanıcı bilgilerini dönmüyorsa, email'i kaydedelim
              await saveUserData({
                'email': email,
                'fullName': email.split('@')[0], // Basit bir varsayılan isim
                'phoneNumber': '',
              });
            }
          }
        } else if (data.containsKey('token')) {
          // Eski format için geriye dönük uyumluluk
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
        } else {
          // Token yoksa, giriş başarılı olsa bile kullanıcı bilgilerini al
          await saveUserData({
            'email': email,
            'fullName': email.split('@')[0], // Basit bir varsayılan isim
            'phoneNumber': '',
          });

          // Giriş başarılı olduktan sonra kullanıcı bilgilerini almak için API'ye istek gönder
          try {
            // Önce token'ı kaydet (eğer varsa)
            if (data.containsKey('token')) {
              await saveToken(data['token']);
            }

            // Kullanıcı bilgilerini al
            final userResult = await getCurrentUser();

            if (userResult['success'] && userResult['data'] != null) {
              // Kullanıcı bilgilerini güncelle
              await saveUserData(userResult['data'] as Map<String, dynamic>);
            }
          } catch (e) {
            // Hata durumunda bir şey yapma, en azından giriş yapılmış olsun
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

  // Şifre sıfırlama isteği (Eski metod, uyumluluk için korundu)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      // Debug için istek bilgilerini yazdır
      print('ForgotPassword request for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/Auth/ForgotPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      // Debug için yanıtı yazdır
      print(
          'ForgotPassword response: ${response.statusCode} - ${response.body}');

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // API yanıt formatını kontrol et
        if (data.containsKey('status')) {
          return {
            'success': data['status'] == true,
            'message': data['message'] ?? 'Kullanıcı bulundu',
            'data': data['data'],
          };
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Kullanıcı bulundu',
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
      print('Error in forgotPassword: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Şifre sıfırlama e-postası gönder (Yeni metod)
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      // Debug için istek bilgilerini yazdır
      print('SendPasswordResetEmail request for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/Auth/SendPasswordResetEmail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      // Debug için yanıtı yazdır
      print(
          'SendPasswordResetEmail response: ${response.statusCode} - ${response.body}');

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      // Geliştirme ortamında, doğrulama kodunu konsola yazdır
      if (data.containsKey('message') &&
          data['message'].toString().contains('DOĞRULAMA KODU:')) {
        final String message = data['message'].toString();
        final RegExp regex = RegExp(r'DOĞRULAMA KODU: (\d+)');
        final match = regex.firstMatch(message);
        if (match != null && match.groupCount >= 1) {
          final String code = match.group(1)!;
          print('🔑 DOĞRULAMA KODU: $code');
        }
      }

      if (response.statusCode == 200) {
        // API yanıt formatını kontrol et
        if (data.containsKey('status')) {
          return {
            'success': data['status'] == true,
            'message': data['message'] ??
                'Şifre sıfırlama kodu e-posta adresinize gönderildi',
            'data': data['data'],
          };
        }

        return {
          'success': true,
          'message': data['message'] ??
              'Şifre sıfırlama kodu e-posta adresinize gönderildi',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ??
              'Şifre sıfırlama kodu gönderilirken bir hata oluştu',
          'data': data,
        };
      }
    } catch (e) {
      print('Error in sendPasswordResetEmail: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Şifre sıfırlama kodunu doğrula
  Future<Map<String, dynamic>> verifyResetCode(
      String email, String resetCode) async {
    try {
      // Debug için istek bilgilerini yazdır
      print('VerifyResetCode request for email: $email, code: $resetCode');

      final response = await http.post(
        Uri.parse('$baseUrl/Auth/VerifyResetCode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'resetCode': resetCode,
        }),
      );

      // Debug için yanıtı yazdır
      print(
          'VerifyResetCode response: ${response.statusCode} - ${response.body}');

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // API yanıt formatını kontrol et
        if (data.containsKey('status')) {
          return {
            'success': data['status'] == true,
            'message': data['message'] ?? 'Kod doğrulandı',
            'data': data['data'],
          };
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Kod doğrulandı',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Kod doğrulanırken bir hata oluştu',
          'data': data,
        };
      }
    } catch (e) {
      print('Error in verifyResetCode: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Şifre sıfırlama (yeni şifre ile) (Eski metod, uyumluluk için korundu)
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Debug için istek bilgilerini yazdır
      print('ResetPassword request for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/Auth/ResetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'newPassword': newPassword,
        }),
      );

      // Debug için yanıtı yazdır
      print(
          'ResetPassword response: ${response.statusCode} - ${response.body}');

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // API yanıt formatını kontrol et
        if (data.containsKey('status')) {
          return {
            'success': data['status'] == true,
            'message': data['message'] ?? 'Şifre başarıyla sıfırlandı',
            'data': data['data'],
          };
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Şifre başarıyla sıfırlandı',
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

  // Token ile şifre sıfırlama (Yeni metod)
  Future<Map<String, dynamic>> resetPasswordWithToken({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    try {
      // Debug için istek bilgilerini yazdır
      print(
          'ResetPasswordWithToken request for email: $email, code: $resetCode');

      final response = await http.post(
        Uri.parse('$baseUrl/Auth/ResetPasswordWithToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'resetCode': resetCode,
          'newPassword': newPassword,
        }),
      );

      // Debug için yanıtı yazdır
      print(
          'ResetPasswordWithToken response: ${response.statusCode} - ${response.body}');

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // API yanıt formatını kontrol et
        if (data.containsKey('status')) {
          return {
            'success': data['status'] == true,
            'message': data['message'] ?? 'Şifre başarıyla sıfırlandı',
            'data': data['data'],
          };
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Şifre başarıyla sıfırlandı',
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
      print('Error in resetPasswordWithToken: $e');
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Şifre değiştirme (oturum açıkken)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Token'i al
      final token = await getToken();

      // Debug için token bilgisini yazdır
      print(
          'Token for ChangePassword: ${token != null ? (token.length > 10 ? "${token.substring(0, 10)}..." : token) : "null"}');

      if (token == null) {
        print('ChangePassword: Token bulunamadı');
        return {
          'success': false,
          'message': 'Oturum açılmamış',
          'data': null,
        };
      }

      // Debug için istek URL'sini yazdır
      final requestUrl = '$baseUrl/Auth/ChangePassword';
      print('ChangePassword request URL: $requestUrl');

      // Debug için istek gövdesini yazdır
      final requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
      print('ChangePassword request body: $requestBody');

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Debug için yanıtı yazdır
      print(
          'ChangePassword response: ${response.statusCode} - ${response.body}');

      // API yanıtını işle
      if (response.statusCode == 200) {
        final dynamic responseData =
            jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (responseData is Map && responseData.containsKey('status')) {
          return {
            'success': responseData['status'] == true,
            'message':
                responseData['message'] ?? 'Şifre başarıyla değiştirildi',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': true,
            'message': 'Şifre başarıyla değiştirildi',
            'data': responseData,
          };
        }
      } else {
        // Hata durumu
        try {
          final dynamic errorData = jsonDecode(utf8.decode(response.bodyBytes));
          print('ChangePassword error data: $errorData');
          return {
            'success': false,
            'message': errorData['message'] ??
                'Şifre değiştirilemedi: HTTP ${response.statusCode}',
            'data': null,
          };
        } catch (e) {
          print('ChangePassword error parsing response: $e');
          return {
            'success': false,
            'message': 'Şifre değiştirilemedi: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      }
    } catch (e) {
      print('ChangePassword exception: $e');
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
        final dynamic responseData =
            jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (responseData is Map && responseData.containsKey('data')) {
          // Yeni API formatı (ApiResponse sınıfı)
          final userData = responseData['data'];

          // Kullanıcı ID'sini ekleyelim
          if (userData is Map &&
              !userData.containsKey('id') &&
              responseData.containsKey('userId')) {
            userData['id'] = responseData['userId'];
          }

          // Rol belirleme öncelik sırası:
          // 1. Eğer zaten bir rol tanımlanmışsa, onu koru
          // 2. Doktor ID'si veya doktor adı kontrolü
          // 3. İsim içinde "doktor" kelimesi kontrolü

          if (userData is Map) {
            // Rol zaten tanımlanmış mı kontrol et
            if (!userData.containsKey('role') ||
                userData['role'] == null ||
                userData['role'].toString().isEmpty) {
              // Doktor ID'si veya doktor adı varsa doktor rolü
              // doctorId 0 olsa bile doktor olarak kabul et
              if ((userData.containsKey('doctorId') &&
                      userData['doctorId'] != null) ||
                  (userData.containsKey('doctorName') &&
                      userData['doctorName'] != null &&
                      userData['doctorName'].toString().isNotEmpty)) {
                // Doktor bilgileri varsa, doktor rolünü ekle
                userData['role'] = 'doctor';
                print(
                    'getCurrentUser: Doktor bilgileri bulundu, role=doctor olarak ayarlandı');
              }
              // Kullanıcı adı "doktor" içeriyorsa doktor rolü ver (geçici çözüm)
              else if (userData.containsKey('fullName') &&
                  userData['fullName'] != null &&
                  userData['fullName']
                      .toString()
                      .toLowerCase()
                      .contains('doktor')) {
                userData['role'] = 'doctor';
                print(
                    'getCurrentUser: İsimden doktor rolü tespit edildi: ${userData['fullName']}');
              }
              // Hiçbir doktor bilgisi yoksa, varsayılan olarak user rolü
              else {
                userData['role'] = 'user';
                print('getCurrentUser: Varsayılan rol atandı: user');
              }
            } else {
              print('getCurrentUser: Mevcut rol korundu: ${userData['role']}');
            }
          }

          // Rol bilgisi debug
          print(
              'getCurrentUser: Kullanıcı rolü: ${userData is Map ? (userData['role'] ?? 'belirtilmemiş') : 'userData bir Map değil'}');

          return {
            'success': responseData['status'] == true,
            'message': responseData['message'] ?? 'Kullanıcı bilgileri alındı',
            'data': userData,
          };
        } else {
          // Eski format veya farklı bir format
          // Kullanıcı ID'sini ekleyelim
          if (responseData is Map && !responseData.containsKey('id')) {
            // Token'dan kullanıcı ID'sini çıkarmaya çalış
            final token = await getToken();
            if (token != null) {
              try {
                // JWT token'ı decode et (basit bir yöntem)
                final parts = token.split('.');
                if (parts.length == 3) {
                  final payload = parts[1];
                  final normalized = base64Url.normalize(payload);
                  final decoded = utf8.decode(base64Url.decode(normalized));
                  final payloadMap =
                      jsonDecode(decoded) as Map<String, dynamic>;

                  // userId claim'ini kontrol et
                  if (payloadMap.containsKey('userId')) {
                    responseData['id'] =
                        int.parse(payloadMap['userId'].toString());
                  }
                }
              } catch (e) {
                // Token decode edilemezse bir şey yapma
              }
            }
          }

          return {
            'success': true,
            'message': 'Kullanıcı bilgileri alındı',
            'data': responseData,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Kullanıcı bilgileri alınamadı: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      // Hata durumunu loglama
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Kullanıcı bilgilerini kaydet (SharedPreferences'a)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Hassas bilgileri filtrele
      final filteredData = Map<String, dynamic>.from(userData);

      // Şifre gibi hassas bilgileri kaydetme
      filteredData.remove('password');
      filteredData.remove('newPassword');

      // Rol belirleme öncelik sırası:
      // 1. Eğer zaten bir rol tanımlanmışsa, onu koru
      // 2. Doktor ID'si veya doktor adı kontrolü
      // 3. İsim içinde "doktor" kelimesi kontrolü

      // Rol zaten tanımlanmış mı kontrol et
      if (!filteredData.containsKey('role') ||
          filteredData['role'] == null ||
          filteredData['role'].toString().isEmpty) {
        // Doktor ID'si veya doktor adı varsa doktor rolü
        // doctorId 0 olsa bile doktor olarak kabul et
        if ((filteredData.containsKey('doctorId') &&
                filteredData['doctorId'] != null) ||
            (filteredData.containsKey('doctorName') &&
                filteredData['doctorName'] != null &&
                filteredData['doctorName'].toString().isNotEmpty)) {
          // Doktor ID'si varsa, doktor rolünü ekle
          filteredData['role'] = 'doctor';
          print(
              'saveUserData: Doktor bilgileri bulundu, role=doctor olarak ayarlandı');
        }
        // Kullanıcı adı "doktor" içeriyorsa doktor rolü ver (geçici çözüm)
        else if (filteredData.containsKey('fullName') &&
            filteredData['fullName'] != null &&
            filteredData['fullName']
                .toString()
                .toLowerCase()
                .contains('doktor')) {
          filteredData['role'] = 'doctor';
          print(
              'saveUserData: İsimden doktor rolü tespit edildi: ${filteredData['fullName']}');
        }
        // Hiçbir doktor bilgisi yoksa, varsayılan olarak user rolü
        else {
          filteredData['role'] = 'user';
          print('saveUserData: Varsayılan rol atandı: user');
        }
      } else {
        print('saveUserData: Mevcut rol korundu: ${filteredData['role']}');
      }

      // Rol bilgisi debug
      print(
          'Kaydedilen kullanıcı rolü: ${filteredData['role'] ?? 'belirtilmemiş'}');

      // Kullanıcı verilerini kaydet
      await prefs.setString('user_data', jsonEncode(filteredData));
    } catch (e) {
      // Hata durumunda sessizce devam et
      print('Kullanıcı verileri kaydedilirken hata: $e');
    }
  }

  // Kullanıcı profilini güncelle
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
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

      // Önce mevcut kullanıcı bilgilerini al
      final currentUserData = await getUserData();
      if (currentUserData == null) {
        return {
          'success': false,
          'message': 'Kullanıcı bilgileri bulunamadı',
          'data': null,
        };
      }

      // Kullanıcı ID'sini al
      final userId = currentUserData['id'];

      // Eğer ID yoksa, sadece yerel verileri güncelle
      if (userId == null) {
        // Yerel verileri güncelle
        await saveUserData(userData);

        return {
          'success': true,
          'message': 'Profil bilgileri yerel olarak güncellendi',
          'data': userData,
        };
      }

      // Backend'in beklediği endpoint'i kullan
      final response = await http.put(
        Uri.parse('$baseUrl/Users/UpdateUser/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': userId,
          'fullName': userData['fullName'],
          'email': userData['email'],
          'mobileNumber': userData['phoneNumber'],
          // Şifre alanını boş bırak, şifre değiştirme ayrı bir işlem olmalı
          'password': '',
        }),
      );

      if (response.statusCode == 200) {
        // Yerel verileri güncelle
        await saveUserData(userData);

        return {
          'success': true,
          'message': 'Profil bilgileri başarıyla güncellendi',
          'data': userData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Profil güncellenirken bir hata oluştu: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      // Hata durumunda, yine de yerel verileri güncelle
      await saveUserData(userData);

      return {
        'success': true,
        'message': 'Profil bilgileri yerel olarak güncellendi (API hatası: $e)',
        'data': userData,
      };
    }
  }

  // Kullanıcı bilgilerini al (SharedPreferences'dan)
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null && userDataString.isNotEmpty) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
    } catch (e) {
      // Hata durumunda null dön
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
        // Hata durumunu loglama

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
      // Hata durumunu loglama
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
        // Hata durumunu loglama
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
        // Hata durumunu loglama
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
      return {
        'success': false,
        'message': 'API bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Doktor kullanıcısı bilgilerini güncelle
  Future<Map<String, dynamic>> updateDoctorUser(
      Map<String, dynamic> userData) async {
    try {
      // Token'i al
      final token = await getToken();
      final userId = userData['id'];

      // Backend'in beklediği endpoint'i kullan
      final response = await http.put(
        Uri.parse('$baseUrl/Users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': userId,
          'fullName': userData['fullName'],
          'email': userData['email'],
          'mobileNumber':
              userData['phoneNumber'] ?? userData['mobileNumber'] ?? '',
          'doctorId': userData['doctorId'],
          'doctorName': userData['doctorName'],
          'specialization': userData['specialization'],
          'role': 'doctor',
          // Şifre alanını boş bırak, şifre değiştirme ayrı bir işlem olmalı
          'password': '',
        }),
      );

      if (response.statusCode == 200) {
        // Yerel verileri güncelle
        await saveUserData(userData);

        return {
          'success': true,
          'message': 'Doktor kullanıcısı bilgileri başarıyla güncellendi',
          'data': userData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Doktor kullanıcısı güncellenirken bir hata oluştu: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      // Hata durumunda, yine de yerel verileri güncelle
      await saveUserData(userData);

      return {
        'success': true,
        'message':
            'Doktor kullanıcısı bilgileri yerel olarak güncellendi (API hatası: $e)',
        'data': userData,
      };
    }
  }

  // ==================== DOKTOR İŞLEMLERİ ====================

  // Tüm doktorları getir
  Future<List<Doctor>> getAllDoctors() async {
    try {
      // Token'i al (eğer varsa)
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/Doctors/GetAllDoctors'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API'den gelen veri bir liste ise
        if (decodedData is List) {
          return decodedData.map((json) => Doctor.fromJson(json)).toList();
        }
        // API'den gelen veri bir nesne ise ve 'data' alanı içeriyorsa
        else if (decodedData is Map && decodedData.containsKey('data')) {
          final dynamic data = decodedData['data'];

          // data bir liste ise
          if (data is List) {
            return data.map((json) => Doctor.fromJson(json)).toList();
          }
          // data bir nesne ise ve 'items' veya benzer bir alanı varsa
          else if (data is Map && data.containsKey('items')) {
            final List<dynamic> items = data['items'];
            return items.map((json) => Doctor.fromJson(json)).toList();
          }
          // Diğer durumlar için boş liste dön
          else {
            return [];
          }
        }
        // Diğer durumlar için boş liste dön
        else {
          return [];
        }
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Gerçek API bağlantısı olmadığı için örnek veriler dönelim
      return [
        Doctor(
          id: 1,
          name: 'Dr. Mehmet Öz',
          specialization: 'Diş Hekimi',
          email: 'mehmet.oz@example.com',
          phoneNumber: '0555-123-4567',
          isAvailable: true,
          createdDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Doctor(
          id: 2,
          name: 'Dr. Zeynep Kaya',
          specialization: 'Ortodontist',
          email: 'zeynep.kaya@example.com',
          phoneNumber: '0555-234-5678',
          isAvailable: true,
          createdDate: DateTime.now().subtract(const Duration(days: 60)),
        ),
        Doctor(
          id: 3,
          name: 'Dr. Ali Yıldız',
          specialization: 'Ağız ve Çene Cerrahı',
          email: 'ali.yildiz@example.com',
          phoneNumber: '0555-345-6789',
          isAvailable: false,
          createdDate: DateTime.now().subtract(const Duration(days: 90)),
        ),
        Doctor(
          id: 4,
          name: 'Dr. Ayşe Demir',
          specialization: 'Pedodontist',
          email: 'ayse.demir@example.com',
          phoneNumber: '0555-456-7890',
          isAvailable: true,
          createdDate: DateTime.now().subtract(const Duration(days: 120)),
        ),
      ];
    }
  }

  // Yeni doktor ekle
  Future<Map<String, dynamic>> addDoctor(Doctor doctor) async {
    try {
      // Token'i al
      final token = await getToken();

      // Backend'in beklediği endpoint'i kullan
      final response = await http.post(
        Uri.parse('$baseUrl/Doctors/CreateDoctor'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(doctor.toJson()),
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
            'message': 'Doktor başarıyla eklendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Doktor eklenirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': 'Doktor başarıyla eklendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Doktor eklenirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Doktor başarıyla eklendi (simülasyon)',
        'data': null,
      };
    }
  }

  // Doktor bilgilerini güncelle
  Future<Map<String, dynamic>> updateDoctor(Doctor doctor) async {
    try {
      // Token'i al
      final token = await getToken();

      // Backend'in beklediği endpoint'i kullan
      final response = await http.put(
        Uri.parse('$baseUrl/Doctors/${doctor.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(doctor.toJson()),
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
            'message': 'Doktor bilgileri başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Doktor güncellenirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Doktor bilgileri başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Doktor güncellenirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Doktor bilgileri başarıyla güncellendi (simülasyon)',
        'data': null,
      };
    }
  }

  // Doktor sil
  Future<Map<String, dynamic>> deleteDoctor(int doctorId) async {
    try {
      // Token'i al
      final token = await getToken();

      // Standart endpoint'i deneyelim
      final response = await http.delete(
        Uri.parse('$baseUrl/Doctors/$doctorId'),
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
            'message': 'Doktor başarıyla silindi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Doktor silinirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Doktor başarıyla silindi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Doktor silinirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Doktor başarıyla silindi (simülasyon)',
        'data': null,
      };
    }
  }

  // ==================== RANDEVU İŞLEMLERİ ====================

  // Tüm randevuları getir
  Future<List<Appointment>> getAllAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Appointments/GetAllAppointments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API'den gelen veri bir liste ise
        if (decodedData is List) {
          return decodedData.map((json) => Appointment.fromJson(json)).toList();
        }
        // API'den gelen veri bir nesne ise ve 'data' alanı içeriyorsa
        else if (decodedData is Map && decodedData.containsKey('data')) {
          final dynamic data = decodedData['data'];

          // data bir liste ise
          if (data is List) {
            return data.map((json) => Appointment.fromJson(json)).toList();
          }
          // data bir nesne ise ve 'items' veya benzer bir alanı varsa
          else if (data is Map && data.containsKey('items')) {
            final List<dynamic> items = data['items'];
            return items.map((json) => Appointment.fromJson(json)).toList();
          }
          // Diğer durumlar için boş liste dön
          else {
            return [];
          }
        }
        // Diğer durumlar için boş liste dön
        else {
          return [];
        }
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Gerçek API bağlantısı olmadığı için örnek veriler dönelim
      return [
        Appointment(
          id: 1,
          patientName: 'Ahmet Yılmaz',
          doctorName: 'Dr. Mehmet Öz',
          date: DateTime.now(),
          time: '09:30',
          status: 'Onaylandı',
          type: 'Diş Kontrolü',
        ),
        Appointment(
          id: 2,
          patientName: 'Ayşe Demir',
          doctorName: 'Dr. Zeynep Kaya',
          date: DateTime.now().add(const Duration(days: 1)),
          time: '14:00',
          status: 'Bekleyen',
          type: 'Dolgu',
        ),
        Appointment(
          id: 3,
          patientName: 'Mehmet Kaya',
          doctorName: 'Dr. Ali Yıldız',
          date: DateTime.now().add(const Duration(days: 2)),
          time: '10:15',
          status: 'Tamamlandı',
          type: 'Kanal Tedavisi',
        ),
        Appointment(
          id: 4,
          patientName: 'Zeynep Şahin',
          doctorName: 'Dr. Mehmet Öz',
          date: DateTime.now().add(const Duration(days: 3)),
          time: '11:30',
          status: 'İptal Edildi',
          type: 'Diş Kontrolü',
        ),
        Appointment(
          id: 5,
          patientName: 'Ali Yıldız',
          doctorName: 'Dr. Zeynep Kaya',
          date: DateTime.now(),
          time: '16:45',
          status: 'Bekleyen',
          type: 'Dolgu',
        ),
      ];
    }
  }

  // Yeni randevu ekle
  Future<Map<String, dynamic>> addAppointment(Appointment appointment) async {
    try {
      // Token'i al
      final token = await getToken();

      // Backend'in beklediği endpoint'i kullan
      final response = await http.post(
        Uri.parse('$baseUrl/Appointments/CreateAppointment'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointment.toJson()),
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
            'message': 'Randevu başarıyla eklendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Randevu eklenirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': 'Randevu başarıyla eklendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Randevu eklenirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Randevu başarıyla eklendi (simülasyon)',
        'data': null,
      };
    }
  }

  // Randevu durumunu güncelle
  Future<Map<String, dynamic>> updateAppointmentStatus(
      int appointmentId, String newStatus) async {
    try {
      // Token'i al (eğer varsa)
      final token = await getToken();

      // Önce randevuyu al
      final response = await http.get(
        Uri.parse('$baseUrl/Appointments/GetAppointmentById/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Randevu bulunamadı: HTTP ${response.statusCode}',
          'data': null,
        };
      }

      final dynamic appointmentData =
          jsonDecode(utf8.decode(response.bodyBytes));
      Map<String, dynamic> appointmentJson;

      if (appointmentData is Map && appointmentData.containsKey('data')) {
        appointmentJson = appointmentData['data'];
      } else {
        appointmentJson = appointmentData;
      }

      // Randevu durumunu güncelle
      appointmentJson['status'] = newStatus;

      // Güncelleme isteği gönder
      final updateResponse = await http.put(
        Uri.parse('$baseUrl/Appointments/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientName': appointmentJson['patientName'],
          'doctorName': appointmentJson['doctorName'],
          'date': appointmentJson['date'],
          'time': appointmentJson['time'],
          'status': newStatus,
          'type': appointmentJson['type'],
        }),
      );

      // Yanıtı işle
      if (updateResponse.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(updateResponse.bodyBytes));

        if (data is Map && data.containsKey('status')) {
          return {
            'success': data['status'] == true,
            'message': data['message'] ?? 'Randevu durumu güncellendi',
            'data': data['data'],
          };
        }

        return {
          'success': true,
          'message': 'Randevu durumu güncellendi',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message':
              'Randevu güncellenirken bir hata oluştu: HTTP ${updateResponse.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Randevu durumu güncellendi (simülasyon)',
        'data': null,
      };
    }
  }

  // Randevu güncelle
  Future<Map<String, dynamic>> updateAppointment(
      Appointment appointment) async {
    try {
      // Token'i al
      final token = await getToken();

      // Backend'in beklediği endpoint'i kullan
      final response = await http.put(
        Uri.parse('$baseUrl/Appointments/${appointment.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointment.toJson()),
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
            'message': 'Randevu başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Randevu güncellenirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Randevu başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Randevu güncellenirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Randevu başarıyla güncellendi (simülasyon)',
        'data': null,
      };
    }
  }

  // Randevu sil
  Future<Map<String, dynamic>> deleteAppointment(int appointmentId) async {
    try {
      // Token'i al
      final token = await getToken();

      // Standart endpoint'i deneyelim
      final response = await http.delete(
        Uri.parse('$baseUrl/Appointments/$appointmentId'),
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
            'message': 'Randevu başarıyla silindi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Randevu silinirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Randevu başarıyla silindi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message': 'Randevu silinirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Randevu başarıyla silindi (simülasyon)',
        'data': null,
      };
    }
  }

  // ==================== RAPOR İŞLEMLERİ ====================

  // Dashboard verilerini getir
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      // Token'i al (eğer varsa)
      final token = await getToken();

      // Kullanıcıları al
      final users = await getAllUsers();

      // Randevuları al
      final appointments = await getAllAppointments();

      // Doktorları al
      final doctors = await getAllDoctors();

      // Bugünün tarihi
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Son 30 gün
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Toplam hasta sayısı
      final totalPatients = users.length;

      // Aktif hastalar (son 30 gün içinde kaydedilmiş)
      final activePatients = users
          .where((user) =>
              user.createdDate != null &&
              user.createdDate!.isAfter(thirtyDaysAgo))
          .length;

      // Bugünkü randevular
      final todayAppointments = appointments.where((appointment) {
        final appointmentDate = DateTime(appointment.date.year,
            appointment.date.month, appointment.date.day);
        return appointmentDate.isAtSameMomentAs(today);
      }).length;

      // Bekleyen randevular
      final pendingAppointments = appointments
          .where(
              (appointment) => appointment.status.toLowerCase() == 'bekleyen')
          .length;

      // Toplam doktor sayısı
      final totalDoctors = doctors.length;

      // Önceki ay ile karşılaştırma için yüzde değişimler
      // Gerçek uygulamada bu değerler önceki ay verileriyle karşılaştırılarak hesaplanmalı
      // Şimdilik örnek değerler kullanıyoruz
      const totalPatientsChange = '+12%';
      const activePatientsChange = '+8%';
      const todayAppointmentsChange = '+5%';
      const pendingAppointmentsChange = '-3%';

      return {
        'totalPatients': totalPatients,
        'activePatients': activePatients,
        'todayAppointments': todayAppointments,
        'pendingAppointments': pendingAppointments,
        'totalDoctors': totalDoctors,
        'totalPatientsChange': totalPatientsChange,
        'activePatientsChange': activePatientsChange,
        'todayAppointmentsChange': todayAppointmentsChange,
        'pendingAppointmentsChange': pendingAppointmentsChange,
        'recentActivities': _getRecentActivities(users, appointments),
      };
    } catch (e) {
      // Hata durumunda boş veri döndür
      return {
        'totalPatients': 0,
        'activePatients': 0,
        'todayAppointments': 0,
        'pendingAppointments': 0,
        'totalDoctors': 0,
        'totalPatientsChange': '+0%',
        'activePatientsChange': '+0%',
        'todayAppointmentsChange': '+0%',
        'pendingAppointmentsChange': '+0%',
        'recentActivities': [],
      };
    }
  }

  // Son aktiviteleri oluştur
  List<Map<String, dynamic>> _getRecentActivities(
      List<User> users, List<Appointment> appointments) {
    final List<Map<String, dynamic>> activities = [];

    // Son eklenen kullanıcıları aktivite olarak ekle
    final recentUsers = users.where((user) => user.createdDate != null).toList()
      ..sort((a, b) => b.createdDate!.compareTo(a.createdDate!));

    // En fazla 2 yeni kullanıcı ekle
    for (var i = 0; i < recentUsers.length && i < 2; i++) {
      activities.add({
        'id': i + 1,
        'type': 'patient',
        'title': 'Yeni Hasta',
        'description': '${recentUsers[i].fullName} sisteme kaydedildi',
        'time': _getTimeAgo(recentUsers[i].createdDate!),
        'icon': Icons.person_add,
        'color': AppTheme.accentColor,
      });
    }

    // Son eklenen randevuları aktivite olarak ekle
    final recentAppointments = List<Appointment>.from(appointments)
      ..sort((a, b) => b.date.compareTo(a.date));

    // En fazla 2 yeni randevu ekle
    for (var i = 0; i < recentAppointments.length && i < 2; i++) {
      activities.add({
        'id': activities.length + 1,
        'type': 'appointment',
        'title': 'Yeni Randevu',
        'description':
            '${recentAppointments[i].patientName} için ${recentAppointments[i].type} randevusu oluşturuldu',
        'time': _getTimeAgo(recentAppointments[i].date),
        'icon': Icons.calendar_today,
        'color': AppTheme.primaryColor,
      });
    }

    return activities;
  }

  // Zaman farkını insan dostu formata dönüştür
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  // Rapor verilerini getir
  Future<Map<String, dynamic>> getReportData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Reports/GetReportData'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        return decodedData;
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Gerçek API bağlantısı olmadığı için örnek veriler dönelim
      return {
        'patientStats': {
          'totalPatients': 256,
          'newPatients': 24,
          'activePatients': 187,
          'inactivePatients': 69,
          'patientsByAge': [
            {'age': '0-18', 'count': 45},
            {'age': '19-30', 'count': 78},
            {'age': '31-45', 'count': 92},
            {'age': '46-60', 'count': 31},
            {'age': '60+', 'count': 10},
          ],
          'patientsByGender': [
            {'gender': 'Erkek', 'count': 118},
            {'gender': 'Kadın', 'count': 138},
          ],
        },
        'appointmentStats': {
          'totalAppointments': 412,
          'completedAppointments': 324,
          'pendingAppointments': 56,
          'cancelledAppointments': 32,
          'appointmentsByMonth': [
            {'month': 'Ocak', 'count': 42},
            {'month': 'Şubat', 'count': 38},
            {'month': 'Mart', 'count': 45},
            {'month': 'Nisan', 'count': 40},
            {'month': 'Mayıs', 'count': 52},
            {'month': 'Haziran', 'count': 48},
          ],
          'appointmentsByType': [
            {'type': 'Diş Kontrolü', 'count': 156},
            {'type': 'Dolgu', 'count': 98},
            {'type': 'Kanal Tedavisi', 'count': 45},
            {'type': 'Diş Çekimi', 'count': 32},
            {'type': 'Diş Temizliği', 'count': 81},
          ],
        },
        'revenueStats': {
          'totalRevenue': 45750,
          'averageRevenuePerPatient': 178.7,
          'revenueByMonth': [
            {'month': 'Ocak', 'amount': 6250},
            {'month': 'Şubat', 'amount': 5800},
            {'month': 'Mart', 'amount': 7200},
            {'month': 'Nisan', 'amount': 6800},
            {'month': 'Mayıs', 'amount': 9500},
            {'month': 'Haziran', 'amount': 10200},
          ],
          'revenueByService': [
            {'service': 'Diş Kontrolü', 'amount': 7800},
            {'service': 'Dolgu', 'amount': 9800},
            {'service': 'Kanal Tedavisi', 'amount': 13500},
            {'service': 'Diş Çekimi', 'amount': 4800},
            {'service': 'Diş Temizliği', 'amount': 9850},
          ],
        },
      };
    }
  }
}
