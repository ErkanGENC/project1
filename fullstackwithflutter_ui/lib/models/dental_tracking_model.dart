
/// Diş sağlığı takip verilerini tutan model sınıfı
class DentalTrackingModel {
  final int id;
  final int userId;
  final DateTime date;
  
  // Diş fırçalama takibi
  final bool morningBrushing;
  final bool eveningBrushing;
  
  // Diş ipi kullanımı
  final bool usedFloss;
  
  // Ağız gargarası kullanımı
  final bool usedMouthwash;
  
  // Notlar
  final String? notes;
  
  // Oluşturma ve güncelleme tarihleri
  final DateTime createdAt;
  final DateTime? updatedAt;

  DentalTrackingModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.morningBrushing,
    required this.eveningBrushing,
    required this.usedFloss,
    required this.usedMouthwash,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Günlük hedefler
  static const int brushingTarget = 2;
  static const bool flossTarget = true;
  static const bool mouthwashTarget = true;

  // Diş fırçalama sayısını hesapla
  int get brushingCount => (morningBrushing ? 1 : 0) + (eveningBrushing ? 1 : 0);

  // Günlük hedeflerin tamamlanma durumu
  int get completedGoals => 
      (brushingCount >= brushingTarget ? 1 : 0) +
      (usedFloss == flossTarget ? 1 : 0) +
      (usedMouthwash == mouthwashTarget ? 1 : 0);

  // İlerleme yüzdesi
  double get progressPercentage => completedGoals / 3;

  // JSON'dan model oluştur
  factory DentalTrackingModel.fromJson(Map<String, dynamic> json) {
    return DentalTrackingModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      morningBrushing: json['morningBrushing'] ?? false,
      eveningBrushing: json['eveningBrushing'] ?? false,
      usedFloss: json['usedFloss'] ?? false,
      usedMouthwash: json['usedMouthwash'] ?? false,
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  // Model'i JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'morningBrushing': morningBrushing,
      'eveningBrushing': eveningBrushing,
      'usedFloss': usedFloss,
      'usedMouthwash': usedMouthwash,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Yeni bir kayıt oluştur
  factory DentalTrackingModel.create({
    required int userId,
    required bool morningBrushing,
    required bool eveningBrushing,
    required bool usedFloss,
    required bool usedMouthwash,
    String? notes,
  }) {
    final now = DateTime.now();
    return DentalTrackingModel(
      id: 0, // API tarafından atanacak
      userId: userId,
      date: DateTime(now.year, now.month, now.day),
      morningBrushing: morningBrushing,
      eveningBrushing: eveningBrushing,
      usedFloss: usedFloss,
      usedMouthwash: usedMouthwash,
      notes: notes,
      createdAt: now,
      updatedAt: null,
    );
  }

  // Mevcut kaydı güncelle
  DentalTrackingModel copyWith({
    int? id,
    int? userId,
    DateTime? date,
    bool? morningBrushing,
    bool? eveningBrushing,
    bool? usedFloss,
    bool? usedMouthwash,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DentalTrackingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      morningBrushing: morningBrushing ?? this.morningBrushing,
      eveningBrushing: eveningBrushing ?? this.eveningBrushing,
      usedFloss: usedFloss ?? this.usedFloss,
      usedMouthwash: usedMouthwash ?? this.usedMouthwash,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Haftalık diş sağlığı verilerini tutan model sınıfı
class WeeklyDentalStats {
  final List<DentalTrackingModel> dailyRecords;
  
  WeeklyDentalStats({required this.dailyRecords});
  
  // Haftalık diş fırçalama sayısı
  List<int> get weeklyBrushing {
    final List<int> result = List.filled(7, 0);
    for (final record in dailyRecords) {
      final int dayIndex = record.date.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        result[dayIndex] = record.brushingCount;
      }
    }
    return result;
  }
  
  // Haftalık diş ipi kullanımı
  List<bool> get weeklyFloss {
    final List<bool> result = List.filled(7, false);
    for (final record in dailyRecords) {
      final int dayIndex = record.date.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        result[dayIndex] = record.usedFloss;
      }
    }
    return result;
  }
  
  // Haftalık gargara kullanımı
  List<bool> get weeklyMouthwash {
    final List<bool> result = List.filled(7, false);
    for (final record in dailyRecords) {
      final int dayIndex = record.date.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        result[dayIndex] = record.usedMouthwash;
      }
    }
    return result;
  }
  
  // Toplam diş fırçalama sayısı
  int get totalBrushing => weeklyBrushing.fold(0, (sum, count) => sum + count);
  
  // Toplam diş ipi kullanım günü
  int get totalFloss => weeklyFloss.where((day) => day).length;
  
  // Toplam gargara kullanım günü
  int get totalMouthwash => weeklyMouthwash.where((day) => day).length;
}
