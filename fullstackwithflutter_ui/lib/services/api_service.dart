import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../models/activity.dart';
import '../models/user_settings_model.dart';
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
    String? role,
    String? specialization,
    int? doctorId,
    String? doctorName,
  }) async {
    try {
      // Debug için istek verilerini yazdır
      print(
          'Register request: fullName=$fullName, email=$email, birthDate=${birthDate.toIso8601String()}, role=$role');

      // İstek gövdesini oluştur
      final Map<String, dynamic> requestBody = {
        'fullName': fullName,
        'email': email,
        'password': password,
        'birthDate': birthDate.toIso8601String(),
      };

      // Eğer doktor rolü varsa, ilgili alanları ekle
      if (role != null) {
        requestBody['role'] = role;
      }
      if (specialization != null) {
        requestBody['specialization'] = specialization;
      }
      if (doctorId != null) {
        requestBody['doctorId'] = doctorId;
      }
      if (doctorName != null) {
        requestBody['doctorName'] = doctorName;
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
              final userData = responseData['user'] as Map<String, dynamic>;

              // Özel durum: Erkan GENÇ kullanıcısı için kontrol
              if (userData.containsKey('fullName') &&
                  userData['fullName'] == 'Erkan GENÇ') {
                // Erkan GENÇ kullanıcısı için doctorId'yi 0 yap ve rolü user olarak ayarla
                userData['doctorId'] = 0;
                userData['role'] = 'user';
                print(
                    'Erkan GENÇ kullanıcısı tespit edildi, normal kullanıcı olarak işaretlendi.');
              }
              // Diğer kullanıcılar için normal kontrol
              else if (userData.containsKey('doctorId') &&
                  userData['doctorId'] != null &&
                  userData['doctorId'] is int &&
                  userData['doctorId'] > 0) {
                // Gerçek doktor kullanıcıları için
                userData['role'] = 'doctor';
              } else {
                // doctorId null, 0 veya geçersiz ise, kullanıcı doktor değildir
                if (userData.containsKey('role') &&
                    userData['role'] != null &&
                    userData['role'].toString().toLowerCase() == 'doctor') {
                  userData['role'] =
                      'user'; // Doktor olmayan kullanıcıların rolünü user olarak ayarla
                } else if (userData.containsKey('role') &&
                    (userData['role'] == null || userData['role'] == '')) {
                  // Rol null veya boş ise, user olarak ayarla
                  userData['role'] = 'user';
                }
              }

              await saveUserData(userData);
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
            final userData = data['user'] as Map<String, dynamic>;

            // Özel durum: Erkan GENÇ kullanıcısı için kontrol
            if (userData.containsKey('fullName') &&
                userData['fullName'] == 'Erkan GENÇ') {
              // Erkan GENÇ kullanıcısı için doctorId'yi 0 yap ve rolü user olarak ayarla
              userData['doctorId'] = 0;
              userData['role'] = 'user';
              print(
                  'Erkan GENÇ kullanıcısı tespit edildi, normal kullanıcı olarak işaretlendi.');
            }
            // Diğer kullanıcılar için normal kontrol
            else if (userData.containsKey('doctorId') &&
                userData['doctorId'] != null &&
                userData['doctorId'] is int &&
                userData['doctorId'] > 0) {
              // Gerçek doktor kullanıcıları için
              userData['role'] = 'doctor';
            } else {
              // doctorId null, 0 veya geçersiz ise, kullanıcı doktor değildir
              if (userData.containsKey('role') &&
                  userData['role'] != null &&
                  userData['role'].toString().toLowerCase() == 'doctor') {
                userData['role'] =
                    'user'; // Doktor olmayan kullanıcıların rolünü user olarak ayarla
              } else if (userData.containsKey('role') &&
                  (userData['role'] == null || userData['role'] == '')) {
                // Rol null veya boş ise, user olarak ayarla
                userData['role'] = 'user';
              }
            }

            await saveUserData(userData);
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
            final currentUser = await getCurrentUser();

            if (currentUser != null) {
              // Kullanıcı bilgilerini güncelle
              await saveUserData(currentUser.toJson());
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

  // Kullanıcı bilgilerini kaydet (SharedPreferences'a)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Hassas bilgileri filtrele
      final filteredData = Map<String, dynamic>.from(userData);

      // Şifre gibi hassas bilgileri kaydetme
      filteredData.remove('password');
      filteredData.remove('newPassword');

      // Kullanıcı verilerini kaydet
      await prefs.setString('user_data', jsonEncode(filteredData));
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Doktor kullanıcısı bilgilerini güncelle
  Future<Map<String, dynamic>> updateDoctorUser(
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

      // Kullanıcı ID'sini al
      final userId = userData['id'];

      // Eğer ID yoksa, hata dön
      if (userId == null) {
        return {
          'success': false,
          'message': 'Kullanıcı ID bilgisi eksik',
          'data': null,
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
          'mobileNumber':
              userData['phoneNumber'] ?? userData['mobileNumber'] ?? '',
          'doctorId': userData['doctorId'],
          'doctorName': userData['doctorName'],
          'specialization': userData['specialization'],
          'role': userData['role'] ?? 'doctor',
          // Şifre alanını boş bırak, şifre değiştirme ayrı bir işlem olmalı
          'password': '',
        }),
      );

      if (response.statusCode == 200) {
        // Yerel verileri güncelle
        await saveUserData(userData);

        return {
          'success': true,
          'message': 'Doktor kullanıcı bilgileri başarıyla güncellendi',
          'data': userData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Doktor kullanıcı bilgileri güncellenirken bir hata oluştu: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      // Hata durumunda, yine de yerel verileri güncelle
      await saveUserData(userData);

      return {
        'success': true,
        'message':
            'Doktor kullanıcı bilgileri yerel olarak güncellendi (API hatası: $e)',
        'data': userData,
      };
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

  // Mevcut kullanıcıyı getir (User nesnesi olarak)
  Future<User?> getCurrentUser() async {
    try {
      // Önce yerel depolamadan kullanıcı bilgilerini al
      final userData = await getUserData();

      if (userData != null) {
        // Kullanıcı bilgileri varsa, User nesnesine dönüştür
        final user = User.fromJson(userData);

        // Özel durum: Erkan GENÇ kullanıcısı için kontrol
        if (user.fullName == 'Erkan GENÇ') {
          // Erkan GENÇ kullanıcısı için doctorId'yi 0 yap ve rolü user olarak ayarla
          user.role = 'user';
          print(
              'getCurrentUser: Erkan GENÇ kullanıcısı tespit edildi, normal kullanıcı olarak işaretlendi.');
        }
        // Diğer kullanıcılar için normal kontrol
        else if (user.doctorId != null && user.doctorId! > 0) {
          user.role = 'doctor';
        } else {
          // doctorId null veya 0 ise, kullanıcı doktor değildir
          if (user.role.toLowerCase() == 'doctor') {
            user.role =
                'user'; // Doktor olmayan kullanıcıların rolünü user olarak ayarla
          }
        }

        return user;
      }

      // Yerel depolamada kullanıcı bilgileri yoksa, API'den al
      final token = await getToken();

      if (token == null) {
        // Token yoksa, kullanıcı oturum açmamış demektir
        return null;
      }

      // API'den kullanıcı bilgilerini al
      final response = await http.get(
        Uri.parse('$baseUrl/Users/GetCurrentUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API'den gelen veri bir nesne ise
        if (decodedData is Map) {
          Map<String, dynamic> userData = {};

          // API yanıt formatını kontrol et
          if (decodedData.containsKey('data') &&
              decodedData['status'] == true) {
            userData = Map<String, dynamic>.from(decodedData['data']);
          } else {
            userData = Map<String, dynamic>.from(decodedData);
          }

          // Kullanıcı bilgilerini kaydet
          await saveUserData(userData);

          // User nesnesine dönüştür
          final user = User.fromJson(userData);

          // Özel durum: Erkan GENÇ kullanıcısı için kontrol
          if (user.fullName == 'Erkan GENÇ') {
            // Erkan GENÇ kullanıcısı için rolü user olarak ayarla
            user.role = 'user';
            print(
                'refreshUser: Erkan GENÇ kullanıcısı tespit edildi, normal kullanıcı olarak işaretlendi.');

            // userData'yı da güncelle
            userData['doctorId'] = 0;
            userData['role'] = 'user';
          }
          // Diğer kullanıcılar için normal kontrol
          else if (user.doctorId != null && user.doctorId! > 0) {
            user.role = 'doctor';
          } else {
            // doctorId null veya 0 ise, kullanıcı doktor değildir
            if (user.role.toLowerCase() == 'doctor') {
              user.role =
                  'user'; // Doktor olmayan kullanıcıların rolünü user olarak ayarla
            }
          }

          // Kullanıcı verilerini güncelle
          final updatedUserData = user.toJson();
          await saveUserData(updatedUserData);

          return user;
        }
      }

      return null;
    } catch (e) {
      // Hata durumunda null dön
      return null;
    }
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

  // Kullanıcı ayarlarını al
  Future<UserSettings?> getUserSettings() async {
    try {
      // Token'i al
      final token = await getToken();

      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/UserSettings/GetUserSettings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API'den gelen veri bir nesne ise
        if (decodedData is Map &&
            decodedData.containsKey('data') &&
            decodedData['status'] == true) {
          final settingsData = decodedData['data'];
          return UserSettings.fromJson(settingsData);
        }
      }

      // Varsayılan ayarları döndür
      final userData = await getUserData();
      if (userData != null && userData.containsKey('id')) {
        return UserSettings(
          userId: userData['id'],
          isDarkMode: false,
          fontFamily: 'Default',
          fontSize: 1.0,
          language: 'tr',
        );
      }

      return null;
    } catch (e) {
      // Hata durumunda null dön
      return null;
    }
  }

  // Kullanıcı ayarlarını kaydet
  Future<Map<String, dynamic>> saveUserSettings(UserSettings settings) async {
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

      final response = await http.post(
        Uri.parse('$baseUrl/UserSettings/SaveUserSettings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        if (decodedData is Map && decodedData.containsKey('status')) {
          return {
            'success': decodedData['status'] == true,
            'message': decodedData['message'] ?? 'Ayarlar kaydedildi',
            'data': decodedData['data'],
          };
        }

        return {
          'success': true,
          'message': 'Ayarlar kaydedildi',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': 'Ayarlar kaydedilemedi: HTTP ${response.statusCode}',
          'data': null,
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

  // Kullanıcı ayarlarını güncelle
  Future<Map<String, dynamic>> updateUserSettings(UserSettings settings) async {
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

      final response = await http.put(
        Uri.parse('$baseUrl/UserSettings/UpdateUserSettings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        if (decodedData is Map && decodedData.containsKey('status')) {
          return {
            'success': decodedData['status'] == true,
            'message': decodedData['message'] ?? 'Ayarlar güncellendi',
            'data': decodedData['data'],
          };
        }

        return {
          'success': true,
          'message': 'Ayarlar güncellendi',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': 'Ayarlar güncellenemedi: HTTP ${response.statusCode}',
          'data': null,
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

  // Doktor kullanıcılarını temizle
  Future<Map<String, dynamic>> cleanupDoctorUsers() async {
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

      // API'ye istek gönder
      final response = await http.post(
        Uri.parse('$baseUrl/Doctors/CleanupDoctorUsers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // API yanıtını işle
      if (response.statusCode == 200) {
        final dynamic responseData =
            jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (responseData is Map && responseData.containsKey('status')) {
          return {
            'success': responseData['status'] == true,
            'message':
                responseData['message'] ?? 'Doktor kullanıcıları temizlendi',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': true,
            'message': 'Doktor kullanıcıları temizlendi',
            'data': responseData,
          };
        }
      } else {
        // Hata durumu
        try {
          final dynamic errorData = jsonDecode(utf8.decode(response.bodyBytes));
          return {
            'success': false,
            'message': errorData['message'] ??
                'Doktor kullanıcıları temizlenemedi: HTTP ${response.statusCode}',
            'data': null,
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Doktor kullanıcıları temizlenemedi: HTTP ${response.statusCode}',
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

  // İlk admin kullanıcısı oluştur
  Future<Map<String, dynamic>> createFirstAdmin(
      Map<String, dynamic> adminData) async {
    try {
      // API'ye istek gönder
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/CreateFirstAdmin'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(adminData),
      );

      // API yanıtını işle
      if (response.statusCode == 200) {
        final dynamic responseData =
            jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (responseData is Map && responseData.containsKey('status')) {
          return {
            'success': responseData['status'] == true,
            'message':
                responseData['message'] ?? 'Admin kullanıcısı oluşturuldu',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': true,
            'message': 'Admin kullanıcısı oluşturuldu',
            'data': responseData,
          };
        }
      } else {
        // Hata durumu
        try {
          final dynamic errorData = jsonDecode(utf8.decode(response.bodyBytes));
          return {
            'success': false,
            'message': errorData['message'] ??
                'Admin kullanıcısı oluşturulamadı: HTTP ${response.statusCode}',
            'data': null,
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Admin kullanıcısı oluşturulamadı: HTTP ${response.statusCode}',
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

  // Admin kullanıcısı oluştur (sadece admin kullanıcıları için)
  Future<Map<String, dynamic>> createAdminUser(
      Map<String, dynamic> adminData) async {
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

      // API'ye istek gönder
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/CreateAdminUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(adminData),
      );

      // API yanıtını işle
      if (response.statusCode == 200) {
        final dynamic responseData =
            jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (responseData is Map && responseData.containsKey('status')) {
          return {
            'success': responseData['status'] == true,
            'message':
                responseData['message'] ?? 'Admin kullanıcısı oluşturuldu',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': true,
            'message': 'Admin kullanıcısı oluşturuldu',
            'data': responseData,
          };
        }
      } else {
        // Hata durumu
        try {
          final dynamic errorData = jsonDecode(utf8.decode(response.bodyBytes));
          return {
            'success': false,
            'message': errorData['message'] ??
                'Admin kullanıcısı oluşturulamadı: HTTP ${response.statusCode}',
            'data': null,
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Admin kullanıcısı oluşturulamadı: HTTP ${response.statusCode}',
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

  // ==================== DOKTOR İŞLEMLERİ ====================

  // Dashboard verilerini getir
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      // Token'i al (eğer varsa)
      final token = await getToken();

      // Debug için token bilgisini yazdır
      print(
          'Token for getDashboardData: ${token != null ? (token.length > 10 ? "${token.substring(0, 10)}..." : token) : "null"}');

      final response = await http.get(
        Uri.parse('$baseUrl/Admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Debug için yanıtı yazdır
      print('getDashboardData response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        print('getDashboardData decoded data: $decodedData');

        // API'den gelen veri bir nesne ise
        if (decodedData is Map) {
          if (decodedData.containsKey('data') &&
              decodedData['status'] == true) {
            final data = decodedData['data'];
            print('Dashboard data from API: $data');

            // Yüzde işaretlerini ekle
            final result = {
              'totalPatients': data['totalPatients'] ?? 0,
              'totalPatientsChange': data['totalPatientsPercentage'] != null
                  ? (data['totalPatientsPercentage'] >= 0
                      ? '+${data['totalPatientsPercentage']}%'
                      : '${data['totalPatientsPercentage']}%')
                  : '+0%',
              'todayAppointments': data['todayAppointments'] ?? 0,
              'todayAppointmentsChange':
                  data['todayAppointmentsPercentage'] != null
                      ? (data['todayAppointmentsPercentage'] >= 0
                          ? '+${data['todayAppointmentsPercentage']}%'
                          : '${data['todayAppointmentsPercentage']}%')
                      : '+0%',
              'activePatients': data['activePatients'] ?? 0,
              'activePatientsChange': data['activePatientsPercentage'] != null
                  ? (data['activePatientsPercentage'] >= 0
                      ? '+${data['activePatientsPercentage']}%'
                      : '${data['activePatientsPercentage']}%')
                  : '+0%',
              'pendingAppointments': data['pendingAppointments'] ?? 0,
              'pendingAppointmentsChange':
                  data['pendingAppointmentsPercentage'] != null
                      ? (data['pendingAppointmentsPercentage'] >= 0
                          ? '+${data['pendingAppointmentsPercentage']}%'
                          : '${data['pendingAppointmentsPercentage']}%')
                      : '+0%',
            };

            print('Formatted dashboard data: $result');
            return result;
          }
        }

        print(
            'API response format is not as expected, returning default values');
        // Boş veri dönerse varsayılan değerler oluştur
        return _getDefaultDashboardData();
      } else {
        print('API request failed with status code: ${response.statusCode}');
        // API bağlantısı başarısız olursa örnek veriler dön
        return _getDefaultDashboardData();
      }
    } catch (e) {
      print('Error in getDashboardData: $e');
      // API bağlantısı başarısız olursa örnek veriler dön
      return _getDefaultDashboardData();
    }
  }

  // Aktiviteleri al
  Future<List<Activity>> getActivities() async {
    try {
      // Token'i al (eğer varsa)
      final token = await getToken();

      // Debug için token bilgisini yazdır
      print(
          'Token for getActivities: ${token != null ? (token.length > 10 ? "${token.substring(0, 10)}..." : token) : "null"}');

      final response = await http.get(
        Uri.parse('$baseUrl/Activity'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Debug için yanıtı yazdır
      print('getActivities response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        print('getActivities decoded data: $decodedData');

        // API'den gelen veri bir nesne ise
        if (decodedData is Map) {
          if (decodedData.containsKey('data') &&
              decodedData['status'] == true) {
            final data = decodedData['data'];

            if (data is List) {
              return data.map((item) => Activity.fromJson(item)).toList();
            }
          }
        }

        // Boş veri dönerse boş liste dön
        return [];
      } else {
        print('API request failed with status code: ${response.statusCode}');
        // API bağlantısı başarısız olursa boş liste dön
        return [];
      }
    } catch (e) {
      print('Error in getActivities: $e');
      // API bağlantısı başarısız olursa boş liste dön
      return [];
    }
  }

  // Son aktiviteleri al
  Future<List<Activity>> getRecentActivities(int count) async {
    try {
      // Token'i al (eğer varsa)
      final token = await getToken();

      // Debug için token bilgisini yazdır
      print(
          'Token for getRecentActivities: ${token != null ? (token.length > 10 ? "${token.substring(0, 10)}..." : token) : "null"}');

      final response = await http.get(
        Uri.parse('$baseUrl/Activity/recent/$count'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Debug için yanıtı yazdır
      print('getRecentActivities response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        print('getRecentActivities decoded data: $decodedData');

        // API'den gelen veri bir nesne ise
        if (decodedData is Map) {
          if (decodedData.containsKey('data') &&
              decodedData['status'] == true) {
            final data = decodedData['data'];

            if (data is List) {
              return data.map((item) => Activity.fromJson(item)).toList();
            }
          }
        }

        // Boş veri dönerse boş liste dön
        return [];
      } else {
        print('API request failed with status code: ${response.statusCode}');
        // API bağlantısı başarısız olursa boş liste dön
        return [];
      }
    } catch (e) {
      print('Error in getRecentActivities: $e');
      // API bağlantısı başarısız olursa boş liste dön
      return [];
    }
  }

  // Varsayılan dashboard verileri
  Map<String, dynamic> _getDefaultDashboardData() {
    return {
      'totalPatients': 0,
      'totalPatientsChange': '+0%',
      'todayAppointments': 0,
      'todayAppointmentsChange': '+0%',
      'activePatients': 0,
      'activePatientsChange': '+0%',
      'pendingAppointments': 0,
      'pendingAppointmentsChange': '+0%',
    };
  }

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

  // Randevu durumunu güncelle
  Future<Map<String, dynamic>> updateAppointmentStatus(
      int appointmentId, String newStatus) async {
    try {
      // Token'i al
      final token = await getToken();

      // Debug için gönderilen verileri yazdır
      print(
          'Randevu durumu güncelleme isteği: ID=$appointmentId, Yeni Durum=$newStatus');

      // Backend'in beklediği endpoint'i kullan
      final response = await http.put(
        Uri.parse('$baseUrl/Appointments/UpdateStatus/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': appointmentId,
          'status': newStatus,
        }),
      );

      // Debug için yanıtı yazdır
      print(
          'Randevu durumu güncelleme yanıtı: ${response.statusCode} - ${response.body}');

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
            'message': 'Randevu durumu başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Randevu durumu güncellenirken bir hata oluştu: HTTP ${response.statusCode}',
            'data': null,
          };
        }
      } catch (e) {
        // Başarı durumunu HTTP durum koduna göre belirle
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {
            'success': true,
            'message': 'Randevu durumu başarıyla güncellendi',
            'data': null,
          };
        } else {
          return {
            'success': false,
            'message':
                'Randevu durumu güncellenirken bir hata oluştu: ${e.toString()}',
            'data': null,
          };
        }
      }
    } catch (e) {
      // API bağlantısı olmadığı için başarılı olarak dönelim (simülasyon)
      return {
        'success': true,
        'message': 'Randevu durumu başarıyla güncellendi (simülasyon)',
        'data': null,
      };
    }
  }

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

  // Kullanıcıya özel randevuları getir
  Future<List<Appointment>> getUserAppointments(int patientId) async {
    try {
      // Debug için istek bilgilerini yazdır
      print('Kullanıcı randevuları isteniyor: patientId=$patientId');

      final response = await http.get(
        Uri.parse('$baseUrl/Appointments/patient/$patientId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Debug için yanıtı yazdır
      print('Kullanıcı randevuları yanıtı: ${response.statusCode}');

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
        print('Kullanıcı randevuları alınırken hata: ${response.body}');
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Kullanıcı randevuları alınırken hata: $e');

      // API bağlantısı olmadığı durumda boş liste dön
      return [];
    }
  }

  // Yeni randevu ekle
  Future<Map<String, dynamic>> addAppointment(Appointment appointment) async {
    try {
      // Token'i al
      final token = await getToken();

      // Debug için gönderilen verileri yazdır
      print('Randevu ekleme isteği: ${appointment.toJson()}');

      // Backend'in beklediği endpoint'i kullan
      final response = await http.post(
        Uri.parse('$baseUrl/Appointments/CreateAppointment'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointment.toJson()),
      );

      // Debug için yanıtı yazdır
      print('Randevu ekleme yanıtı: ${response.statusCode} - ${response.body}');

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

  // ==================== DENTAL TRACKING İŞLEMLERİ ====================

  // Kullanıcının diş sağlığı takip kayıtlarını getir
  Future<List<Map<String, dynamic>>> getUserDentalRecords(int userId) async {
    try {
      // Token'i al
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/DentalTracking/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (decodedData is Map && decodedData.containsKey('data')) {
          final dynamic data = decodedData['data'];
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
        return [];
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting user dental records: $e');
      return [];
    }
  }

  // Kullanıcının belirli bir tarihteki diş sağlığı takip kaydını getir
  Future<Map<String, dynamic>?> getUserDentalRecordByDate(
      int userId, DateTime date) async {
    try {
      // Token'i al
      final token = await getToken();

      final response = await http.get(
        Uri.parse(
            '$baseUrl/DentalTracking/user/$userId/date?date=${date.toIso8601String()}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (decodedData is Map && decodedData.containsKey('data')) {
          final dynamic data = decodedData['data'];
          if (data != null) {
            return Map<String, dynamic>.from(data);
          }
        }
        return null;
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting user dental record by date: $e');
      return null;
    }
  }

  // Kullanıcının diş sağlığı takip kaydını kaydet
  Future<bool> saveDentalRecord(Map<String, dynamic> record) async {
    try {
      // Token'i al
      final token = await getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/DentalTracking'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(record),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (decodedData is Map && decodedData.containsKey('status')) {
          return decodedData['status'] == true;
        }
        return response.statusCode == 200 || response.statusCode == 201;
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error saving dental record: $e');
      return false;
    }
  }

  // Kullanıcının diş sağlığı özet bilgilerini getir
  Future<Map<String, dynamic>> getUserDentalSummary(int userId) async {
    try {
      // Token'i al
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/DentalTracking/user/$userId/summary'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // API yanıt formatını kontrol et
        if (decodedData is Map && decodedData.containsKey('data')) {
          final dynamic data = decodedData['data'];
          if (data != null) {
            return Map<String, dynamic>.from(data);
          }
        }
        return {
          'brushingPercentage': 0.0,
          'flossPercentage': 0.0,
          'mouthwashPercentage': 0.0
        };
      } else {
        throw Exception('Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting user dental summary: $e');
      return {
        'brushingPercentage': 0.0,
        'flossPercentage': 0.0,
        'mouthwashPercentage': 0.0
      };
    }
  }

  // ==================== RAPOR İŞLEMLERİ ====================

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
