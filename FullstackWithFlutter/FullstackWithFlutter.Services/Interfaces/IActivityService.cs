﻿using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IActivityService
    {
        Task<IEnumerable<ActivityViewModel>> GetAllActivities();
        Task<IEnumerable<ActivityViewModel>> GetRecentActivities(int count);
        Task<ActivityViewModel> GetActivityById(int id);
        Task<ActivityViewModel> AddActivity(SaveActivityViewModel activityViewModel);
        Task<bool> LogUserActivity(string type, string description, int? userId, string? userName, string? details = null);
        Task<bool> LogAppointmentActivity(string type, string description, int? userId, string? userName, int appointmentId, string? details = null);
        Task<bool> LogDoctorActivity(string type, string description, int? userId, string? userName, int doctorId, string? details = null);
    }
}
