﻿using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;

namespace FullstackWithFlutter.Services
{
    public class ReportService : IReportService
    {
        private readonly IUnitofWork _unitOfWork;

        public ReportService(IUnitofWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ReportViewModel> GetReportData()
        {
            try
            {
                // Gerçek uygulamada, burada veritabanından verileri çekip işleyeceğiz
                // Şimdilik örnek veriler dönüyoruz

                // Hasta istatistikleri
                var patientStats = new PatientStatsViewModel
                {
                    TotalPatients = 256,
                    NewPatients = 24,
                    ActivePatients = 187,
                    InactivePatients = 69,
                    PatientsByAge = new List<AgeGroupViewModel>
                    {
                        new AgeGroupViewModel { Age = "0-18", Count = 45 },
                        new AgeGroupViewModel { Age = "19-30", Count = 78 },
                        new AgeGroupViewModel { Age = "31-45", Count = 92 },
                        new AgeGroupViewModel { Age = "46-60", Count = 31 },
                        new AgeGroupViewModel { Age = "60+", Count = 10 },
                    },
                    PatientsByGender = new List<GenderViewModel>
                    {
                        new GenderViewModel { Gender = "Erkek", Count = 118 },
                        new GenderViewModel { Gender = "Kadın", Count = 138 },
                    }
                };

                // Randevu istatistikleri
                var appointmentStats = new AppointmentStatsViewModel
                {
                    TotalAppointments = 412,
                    CompletedAppointments = 356,
                    CancelledAppointments = 32,
                    PendingAppointments = 24,
                    AppointmentsByMonth = new List<MonthlyAppointmentViewModel>
                    {
                        new MonthlyAppointmentViewModel { Month = "Ocak", Count = 32 },
                        new MonthlyAppointmentViewModel { Month = "Şubat", Count = 28 },
                        new MonthlyAppointmentViewModel { Month = "Mart", Count = 35 },
                        new MonthlyAppointmentViewModel { Month = "Nisan", Count = 42 },
                        new MonthlyAppointmentViewModel { Month = "Mayıs", Count = 38 },
                        new MonthlyAppointmentViewModel { Month = "Haziran", Count = 45 },
                        new MonthlyAppointmentViewModel { Month = "Temmuz", Count = 52 },
                        new MonthlyAppointmentViewModel { Month = "Ağustos", Count = 48 },
                        new MonthlyAppointmentViewModel { Month = "Eylül", Count = 40 },
                        new MonthlyAppointmentViewModel { Month = "Ekim", Count = 36 },
                        new MonthlyAppointmentViewModel { Month = "Kasım", Count = 30 },
                        new MonthlyAppointmentViewModel { Month = "Aralık", Count = 28 },
                    },
                    AppointmentsByType = new List<AppointmentTypeViewModel>
                    {
                        new AppointmentTypeViewModel { Type = "Diş Kontrolü", Count = 156 },
                        new AppointmentTypeViewModel { Type = "Dolgu", Count = 98 },
                        new AppointmentTypeViewModel { Type = "Kanal Tedavisi", Count = 45 },
                        new AppointmentTypeViewModel { Type = "Diş Çekimi", Count = 32 },
                        new AppointmentTypeViewModel { Type = "Diş Beyazlatma", Count = 28 },
                        new AppointmentTypeViewModel { Type = "Diğer", Count = 53 },
                    }
                };

                // Gelir istatistikleri
                var revenueStats = new RevenueStatsViewModel
                {
                    TotalRevenue = 145750,
                    PendingPayments = 12500,
                    RevenueByMonth = new List<MonthlyRevenueViewModel>
                    {
                        new MonthlyRevenueViewModel { Month = "Ocak", Amount = 10250 },
                        new MonthlyRevenueViewModel { Month = "Şubat", Amount = 9800 },
                        new MonthlyRevenueViewModel { Month = "Mart", Amount = 11500 },
                        new MonthlyRevenueViewModel { Month = "Nisan", Amount = 12750 },
                        new MonthlyRevenueViewModel { Month = "Mayıs", Amount = 11800 },
                        new MonthlyRevenueViewModel { Month = "Haziran", Amount = 13500 },
                        new MonthlyRevenueViewModel { Month = "Temmuz", Amount = 15200 },
                        new MonthlyRevenueViewModel { Month = "Ağustos", Amount = 14800 },
                        new MonthlyRevenueViewModel { Month = "Eylül", Amount = 12500 },
                        new MonthlyRevenueViewModel { Month = "Ekim", Amount = 11200 },
                        new MonthlyRevenueViewModel { Month = "Kasım", Amount = 10800 },
                        new MonthlyRevenueViewModel { Month = "Aralık", Amount = 9650 },
                    },
                    RevenueByService = new List<ServiceRevenueViewModel>
                    {
                        new ServiceRevenueViewModel { Service = "Diş Kontrolü", Amount = 31250 },
                        new ServiceRevenueViewModel { Service = "Dolgu", Amount = 29400 },
                        new ServiceRevenueViewModel { Service = "Kanal Tedavisi", Amount = 22500 },
                        new ServiceRevenueViewModel { Service = "Diş Çekimi", Amount = 16000 },
                        new ServiceRevenueViewModel { Service = "Diş Beyazlatma", Amount = 14000 },
                        new ServiceRevenueViewModel { Service = "Diğer", Amount = 32600 },
                    }
                };

                // Tüm istatistikleri birleştir
                var reportData = new ReportViewModel
                {
                    PatientStats = patientStats,
                    AppointmentStats = appointmentStats,
                    RevenueStats = revenueStats
                };

                return reportData;
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"Error in GetReportData: {ex.Message}");
                throw; // Rethrow to let the controller handle it
            }
        }
    }
}
