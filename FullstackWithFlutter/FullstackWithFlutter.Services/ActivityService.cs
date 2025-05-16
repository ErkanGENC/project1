﻿using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace FullstackWithFlutter.Services
{
    public class ActivityService : IActivityService
    {
        private readonly IUnitofWork _unitOfWork;
        private readonly ILogger<ActivityService> _logger;

        public ActivityService(IUnitofWork unitOfWork, ILogger<ActivityService> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }

        public async Task<ActivityViewModel> AddActivity(SaveActivityViewModel activityViewModel)
        {
            try
            {
                var activity = new Activity
                {
                    Type = activityViewModel.Type,
                    Description = activityViewModel.Description,
                    UserId = activityViewModel.UserId,
                    UserName = activityViewModel.UserName,
                    CreatedDate = DateTime.Now,
                    Details = activityViewModel.Details,
                    Icon = activityViewModel.Icon,
                    Color = activityViewModel.Color
                };

                await _unitOfWork.Activities.Add(activity);
                _unitOfWork.Complete();

                return new ActivityViewModel
                {
                    Id = activity.Id,
                    Type = activity.Type,
                    Description = activity.Description,
                    UserId = activity.UserId,
                    UserName = activity.UserName,
                    CreatedDate = activity.CreatedDate,
                    Details = activity.Details,
                    Icon = activity.Icon,
                    Color = activity.Color
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding activity");
                throw;
            }
        }

        public async Task<ActivityViewModel> GetActivityById(int id)
        {
            try
            {
                var activity = await _unitOfWork.Activities.Get(id);
                if (activity == null)
                {
                    return null;
                }

                return new ActivityViewModel
                {
                    Id = activity.Id,
                    Type = activity.Type,
                    Description = activity.Description,
                    UserId = activity.UserId,
                    UserName = activity.UserName,
                    CreatedDate = activity.CreatedDate,
                    Details = activity.Details,
                    Icon = activity.Icon,
                    Color = activity.Color
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting activity by id");
                throw;
            }
        }

        public async Task<IEnumerable<ActivityViewModel>> GetAllActivities()
        {
            try
            {
                var activities = await _unitOfWork.Activities.GetAll();
                return activities.Select(a => new ActivityViewModel
                {
                    Id = a.Id,
                    Type = a.Type,
                    Description = a.Description,
                    UserId = a.UserId,
                    UserName = a.UserName,
                    CreatedDate = a.CreatedDate,
                    Details = a.Details,
                    Icon = a.Icon,
                    Color = a.Color
                }).OrderByDescending(a => a.CreatedDate);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all activities");
                throw;
            }
        }

        public async Task<IEnumerable<ActivityViewModel>> GetRecentActivities(int count)
        {
            try
            {
                var activities = await _unitOfWork.Activities.GetRecentActivities(count);
                return activities.Select(a => new ActivityViewModel
                {
                    Id = a.Id,
                    Type = a.Type,
                    Description = a.Description,
                    UserId = a.UserId,
                    UserName = a.UserName,
                    CreatedDate = a.CreatedDate,
                    Details = a.Details,
                    Icon = a.Icon,
                    Color = a.Color
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting recent activities");
                throw;
            }
        }

        public async Task<bool> LogUserActivity(string type, string description, int? userId, string? userName, string? details = null)
        {
            try
            {
                var activity = new Activity
                {
                    Type = type,
                    Description = description,
                    UserId = userId,
                    UserName = userName,
                    CreatedDate = DateTime.Now,
                    Details = details,
                    Icon = GetIconForActivityType(type),
                    Color = GetColorForActivityType(type)
                };

                await _unitOfWork.Activities.Add(activity);
                _unitOfWork.Complete();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging user activity");
                return false;
            }
        }

        public async Task<bool> LogAppointmentActivity(string type, string description, int? userId, string? userName, int appointmentId, string? details = null)
        {
            try
            {
                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment == null)
                {
                    _logger.LogWarning("Appointment not found for activity logging: {AppointmentId}", appointmentId);
                    return false;
                }

                var detailsObj = new
                {
                    AppointmentId = appointmentId,
                    PatientId = appointment.PatientId,
                    PatientName = appointment.PatientName,
                    DoctorId = appointment.DoctorId,
                    DoctorName = appointment.DoctorName,
                    Date = appointment.Date,
                    Status = appointment.Status,
                    AdditionalDetails = details
                };

                var activity = new Activity
                {
                    Type = type,
                    Description = description,
                    UserId = userId,
                    UserName = userName,
                    CreatedDate = DateTime.Now,
                    Details = JsonSerializer.Serialize(detailsObj),
                    Icon = GetIconForActivityType(type),
                    Color = GetColorForActivityType(type)
                };

                await _unitOfWork.Activities.Add(activity);
                _unitOfWork.Complete();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging appointment activity");
                return false;
            }
        }

        public async Task<bool> LogDoctorActivity(string type, string description, int? userId, string? userName, int doctorId, string? details = null)
        {
            try
            {
                var doctor = await _unitOfWork.Doctors.Get(doctorId);
                if (doctor == null)
                {
                    _logger.LogWarning("Doctor not found for activity logging: {DoctorId}", doctorId);
                    return false;
                }

                var detailsObj = new
                {
                    DoctorId = doctorId,
                    DoctorName = doctor.Name,
                    Specialization = doctor.Specialization,
                    AdditionalDetails = details
                };

                var activity = new Activity
                {
                    Type = type,
                    Description = description,
                    UserId = userId,
                    UserName = userName,
                    CreatedDate = DateTime.Now,
                    Details = JsonSerializer.Serialize(detailsObj),
                    Icon = GetIconForActivityType(type),
                    Color = GetColorForActivityType(type)
                };

                await _unitOfWork.Activities.Add(activity);
                _unitOfWork.Complete();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging doctor activity");
                return false;
            }
        }

        private string GetIconForActivityType(string type)
        {
            return type switch
            {
                "UserRegistration" => "person_add",
                "UserLogin" => "login",
                "UserLogout" => "logout",
                "AppointmentCreation" => "event_available",
                "AppointmentStatusChange" => "event_note",
                "DoctorAssignment" => "medical_services",
                "AdminAction" => "admin_panel_settings",
                _ => "info",
            };
        }

        private string GetColorForActivityType(string type)
        {
            return type switch
            {
                "UserRegistration" => "#4CAF50", // Green
                "UserLogin" => "#2196F3", // Blue
                "UserLogout" => "#607D8B", // Blue Grey
                "AppointmentCreation" => "#FF9800", // Orange
                "AppointmentStatusChange" => "#FFC107", // Amber
                "DoctorAssignment" => "#9C27B0", // Purple
                "AdminAction" => "#F44336", // Red
                _ => "#9E9E9E", // Grey
            };
        }
    }
}
