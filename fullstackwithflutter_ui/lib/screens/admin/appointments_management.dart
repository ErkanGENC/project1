import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/appointment_model.dart';

class AppointmentsManagement extends StatefulWidget {
  const AppointmentsManagement({super.key});

  @override
  AppointmentsManagementState createState() => AppointmentsManagementState();
}

class AppointmentsManagementState extends State<AppointmentsManagement>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  late TabController _tabController;

  final List<String> _statusFilters = [
    'Tümü',
    'Bekleyen',
    'Onaylandı',
    'İptal Edildi',
    'Tamamlandı'
  ];
  String _selectedStatus = 'Tümü';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedStatus = _statusFilters[_tabController.index];
        _filterAppointments();
      });
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // API'den randevuları al
      final appointments = await _apiService.getAllAppointments();

      setState(() {
        _appointments = appointments;
        _filterAppointments();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterAppointments() {
    setState(() {
      if (_searchQuery.isEmpty && _selectedStatus == 'Tümü') {
        _filteredAppointments = _appointments;
        return;
      }

      _filteredAppointments = _appointments.where((appointment) {
        // Durum filtreleme
        final bool statusMatch =
            _selectedStatus == 'Tümü' || appointment.status == _selectedStatus;

        // Arama filtreleme
        final bool searchMatch = _searchQuery.isEmpty ||
            appointment.patientName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            appointment.doctorName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            appointment.type.toLowerCase().contains(_searchQuery.toLowerCase());

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  void _showAddAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    final patientController = TextEditingController();
    final doctorController = TextEditingController();
    final typeController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedTime = '09:00';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                TextFormField(
                  controller: doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Doktor Adı',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen doktor adı girin';
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
                  ),
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
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                      selectedTime = newValue;
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
                  doctorName: doctorController.text,
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
                      await _apiService.addAppointment(newAppointment);

                  // Mounted kontrolü
                  if (!mounted) return;

                  // Yükleniyor göstergesini kapat
                  Navigator.pop(context);
                  Navigator.pop(context); // Dialog'u kapat

                  if (result['success']) {
                    // Başarılı ise randevuları yeniden yükle
                    _fetchAppointments();

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
                  if (!mounted) return;

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
      ),
    );
  }

  void _showAppointmentDetailsDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevu Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Hasta', appointment.patientName),
            _buildDetailRow('Doktor', appointment.doctorName),
            _buildDetailRow('Tarih',
                '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}'),
            _buildDetailRow('Saat', appointment.time),
            _buildDetailRow('Tür', appointment.type),
            _buildDetailRow('Durum', appointment.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (appointment.status == 'Bekleyen')
            ElevatedButton(
              onPressed: () {
                // Gerçek uygulamada, burada API'ye randevu onaylamak için istek atılır
                // Şimdilik sadece listeyi güncelliyoruz
                final index =
                    _appointments.indexWhere((a) => a.id == appointment.id);
                if (index != -1) {
                  final updatedAppointment = Appointment(
                    id: appointment.id,
                    patientName: appointment.patientName,
                    doctorName: appointment.doctorName,
                    date: appointment.date,
                    time: appointment.time,
                    status: 'Onaylandı',
                    type: appointment.type,
                  );

                  setState(() {
                    _appointments[index] = updatedAppointment;
                    _filterAppointments();
                  });
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Randevu onaylandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Onayla'),
            ),
          if (appointment.status != 'İptal Edildi' &&
              appointment.status != 'Tamamlandı')
            ElevatedButton(
              onPressed: () {
                // Gerçek uygulamada, burada API'ye randevu iptal etmek için istek atılır
                // Şimdilik sadece listeyi güncelliyoruz
                final index =
                    _appointments.indexWhere((a) => a.id == appointment.id);
                if (index != -1) {
                  final updatedAppointment = Appointment(
                    id: appointment.id,
                    patientName: appointment.patientName,
                    doctorName: appointment.doctorName,
                    date: appointment.date,
                    time: appointment.time,
                    status: 'İptal Edildi',
                    type: appointment.type,
                  );

                  setState(() {
                    _appointments[index] = updatedAppointment;
                    _filterAppointments();
                  });
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Randevu iptal edildi'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('İptal Et'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
            tooltip: 'Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusFilters.map((status) => Tab(text: status)).toList(),
        ),
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
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterAppointments();
                    },
                    decoration: InputDecoration(
                      hintText: 'Randevu ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddAppointmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Randevu'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Randevu listesi
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
                              onPressed: _fetchAppointments,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : _filteredAppointments.isEmpty
                        ? const Center(
                            child: Text('Randevu bulunamadı'),
                          )
                        : ListView.builder(
                            itemCount: _filteredAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = _filteredAppointments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _getStatusColor(appointment.status),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(appointment.patientName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} - ${appointment.time}'),
                                      Text(
                                          '${appointment.type} - ${appointment.doctorName}'),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                                  appointment.status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          appointment.status,
                                          style: TextStyle(
                                            color: _getStatusColor(
                                                appointment.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () =>
                                        _showAppointmentDetailsDialog(
                                            appointment),
                                    tooltip: 'Detaylar',
                                  ),
                                  onTap: () => _showAppointmentDetailsDialog(
                                      appointment),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Bekleyen':
        return Colors.orange;
      case 'Onaylandı':
        return Colors.blue;
      case 'Tamamlandı':
        return Colors.green;
      case 'İptal Edildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
