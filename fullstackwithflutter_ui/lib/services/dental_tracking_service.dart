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
      print('Getting all records for user ID: $userId');

      // Önce API'den verileri almayı dene
      try {
        final records = await _apiService.getUserDentalRecords(userId);
        if (records.isNotEmpty) {
          print(
              'Found ${records.length} records from API for user ID: $userId');
          return records
              .map((json) => DentalTrackingModel.fromJson(json))
              .toList();
        }
      } catch (apiError) {
        print(
            'Error getting records from API: $apiError, falling back to local storage');
      }

      // API'den veri alınamazsa yerel depolamadan verileri al
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
      print('Saving record: userId=${record.userId}, date=${record.date}');

      // Önce API'ye kaydetmeyi dene
      try {
        // API'ye gönderilecek veriyi hazırla
        final recordJson = {
          'userId': record.userId,
          'date': record.date.toIso8601String(),
          'morningBrushing': record.morningBrushing,
          'eveningBrushing': record.eveningBrushing,
          'usedFloss': record.usedFloss,
          'usedMouthwash': record.usedMouthwash,
          'notes': record.notes,
        };

        // API'ye kaydet
        final success = await _apiService.saveDentalRecord(recordJson);
        if (success) {
          print('Record saved successfully to API');
          return true;
        }
      } catch (apiError) {
        print(
            'Error saving record to API: $apiError, falling back to local storage');
      }

      // API'ye kaydedilemezse yerel depolamaya kaydet
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

      // SharedPreferences'a kaydet
      final saveResult = await prefs.setString(_storageKey, updatedJsonString);
      print('Save result: $saveResult');

      return true;
    } catch (e) {
      print('Error saving record: $e');
      return false;
    }
  }

  // Mevcut kullanıcıyı getir
  Future<User?> getCurrentUser() async {
    try {
      // Doğrudan User nesnesi döndüren yeni metodu kullan
      return await _apiService.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}
