using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using FullstackWithFlutter.Services.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using System.Linq;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    // Geliştirme aşamasında yetkilendirmeyi geçici olarak kaldırıyoruz
    // [Authorize(Roles = "admin")]
    public class AdminController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IAppointmentService _appointmentService;
        private readonly ILogger<AdminController> _logger;

        public AdminController(
            IUserService userService,
            IAppointmentService appointmentService,
            ILogger<AdminController> logger)
        {
            _userService = userService;
            _appointmentService = appointmentService;
            _logger = logger;
        }

        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboardData()
        {
            try
            {
                // Tüm hastaları al
                var allPatients = await _userService.GetAllUsers();
                _logger.LogInformation($"Toplam hasta sayısı: {allPatients.Count}");

                // Hasta listesini logla
                foreach (var patient in allPatients)
                {
                    _logger.LogInformation($"Hasta ID: {patient.Id}, Ad: {patient.FullName}, Email: {patient.Email}");
                }

                int totalPatients = allPatients.Count;

                // Aktif hastaları hesapla (son 30 gün içinde randevusu olanlar)
                var thirtyDaysAgo = DateTime.Now.AddDays(-30);
                var recentAppointments = await _appointmentService.GetAllAppointments();
                _logger.LogInformation($"Toplam randevu sayısı: {recentAppointments.Count}");

                // Randevu listesini logla
                foreach (var appointment in recentAppointments)
                {
                    _logger.LogInformation($"Randevu ID: {appointment.Id}, Tarih: {appointment.Date}, Durum: {appointment.Status}");
                }

                var recentPatientIds = recentAppointments
                    .Where(a => a.Date >= thirtyDaysAgo)
                    .Select(a => a.PatientId)
                    .Distinct()
                    .ToList();
                _logger.LogInformation($"Aktif hasta sayısı: {recentPatientIds.Count}");
                int activePatients = recentPatientIds.Count;

                // Bugünkü randevuları al
                var today = DateTime.Today;
                var todayAppointments = recentAppointments
                    .Where(a => a.Date.Date == today)
                    .ToList();
                int todayAppointmentsCount = todayAppointments.Count;

                // Bekleyen randevuları al (bugün ve sonrası, onaylanmamış)
                var pendingAppointments = recentAppointments
                    .Where(a => a.Date.Date >= today && a.Status == "Bekliyor")
                    .ToList();
                int pendingAppointmentsCount = pendingAppointments.Count;

                // Önceki dönem verilerini hesapla (30 gün öncesi)
                var previousPeriodStart = DateTime.Now.AddDays(-60);
                var previousPeriodEnd = DateTime.Now.AddDays(-30);

                // Önceki dönemdeki hasta sayısı - CreatedDate bilgisi olmadığı için sabit bir değer kullanıyoruz
                // Gerçek uygulamada, veritabanından doğrudan sorgu yapılabilir
                var previousPeriodPatients = totalPatients > 10 ? totalPatients - 5 : 0;

                // Önceki dönemdeki aktif hasta sayısı
                var previousPeriodActivePatients = recentAppointments
                    .Where(a => a.Date >= previousPeriodStart && a.Date <= previousPeriodEnd)
                    .Select(a => a.PatientId)
                    .Distinct()
                    .Count();

                // Önceki dönemdeki günlük randevu sayısı (aynı gün)
                var previousPeriodDay = today.AddDays(-30);
                var previousPeriodDayAppointments = recentAppointments
                    .Where(a => a.Date.Date == previousPeriodDay)
                    .Count();

                // Önceki dönemdeki bekleyen randevu sayısı
                var previousPeriodPendingAppointments = recentAppointments
                    .Where(a => a.Date.Date >= previousPeriodDay && a.Date.Date <= previousPeriodEnd && a.Status == "Bekliyor")
                    .Count();

                // Artış yüzdelerini hesapla
                int totalPatientsPercentage = previousPeriodPatients > 0
                    ? (int)Math.Round((totalPatients - previousPeriodPatients) * 100.0 / previousPeriodPatients)
                    : 100; // Önceki dönemde hasta yoksa %100 artış

                int todayAppointmentsPercentage = previousPeriodDayAppointments > 0
                    ? (int)Math.Round((todayAppointmentsCount - previousPeriodDayAppointments) * 100.0 / previousPeriodDayAppointments)
                    : (todayAppointmentsCount > 0 ? 100 : 0); // Önceki dönemde randevu yoksa ve şimdi varsa %100 artış

                int activePatientsPercentage = previousPeriodActivePatients > 0
                    ? (int)Math.Round((activePatients - previousPeriodActivePatients) * 100.0 / previousPeriodActivePatients)
                    : (activePatients > 0 ? 100 : 0); // Önceki dönemde aktif hasta yoksa ve şimdi varsa %100 artış

                int pendingAppointmentsPercentage = previousPeriodPendingAppointments > 0
                    ? (int)Math.Round((pendingAppointmentsCount - previousPeriodPendingAppointments) * 100.0 / previousPeriodPendingAppointments)
                    : (pendingAppointmentsCount > 0 ? 100 : 0); // Önceki dönemde bekleyen randevu yoksa ve şimdi varsa %100 artış

                _logger.LogInformation($"Dashboard hesaplamaları: " +
                    $"Toplam hasta: {totalPatients} (Değişim: %{totalPatientsPercentage}), " +
                    $"Bugünkü randevular: {todayAppointmentsCount} (Değişim: %{todayAppointmentsPercentage}), " +
                    $"Aktif hastalar: {activePatients} (Değişim: %{activePatientsPercentage}), " +
                    $"Bekleyen randevular: {pendingAppointmentsCount} (Değişim: %{pendingAppointmentsPercentage})");

                var dashboardData = new
                {
                    totalPatients,
                    totalPatientsPercentage,
                    todayAppointments = todayAppointmentsCount,
                    todayAppointmentsPercentage,
                    activePatients,
                    activePatientsPercentage,
                    pendingAppointments = pendingAppointmentsCount,
                    pendingAppointmentsPercentage
                };

                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "Dashboard verileri başarıyla alındı",
                    Data = dashboardData
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Dashboard verileri alınırken hata oluştu");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Dashboard verileri alınırken hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }
    }
}
