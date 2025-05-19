﻿using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IAppointmentService
    {
        Task<bool> CreateAppointment(SaveAppointmentViewModel appointmentViewModel);
        Task<List<AppointmentViewModel>> GetAllAppointments();
        Task<AppointmentViewModel> GetAppointmentById(int appointmentId);
        Task<bool> UpdateAppointment(int appointmentId, SaveAppointmentViewModel appointmentViewModel);
        Task<bool> DeleteAppointment(int appointmentId);
        Task<bool> UpdateStatus(int appointmentId, string newStatus);
        Task<List<AppointmentViewModel>> GetAppointmentsByPatientId(int patientId);
    }
}
