class Appointment {
  final int id;
  final String patientName;
  final String doctorName;
  final DateTime date;
  final String time;
  final String status;
  final String type;
  final int? doctorId;
  final int? patientId;
  final String patientEmail;
  final String notes;

  Appointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.status,
    required this.type,
    this.doctorId,
    this.patientId,
    this.patientEmail = '',
    this.notes = '',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // API'den gelen veriyi yazdır (debug için)
    // print('Appointment.fromJson: $json');

    return Appointment(
      id: json['id'] ?? json['appointmentId'] ?? json['appointment_id'] ?? 0,
      patientName: json['patientName'] ??
          json['patient_name'] ??
          json['patient'] ??
          'İsimsiz Hasta',
      doctorName: json['doctorName'] ??
          json['doctor_name'] ??
          json['doctor'] ??
          'İsimsiz Doktor',
      doctorId: json['doctorId'] != null
          ? int.tryParse(json['doctorId'].toString())
          : null,
      patientId: json['patientId'] != null
          ? int.tryParse(json['patientId'].toString())
          : null,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : (json['appointmentDate'] != null
              ? DateTime.parse(json['appointmentDate'])
              : DateTime.now()),
      time: json['time'] ?? json['appointmentTime'] ?? '00:00',
      status: json['status'] ?? json['appointmentStatus'] ?? 'Bekleyen',
      type: json['type'] ??
          json['appointmentType'] ??
          json['treatment'] ??
          'Belirtilmemiş',
      patientEmail:
          json['patientEmail'] ?? json['patient_email'] ?? json['email'] ?? '',
      notes: json['notes'] ?? json['description'] ?? json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    // Backend'in SaveAppointmentViewModel formatına uygun olarak veri gönder
    return {
      'patientId': patientId ?? 0,
      'doctorId': doctorId ?? 0,
      'patientName': patientName,
      'doctorName': doctorName,
      'date': date.toIso8601String(),
      'time': time,
      'status': status,
      'type': type,
    };
  }
}
