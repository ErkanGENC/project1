import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dental_tracking_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Diş sağlığı takip verilerini yöneten servis sınıfı
class DentalTrackingService {
  static const String _storageKey = 'dental_tracking_data';
  final ApiService _apiService = ApiService();

  // Kullanıcının bugünkü kaydını getir
  Future<DentalTrackingModel?> getTodaysRecord(int userId) async {
    try {
      // Tüm kayıtları getir
      final records = await getAllRecords(userId);

      // Bugünün tarihini al
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Bugüne ait kaydı bul
      return records.firstWhere(
        (record) =>
            record.date.year == todayDate.year &&
            record.date.month == todayDate.month &&
            record.date.day == todayDate.day,
        orElse: () => DentalTrackingModel.create(
          userId: userId,
          morningBrushing: false,
          eveningBrushing: false,
          usedFloss: false,
          usedMouthwash: false,
        ),
      );
    } catch (e) {
      print('Error getting today\'s record: $e');
      return null;
    }
  }

  // Kullanıcının haftalık kayıtlarını getir
  Future<WeeklyDentalStats> getWeeklyStats(int userId) async {
    try {
      // Tüm kayıtları getir
      final records = await getAllRecords(userId);

      // Bugünün tarihini al
      final today = DateTime.now();

      // Son 7 günün kayıtlarını filtrele
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekStartDate =
          DateTime(weekStart.year, weekStart.month, weekStart.day);

      final weeklyRecords = records.where((record) {
        return record.date
                .isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
            record.date.isBefore(weekStartDate.add(const Duration(days: 7)));
      }).toList();

      return WeeklyDentalStats(dailyRecords: weeklyRecords);
    } catch (e) {
      print('Error getting weekly stats: $e');
      return WeeklyDentalStats(dailyRecords: []);
    }
  }

  // Kullanıcının tüm kayıtlarını getir
  Future<List<DentalTrackingModel>> getAllRecords(int userId) async {
    try {
      // Önce yerel depolamadan verileri al
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final allRecords =
          jsonList.map((json) => DentalTrackingModel.fromJson(json)).toList();

      // Kullanıcıya ait kayıtları filtrele
      return allRecords.where((record) => record.userId == userId).toList();
    } catch (e) {
      print('Error getting all records: $e');
      return [];
    }
  }

  // Yeni kayıt ekle veya mevcut kaydı güncelle
  Future<bool> saveRecord(DentalTrackingModel record) async {
    try {
      // Tüm kayıtları getir
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      List<DentalTrackingModel> allRecords = [];
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        allRecords =
            jsonList.map((json) => DentalTrackingModel.fromJson(json)).toList();
      }

      // Aynı kullanıcı ve tarih için kayıt var mı kontrol et
      final existingRecordIndex = allRecords.indexWhere((r) =>
          r.userId == record.userId &&
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day);

      // Yeni ID oluştur
      int newId = 1;
      if (allRecords.isNotEmpty) {
        newId = allRecords.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      }

      // Kayıt varsa güncelle, yoksa ekle
      if (existingRecordIndex >= 0) {
        allRecords[existingRecordIndex] = record.copyWith(
          id: allRecords[existingRecordIndex].id,
          updatedAt: DateTime.now(),
        );
      } else {
        allRecords.add(record.copyWith(id: newId));
      }

      // Kayıtları JSON'a dönüştür ve kaydet
      final updatedJsonList = allRecords.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(updatedJsonList));

      return true;
    } catch (e) {
      print('Error saving record: $e');
      return false;
    }
  }

  // Mevcut kullanıcıyı getir
  Future<User?> getCurrentUser() async {
    try {
      final result = await _apiService.getCurrentUser();

      // API'den gelen yanıtı kontrol et
      if (result['success'] == true && result['data'] != null) {
        // Map'i User nesnesine dönüştür
        return User.fromJson(result['data']);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}
