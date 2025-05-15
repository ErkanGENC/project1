import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../constants/app_theme.dart';
import '../screens/doctor/select_doctor_screen.dart';
import '../models/appointment_model.dart';
import '../services/api_service.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final Function(User)? onUserUpdated;

  const UserListItem({
    super.key,
    required this.user,
    this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // Hasta için rastgele bir renk seçimi (gerçek uygulamada hasta durumuna göre değişebilir)
    final List<Color> avatarColors = [
      const Color(0xFF3498DB), // Mavi
      const Color(0xFF9B59B6), // Mor
      const Color(0xFF1ABC9C), // Turkuaz
      const Color(0xFF2ECC71), // Yeşil
      const Color(0xFFE74C3C), // Kırmızı
    ];

    // Hasta ID'sine göre sabit bir renk seçimi
    final Color avatarColor = avatarColors[user.id % avatarColors.length];

    // Hasta adının baş harflerini al
    final String initials = user.fullName
        .split(' ')
        .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
        .join('')
        .substring(0, user.fullName.split(' ').length > 1 ? 2 : 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to user details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Hero(
                tag: 'user-avatar-${user.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withAlpha(76),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Hasta bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.phoneNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    if (user.doctorName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Dr. ${user.doctorName} (${user.specialization})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Sağ taraftaki işlem butonları
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        // Randevu oluşturma ekranını aç
                        _showAddAppointmentDialog(context);
                      },
                      tooltip: 'Randevu Oluştur',
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.medical_services_outlined,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      onPressed: () {
                        // Doktor seçme ekranını aç
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectDoctorScreen(
                              user: user,
                              onDoctorSelected: (updatedUser) {
                                // Callback ile güncellenmiş kullanıcıyı geri döndür
                                if (onUserUpdated != null) {
                                  onUserUpdated!(updatedUser);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      tooltip: user.doctorId == null
                          ? 'Doktor Seç'
                          : 'Doktor Değiştir',
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Randevu oluşturma diyaloğunu göster
  void _showAddAppointmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final patientController = TextEditingController(text: user.fullName);
    final typeController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedTime = '09:00';
    final ApiService apiService = ApiService();

    // Doktor listesi ve seçilen doktor
    List<Doctor> doctors = [];
    Doctor? selectedDoctor;

    final List<String> timeSlots = [
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

    // StatefulBuilder kullanarak doktor seçildiğinde UI'ı güncelleyebiliriz
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Dialog açıldığında doktorları getir
          if (doctors.isEmpty) {
            apiService.getAllDoctors().then((doctorList) {
              setState(() {
                doctors = doctorList;
                // Eğer hastanın bir doktoru varsa, o doktoru seç
                if (user.doctorId != null && user.doctorName != null) {
                  try {
                    selectedDoctor = doctors.firstWhere(
                      (doctor) => doctor.id == user.doctorId,
                    );
                  } catch (e) {
                    // Eğer doktor bulunamazsa, varsayılan bir doktor oluştur
                    selectedDoctor = Doctor(
                      id: user.doctorId!,
                      name: user.doctorName!,
                      specialization: user.specialization ?? 'Belirtilmemiş',
                      email: '',
                      phoneNumber: '',
                    );
                  }
                  // Randevu türünü doktorun uzmanlık alanına göre ayarla
                  typeController.text = selectedDoctor?.specialization ?? '';
                }
              });
            }).catchError((e) {
              // Hata durumunda işlem yapma
            });
          }

          return AlertDialog(
            title: const Text('Yeni Randevu Ekle'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: patientController,
                      decoration: const InputDecoration(
                        labelText: 'Hasta Adı',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen hasta adı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Doktor seçimi için dropdown
                    DropdownButtonFormField<Doctor>(
                      value: selectedDoctor,
                      decoration: const InputDecoration(
                        labelText: 'Doktor Adı',
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      hint: const Text('Doktor Seçin'),
                      isExpanded: true,
                      items: doctors.map((Doctor doctor) {
                        return DropdownMenuItem<Doctor>(
                          value: doctor,
                          child:
                              Text('${doctor.name} (${doctor.specialization})'),
                        );
                      }).toList(),
                      onChanged: (Doctor? newValue) {
                        setState(() {
                          selectedDoctor = newValue;
                          // Doktor seçildiğinde randevu türünü otomatik doldur
                          if (newValue != null) {
                            typeController.text = newValue.specialization;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Lütfen doktor seçin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'Randevu Türü',
                        prefixIcon: Icon(Icons.category),
                        // Salt okunur olduğunu belirtmek için arka plan rengini değiştir
                        fillColor: Color(0xFFF5F5F5),
                        filled: true,
                      ),
                      // Salt okunur yap
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen randevu türü girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tarih',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedTime,
                      decoration: const InputDecoration(
                        labelText: 'Saat',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      items: timeSlots.map((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedTime = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    // API'ye yeni randevu eklemek için istek at
                    final newAppointment = Appointment(
                      id: 0, // API tarafında otomatik atanacak
                      patientName: patientController.text,
                      doctorName: selectedDoctor?.name ?? '',
                      date: selectedDate,
                      time: selectedTime,
                      status: 'Bekleyen',
                      type: typeController.text,
                    );

                    // Yükleniyor göstergesi
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      // API'ye istek at
                      final result =
                          await apiService.addAppointment(newAppointment);

                      // Mounted kontrolü
                      if (!context.mounted) return;

                      // Yükleniyor göstergesini kapat
                      Navigator.pop(context);
                      Navigator.pop(context); // Dialog'u kapat

                      if (result['success']) {
                        // Başarılı ise bildirim göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        // Hata durumunda
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Hata durumunda
                      if (!context.mounted) return;

                      // Yükleniyor göstergesini kapat
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bir hata oluştu: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }
}
