import 'package:flutter/material.dart';
import '../../models/doctor_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../constants/app_theme.dart';

class SelectDoctorScreen extends StatefulWidget {
  final User user;
  final Function(User) onDoctorSelected;

  const SelectDoctorScreen({
    super.key,
    required this.user,
    required this.onDoctorSelected,
  });

  @override
  _SelectDoctorScreenState createState() => _SelectDoctorScreenState();
}

class _SelectDoctorScreenState extends State<SelectDoctorScreen> {
  final ApiService _apiService = ApiService();
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Doctor? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _apiService.getAllDoctors();

      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
          _errorMessage = '';
          
          // Eğer kullanıcının zaten bir doktoru varsa, onu seçili olarak işaretle
          if (widget.user.doctorId != null) {
            _selectedDoctor = _doctors.firstWhere(
              (doctor) => doctor.id == widget.user.doctorId,
              orElse: () => _doctors.first,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String userFriendlyMessage;
        
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          userFriendlyMessage = 'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.';
        } else if (e.toString().contains('TimeoutException')) {
          userFriendlyMessage = 'Sunucu yanıt vermiyor. Lütfen daha sonra tekrar deneyin.';
        } else {
          userFriendlyMessage = 'Doktorlar yüklenirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
        }
        
        setState(() {
          _errorMessage = userFriendlyMessage;
          _isLoading = false;
        });
      }
    }
  }

  void _selectDoctor(Doctor doctor) {
    setState(() {
      _selectedDoctor = doctor;
    });
  }

  void _saveSelection() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir doktor seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kullanıcı bilgilerini güncelle
    final updatedUser = User(
      id: widget.user.id,
      fullName: widget.user.fullName,
      email: widget.user.email,
      phoneNumber: widget.user.phoneNumber,
      createdDate: widget.user.createdDate,
      updatedDate: DateTime.now(),
      doctorId: _selectedDoctor!.id,
      doctorName: _selectedDoctor!.name,
      specialization: _selectedDoctor!.specialization,
    );

    try {
      setState(() {
        _isLoading = true;
      });

      // API'ye güncelleme isteği gönder
      final result = await _apiService.updateUser(updatedUser);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Başarılı güncelleme
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doktor seçiminiz kaydedildi: ${_selectedDoctor!.name}'),
            backgroundColor: Colors.green,
          ),
        );

        // Callback ile güncellenmiş kullanıcıyı geri döndür
        widget.onDoctorSelected(updatedUser);

        // Önceki sayfaya dön
        Navigator.pop(context);
      } else {
        // Hata durumu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
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
        title: const Text('Doktor Seçin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _fetchDoctors();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSelection,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Seçimi Kaydet',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Doktorlar yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorColor.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bir hata oluştu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _fetchDoctors();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: AppTheme.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Henüz kayıtlı doktor bulunmamaktadır',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Lütfen daha sonra tekrar deneyin veya yöneticinize başvurun.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _fetchDoctors();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Yenile'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        final isSelected = _selectedDoctor?.id == doctor.id;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () => _selectDoctor(doctor),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: isSelected ? AppTheme.primaryColor : Colors.grey,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialization,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<int>(
                    value: doctor.id,
                    groupValue: _selectedDoctor?.id,
                    onChanged: (value) {
                      if (value != null) {
                        _selectDoctor(doctor);
                      }
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
