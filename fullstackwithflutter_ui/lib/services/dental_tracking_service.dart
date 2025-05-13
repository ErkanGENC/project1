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

      // Debug için bilgi yazdır
      print('Searching for record for user $userId on date: $todayDate');
      print('Total records found: ${records.length}');

      // Tüm kayıtları debug için yazdır
      for (var record in records) {
        print('Record: userId=${record.userId}, date=${record.date}, '
            'morningBrushing=${record.morningBrushing}, '
            'eveningBrushing=${record.eveningBrushing}, '
            'usedFloss=${record.usedFloss}, '
            'usedMouthwash=${record.usedMouthwash}');
      }

      // Bugüne ait kaydı bul
      final todayRecord = records.firstWhere(
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

      // Debug için bulunan kaydı yazdır
      print('Today\'s record found: ${todayRecord.id != 0 ? 'Yes' : 'No'}');

      return todayRecord;
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
      // Debug için kullanıcı ID'sini yazdır
      print('Getting all records for user ID: $userId');

      // Önce yerel depolamadan verileri al
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) {
        print('No records found in SharedPreferences');
        return [];
      }

      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        print('Found ${jsonList.length} total records in SharedPreferences');

        final allRecords =
            jsonList.map((json) => DentalTrackingModel.fromJson(json)).toList();

        // Kullanıcıya ait kayıtları filtrele
        final userRecords =
            allRecords.where((record) => record.userId == userId).toList();
        print('Found ${userRecords.length} records for user ID: $userId');

        return userRecords;
      } catch (e) {
        print('Error parsing records from SharedPreferences: $e');
        // JSON ayrıştırma hatası durumunda boş liste döndür
        return [];
      }
    } catch (e) {
      print('Error getting all records: $e');
      return [];
    }
  }

  // Yeni kayıt ekle veya mevcut kaydı güncelle
  Future<bool> saveRecord(DentalTrackingModel record) async {
    try {
      // Debug için kaydedilecek kaydı yazdır
      print('Saving record: userId=${record.userId}, date=${record.date}, '
          'morningBrushing=${record.morningBrushing}, '
          'eveningBrushing=${record.eveningBrushing}, '
          'usedFloss=${record.usedFloss}, '
          'usedMouthwash=${record.usedMouthwash}');

      // Tüm kayıtları getir
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      List<DentalTrackingModel> allRecords = [];
      if (jsonString != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          allRecords = jsonList
              .map((json) => DentalTrackingModel.fromJson(json))
              .toList();
          print(
              'Loaded ${allRecords.length} existing records from SharedPreferences');
        } catch (e) {
          print('Error parsing existing records: $e');
          // Hatalı JSON varsa, yeni bir liste başlat
          allRecords = [];
        }
      } else {
        print('No existing records found in SharedPreferences');
      }

      // Aynı kullanıcı ve tarih için kayıt var mı kontrol et
      final existingRecordIndex = allRecords.indexWhere((r) =>
          r.userId == record.userId &&
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day);

      print(
          'Existing record found: ${existingRecordIndex >= 0 ? 'Yes' : 'No'}');

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
        print(
            'Updated existing record with ID: ${allRecords[existingRecordIndex].id}');
      } else {
        final newRecord = record.copyWith(id: newId);
        allRecords.add(newRecord);
        print('Added new record with ID: $newId');
      }

      // Kayıtları JSON'a dönüştür ve kaydet
      final updatedJsonList = allRecords.map((r) => r.toJson()).toList();
      final updatedJsonString = jsonEncode(updatedJsonList);

      // Debug için JSON boyutunu kontrol et
      print('JSON size: ${updatedJsonString.length} characters');

      // SharedPreferences'a kaydet
      final saveResult = await prefs.setString(_storageKey, updatedJsonString);

      print('Save result: $saveResult');

      // Kaydın başarılı olduğunu doğrula
      final verifyJsonString = prefs.getString(_storageKey);
      if (verifyJsonString != null) {
        final verifyList = jsonDecode(verifyJsonString) as List;
        print('Verification: ${verifyList.length} records saved successfully');
      } else {
        print('Verification failed: No data found after save');
      }

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
