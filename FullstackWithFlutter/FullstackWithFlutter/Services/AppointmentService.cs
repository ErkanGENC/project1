﻿using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.Extensions.Logging;

namespace FullstackWithFlutter.Services
{
    public class AppointmentService : IAppointmentService
    {
        private readonly IUnitofWork _unitOfWork;
        private readonly IMapper _mapper;
        private readonly IActivityService _activityService;
        private readonly ILogger<AppointmentService> _logger;

        public AppointmentService(IUnitofWork unitOfWork, IMapper mapper, IActivityService activityService, ILogger<AppointmentService> logger)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
            _activityService = activityService;
            _logger = logger;
        }

        public async Task<bool> CreateAppointment(SaveAppointmentViewModel appointmentViewModel)
        {
            if (appointmentViewModel != null)
            {
                var newAppointment = _mapper.Map<Appointment>(appointmentViewModel);
                newAppointment.CreatedDate = DateTime.Now;
                newAppointment.CreatedBy = "API";
                await _unitOfWork.Appointments.Add(newAppointment);
                var result = _unitOfWork.Complete();
                return result > 0;
            }
            return false;
        }

        public async Task<bool> DeleteAppointment(int appointmentId)
        {
            if (appointmentId > 0)
            {
                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment != null)
                {
                    _unitOfWork.Appointments.Delete(appointment);
                    var result = _unitOfWork.Complete();
                    return result > 0;
                }
            }
            return false;
        }

        public async Task<List<AppointmentViewModel>> GetAllAppointments()
        {
            try
            {
                var appointmentList = await _unitOfWork.Appointments.GetAll();
                if (appointmentList == null)
                {
                    return new List<AppointmentViewModel>();
                }
                var appointmentListMap = _mapper.Map<List<AppointmentViewModel>>(appointmentList);
                return appointmentListMap;
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"Error in GetAllAppointments: {ex.Message}");
                throw; // Rethrow to let the controller handle it
            }
        }

        public async Task<AppointmentViewModel> GetAppointmentById(int appointmentId)
        {
            if (appointmentId > 0)
            {
                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment != null)
                {
                    var appointmentResp = _mapper.Map<AppointmentViewModel>(appointment);
                    return appointmentResp;
                }
            }
            return null;
        }

        public async Task<bool> UpdateAppointment(int appointmentId, SaveAppointmentViewModel appointmentViewModel)
        {
            if (appointmentId > 0)
            {
                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment != null)
                {
                    appointment.PatientName = appointmentViewModel.PatientName;
                    appointment.DoctorName = appointmentViewModel.DoctorName;
                    appointment.Date = appointmentViewModel.Date;
                    appointment.Time = appointmentViewModel.Time;
                    appointment.Status = appointmentViewModel.Status;
                    appointment.Type = appointmentViewModel.Type;
                    appointment.UpdatedDate = DateTime.Now;
                    appointment.UpdatedBy = "API";
                    _unitOfWork.Appointments.Update(appointment);
                    var result = _unitOfWork.Complete();
                    return result > 0;
                }
            }
            return false;
        }

        public async Task<bool> UpdateStatus(int appointmentId, string newStatus)
        {
            try
            {
                if (appointmentId <= 0)
                {
                    _logger.LogWarning("Invalid appointment ID: {AppointmentId}", appointmentId);
                    return false;
                }

                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment == null)
                {
                    _logger.LogWarning("Appointment not found: {AppointmentId}", appointmentId);
                    return false;
                }

                // Eski durumu kaydet
                string oldStatus = appointment.Status ?? "Bekleyen";

                // Durumu güncelle
                appointment.Status = newStatus;
                appointment.UpdatedDate = DateTime.Now;
                appointment.UpdatedBy = "API";
                _unitOfWork.Appointments.Update(appointment);
                var result = _unitOfWork.Complete();

                if (result > 0)
                {
                    // Aktivite kaydı oluştur
                    string description = $"Randevu durumu '{oldStatus}' -> '{newStatus}' olarak değiştirildi";
                    await _activityService.LogAppointmentActivity(
                        "AppointmentStatusChange",
                        description,
                        null, // Kullanıcı ID'si
                        null, // Kullanıcı adı
                        appointmentId,
                        $"Eski durum: {oldStatus}, Yeni durum: {newStatus}"
                    );

                    _logger.LogInformation("Appointment status updated: {AppointmentId}, {OldStatus} -> {NewStatus}",
                        appointmentId, oldStatus, newStatus);
                    return true;
                }
                else
                {
                    _logger.LogWarning("Failed to update appointment status: {AppointmentId}", appointmentId);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating appointment status: {AppointmentId}", appointmentId);
                return false;
            }
        }

        public async Task<List<AppointmentViewModel>> GetAppointmentsByPatientId(int patientId)
        {
            try
            {
                if (patientId <= 0)
                {
                    _logger.LogWarning("Invalid patient ID: {PatientId}", patientId);
                    return new List<AppointmentViewModel>();
                }

                // Tüm randevuları al
                var allAppointments = await _unitOfWork.Appointments.GetAll();
                if (allAppointments == null)
                {
                    return new List<AppointmentViewModel>();
                }

                // Hastaya ait randevuları filtrele
                var patientAppointments = allAppointments.Where(a => a.PatientId == patientId).ToList();

                // ViewModel'e dönüştür
                var appointmentViewModels = _mapper.Map<List<AppointmentViewModel>>(patientAppointments);

                _logger.LogInformation("Retrieved {Count} appointments for patient ID: {PatientId}",
                    appointmentViewModels.Count, patientId);

                return appointmentViewModels;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting appointments for patient ID: {PatientId}", patientId);
                return new List<AppointmentViewModel>();
            }
        }
    }
}
