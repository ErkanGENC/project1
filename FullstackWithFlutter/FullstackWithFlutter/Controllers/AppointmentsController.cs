﻿using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/Appointments")]
    public class AppointmentsController : ControllerBase
    {
        private readonly IAppointmentService _appointmentService;
        private readonly IActivityService _activityService;
        private readonly ILogger<AppointmentsController> _logger;

        public AppointmentsController(IAppointmentService appointmentService, IActivityService activityService, ILogger<AppointmentsController> logger)
        {
            _appointmentService = appointmentService;
            _activityService = activityService;
            _logger = logger;
        }

        [HttpGet("GetAllAppointments")]
        public async Task<IActionResult> GetAllAppointments()
        {
            try
            {
                var appointmentList = await _appointmentService.GetAllAppointments();
                if (appointmentList != null && appointmentList.Any())
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "All appointments fetched successfully",
                        Data = appointmentList,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = true, // Boş liste dönmek bir hata değil
                        Message = "No appointments found",
                        Data = new List<AppointmentViewModel>(), // Boş liste dön
                    };
                    return Ok(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching all appointments");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching appointments: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetAppointmentById(int id)
        {
            try
            {
                var appointment = await _appointmentService.GetAppointmentById(id);
                if (appointment != null)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Appointment fetched successfully",
                        Data = appointment,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Appointment not found",
                        Data = null,
                    };
                    return NotFound(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error fetching appointment with ID {id}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching appointment: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpPost("CreateAppointment")]
        public async Task<IActionResult> CreateAppointment(SaveAppointmentViewModel appointmentViewModel)
        {
            try
            {
                var appointmentCreated = await _appointmentService.CreateAppointment(appointmentViewModel);
                if (appointmentCreated)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Appointment created successfully",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to create appointment",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating appointment");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error creating appointment: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateAppointment(int id, SaveAppointmentViewModel appointmentViewModel)
        {
            try
            {
                var appointmentUpdated = await _appointmentService.UpdateAppointment(id, appointmentViewModel);
                if (appointmentUpdated)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Appointment updated successfully",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to update appointment",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating appointment with ID {id}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error updating appointment: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAppointment(int id)
        {
            try
            {
                var appointmentDeleted = await _appointmentService.DeleteAppointment(id);
                if (appointmentDeleted)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Appointment deleted successfully",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to delete appointment",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting appointment with ID {id}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error deleting appointment: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpPut("UpdateStatus/{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusViewModel model)
        {
            try
            {
                if (id != model.Id)
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "ID mismatch",
                        Data = null
                    });
                }

                // Kullanıcı bilgilerini al
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                var userName = User.FindFirstValue(ClaimTypes.Name);

                // Randevu durumunu güncelle
                var result = await _appointmentService.UpdateStatus(id, model.Status);
                if (result)
                {
                    // Aktivite kaydı oluştur
                    await _activityService.LogAppointmentActivity(
                        "AppointmentStatusChange",
                        $"Randevu durumu '{model.Status}' olarak güncellendi",
                        userId != null ? int.Parse(userId) : null,
                        userName,
                        id
                    );

                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Randevu durumu başarıyla güncellendi",
                        Data = null
                    });
                }
                else
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Randevu durumu güncellenemedi",
                        Data = null
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating appointment status with ID {AppointmentId}", id);
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Randevu durumu güncellenirken hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }
    }
}

// Randevu durumu güncelleme için model
namespace FullstackWithFlutter.Controllers
{
    public class UpdateStatusViewModel
    {
        public int Id { get; set; }
        public required string Status { get; set; }
    }
}
