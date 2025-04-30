import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/api_service.dart';

class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String email;
  final String phoneNumber;
  final bool isAvailable;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.email,
    required this.phoneNumber,
    required this.isAvailable,
  });
}

class DoctorsManagement extends StatefulWidget {
  const DoctorsManagement({Key? key}) : super(key: key);

  @override
  _DoctorsManagementState createState() => _DoctorsManagementState();
}

class _DoctorsManagementState extends State<DoctorsManagement> {
  final ApiService _apiService = ApiService();
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }
  
  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Gerçek uygulamada, burada API'den doktorları alacaksınız
      // Şimdilik örnek veriler kullanıyoruz
      await Future.delayed(const Duration(seconds: 1)); // API çağrısı simülasyonu
      
      final List<Doctor> doctors = [
        Doctor(
          id: 1,
          name: 'Dr. Mehmet Öz',
          specialization: 'Diş Hekimi',
          email: 'mehmet.oz@example.com',
          phoneNumber: '0555-123-4567',
          isAvailable: true,
        ),
        Doctor(
          id: 2,
          name: 'Dr. Zeynep Kaya',
          specialization: 'Ortodontist',
          email: 'zeynep.kaya@example.com',
          phoneNumber: '0555-234-5678',
          isAvailable: true,
        ),
        Doctor(
          id: 3,
          name: 'Dr. Ali Yıldız',
          specialization: 'Ağız ve Çene Cerrahı',
          email: 'ali.yildiz@example.com',
          phoneNumber: '0555-345-6789',
          isAvailable: false,
        ),
        Doctor(
          id: 4,
          name: 'Dr. Ayşe Demir',
          specialization: 'Pedodontist',
          email: 'ayse.demir@example.com',
          phoneNumber: '0555-456-7890',
          isAvailable: true,
        ),
      ];
      
      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _filterDoctors(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDoctors = _doctors;
      } else {
        _filteredDoctors = _doctors.where((doctor) {
          return doctor.name.toLowerCase().contains(query.toLowerCase()) ||
              doctor.specialization.toLowerCase().contains(query.toLowerCase()) ||
              doctor.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  void _showAddDoctorDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _specializationController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    bool _isAvailable = true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Doktor Ekle'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen ad soyad girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Uzmanlık',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen uzmanlık alanı girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen e-posta girin';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen telefon numarası girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Müsait'),
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Gerçek uygulamada, burada API'ye yeni doktor eklemek için istek atılır
                // Şimdilik sadece listeye ekliyoruz
                final newDoctor = Doctor(
                  id: _doctors.length + 1,
                  name: _nameController.text,
                  specialization: _specializationController.text,
                  email: _emailController.text,
                  phoneNumber: _phoneController.text,
                  isAvailable: _isAvailable,
                );
                
                setState(() {
                  _doctors.add(newDoctor);
                  _filterDoctors(_searchQuery);
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doktor başarıyla eklendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
  
  void _showEditDoctorDialog(Doctor doctor) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: doctor.name);
    final _specializationController = TextEditingController(text: doctor.specialization);
    final _emailController = TextEditingController(text: doctor.email);
    final _phoneController = TextEditingController(text: doctor.phoneNumber);
    bool _isAvailable = doctor.isAvailable;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Doktor Düzenle'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen ad soyad girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specializationController,
                    decoration: const InputDecoration(
                      labelText: 'Uzmanlık',
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen uzmanlık alanı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen e-posta girin';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Geçerli bir e-posta girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen telefon numarası girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Müsait'),
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Gerçek uygulamada, burada API'ye doktor güncellemek için istek atılır
                  // Şimdilik sadece listeyi güncelliyoruz
                  final index = _doctors.indexWhere((d) => d.id == doctor.id);
                  if (index != -1) {
                    final updatedDoctor = Doctor(
                      id: doctor.id,
                      name: _nameController.text,
                      specialization: _specializationController.text,
                      email: _emailController.text,
                      phoneNumber: _phoneController.text,
                      isAvailable: _isAvailable,
                    );
                    
                    this.setState(() {
                      _doctors[index] = updatedDoctor;
                      _filterDoctors(_searchQuery);
                    });
                  }
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Doktor başarıyla güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doktoru Sil'),
        content: Text('${doctor.name} adlı doktoru silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Gerçek uygulamada, burada API'ye doktor silmek için istek atılır
              // Şimdilik sadece listeden çıkarıyoruz
              setState(() {
                _doctors.removeWhere((d) => d.id == doctor.id);
                _filterDoctors(_searchQuery);
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Doktor başarıyla silindi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doktor Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDoctors,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve filtre çubuğu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterDoctors,
                    decoration: InputDecoration(
                      hintText: 'Doktor ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddDoctorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Doktor'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Doktor listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bir hata oluştu',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchDoctors,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : _filteredDoctors.isEmpty
                        ? const Center(
                            child: Text('Doktor bulunamadı'),
                          )
                        : ListView.builder(
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor,
                                    child: const Icon(
                                      Icons.medical_services,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(doctor.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doctor.specialization),
                                      Text(doctor.email),
                                      Text(doctor.phoneNumber),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: doctor.isAvailable
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          doctor.isAvailable ? 'Müsait' : 'Müsait Değil',
                                          style: TextStyle(
                                            color: doctor.isAvailable ? Colors.green : Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditDoctorDialog(doctor),
                                        tooltip: 'Düzenle',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteConfirmationDialog(doctor),
                                        tooltip: 'Sil',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
