import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final String? patientName;

  const CreateAppointmentScreen({
    Key? key,
    this.patientName,
  }) : super(key: key);

  @override
  CreateAppointmentScreenState createState() => CreateAppointmentScreenState();
}

class CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '09:00';
  bool _isLoading = true;
  String _errorMessage = '';

  List<Doctor> _doctors = [];
  Doctor? _selectedDoctor;

  final List<String> _timeSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30'
  ];

  final List<String> _appointmentTypes = [
    'Genel Kontrol',
    'Diş Ağrısı',
    'Diş Temizliği',
    'Dolgu',
    'Kanal Tedavisi',
    'Diş Çekimi',
    'Protez',
    'Ortodonti',
    'İmplant',
    'Diğer'
  ];

  @override
  void initState() {
    super.initState();

    // Eğer hasta adı parametre olarak geldiyse, hasta adı alanını doldur
    if (widget.patientName != null) {
      _patientController.text = widget.patientName!;
    }

    // Doktorları yükle
    _loadDoctors();
  }

  @override
  void dispose() {
    _patientController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  // Doktorları yükle
  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final doctors = await _apiService.getAllDoctors();

      setState(() {
        _doctors = doctors;
        _isLoading = false;

        // Eğer doktor listesi boş değilse, ilk doktoru seç
        if (_doctors.isNotEmpty) {
          _selectedDoctor = _doctors.first;

          // Seçilen doktorun uzmanlık alanına göre randevu türünü otomatik doldur
          if (_selectedDoctor!.specialization.isNotEmpty) {
            _typeController.text = _selectedDoctor!.specialization;
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Doktorlar yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  // Tarih seçme diyaloğunu göster
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Randevu oluştur
  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Yükleniyor göstergesi
    setState(() {
      _isLoading = true;
    });

    try {
      // Yeni randevu oluştur
      final newAppointment = Appointment(
        id: 0, // API tarafında otomatik atanacak
        patientName: _patientController.text,
        doctorName: _selectedDoctor?.name ?? '',
        date: _selectedDate,
        time: _selectedTime,
        status: 'Bekleyen',
        type: _typeController.text,
      );

      // API'ye istek at
      final result = await _apiService.addAppointment(newAppointment);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Başarılı ise bildirim göster ve geri dön
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );

        // Önceki sayfaya dön
        Navigator.pop(context, true);
      } else {
        // Hata durumunda
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Oluştur'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadDoctors,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hasta Adı
                        TextFormField(
                          controller: _patientController,
                          decoration: const InputDecoration(
                            labelText: 'Hasta Adı',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen hasta adı girin';
                            }
                            return null;
                          },
                          readOnly: widget.patientName !=
                              null, // Eğer hasta adı parametre olarak geldiyse, salt okunur yap
                        ),
                        const SizedBox(height: 16),

                        // Doktor Seçimi
                        DropdownButtonFormField<Doctor>(
                          value: _selectedDoctor,
                          decoration: const InputDecoration(
                            labelText: 'Doktor',
                            prefixIcon: Icon(Icons.medical_services),
                            border: OutlineInputBorder(),
                          ),
                          items: _doctors.map((doctor) {
                            return DropdownMenuItem<Doctor>(
                              value: doctor,
                              child: Text(
                                  'Dr. ${doctor.name} (${doctor.specialization})'),
                            );
                          }).toList(),
                          onChanged: (Doctor? newValue) {
                            setState(() {
                              _selectedDoctor = newValue;

                              // Seçilen doktorun uzmanlık alanına göre randevu türünü otomatik doldur
                              if (_selectedDoctor != null &&
                                  _selectedDoctor!.specialization.isNotEmpty) {
                                _typeController.text =
                                    _selectedDoctor!.specialization;
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Lütfen bir doktor seçin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Randevu Türü
                        DropdownButtonFormField<String>(
                          value: _typeController.text.isEmpty
                              ? _appointmentTypes.first
                              : (_appointmentTypes
                                      .contains(_typeController.text)
                                  ? _typeController.text
                                  : _appointmentTypes.first),
                          decoration: const InputDecoration(
                            labelText: 'Randevu Türü',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _appointmentTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _typeController.text = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen randevu türü seçin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Tarih Seçimi
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tarih',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Saat Seçimi
                        DropdownButtonFormField<String>(
                          value: _selectedTime,
                          decoration: const InputDecoration(
                            labelText: 'Saat',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                          items: _timeSlots.map((time) {
                            return DropdownMenuItem<String>(
                              value: time,
                              child: Text(time),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTime = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Randevu Oluştur Butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _createAppointment,
                            icon: const Icon(Icons.add),
                            label: const Text('Randevu Oluştur'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
