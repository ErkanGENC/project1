import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/change_password_screen.dart';
import '../screens/user/notification_settings_screen.dart';
import '../screens/user/privacy_policy_screen.dart';
import '../screens/dental/dental_health_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/patients_management.dart';
import '../screens/admin/appointments_management.dart';
import '../screens/admin/doctors_management.dart';
import '../screens/admin/reports_page.dart';
import '../screens/welcome_screen.dart';
import '../screens/doctor/doctor_dashboard.dart';
import '../screens/doctor/doctor_appointments_screen.dart';
import '../screens/doctor/doctor_patients_screen.dart';
import '../screens/appointment/create_appointment_screen.dart';

/// Uygulama içindeki tüm sayfaların rotalarını yöneten sınıf
class AppRoutes {
  // Ana rotalar
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String dentalHealth = '/dental-health';
  static const String welcome = '/welcome';
  static const String createAppointment = '/create-appointment';

  // Doktor rotaları
  static const String doctorDashboard = '/doctor-dashboard';
  static const String doctorAppointments = '/doctor-appointments';
  static const String doctorPatients = '/doctor-patients';

  // Kullanıcı profil rotaları
  static const String changePassword = '/profile/change-password';
  static const String notificationSettings = '/profile/notification-settings';
  static const String privacyPolicy = '/profile/privacy-policy';

  // Admin rotaları
  static const String adminDashboard = '/admin';
  static const String patientsManagement = '/admin/patients';
  static const String appointmentsManagement = '/admin/appointments';
  static const String doctorsManagement = '/admin/doctors';
  static const String reportsPage = '/admin/reports';

  /// Tüm rotaları içeren harita
  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => const HomeScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      profile: (context) => const ProfileScreen(),
      dentalHealth: (context) => const DentalHealthScreen(),
      welcome: (context) => const WelcomeScreen(),
      createAppointment: (context) => const CreateAppointmentScreen(),

      // Kullanıcı profil rotaları
      changePassword: (context) => const ChangePasswordScreen(),
      notificationSettings: (context) => const NotificationSettingsScreen(),
      privacyPolicy: (context) => const PrivacyPolicyScreen(),

      // Admin rotaları
      adminDashboard: (context) => const AdminDashboard(),
      patientsManagement: (context) => const PatientsManagement(),
      appointmentsManagement: (context) => const AppointmentsManagement(),
      doctorsManagement: (context) => const DoctorsManagement(),
      reportsPage: (context) => const ReportsPage(),

      // Doktor rotaları
      doctorDashboard: (context) => const DoctorDashboard(),
      doctorAppointments: (context) => const DoctorAppointmentsScreen(),
      doctorPatients: (context) => const DoctorPatientsScreen(),
    };
  }
}
