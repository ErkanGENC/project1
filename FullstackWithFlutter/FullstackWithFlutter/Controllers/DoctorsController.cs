﻿using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/Doctors")]
    public class DoctorsController : ControllerBase
    {
        private readonly IDoctorService _doctorService;
        private readonly ILogger<DoctorsController> _logger;

        public DoctorsController(IDoctorService doctorService, ILogger<DoctorsController> logger)
        {
            _doctorService = doctorService;
            _logger = logger;
        }

        [HttpGet("GetAllDoctors")]
        public async Task<IActionResult> GetAllDoctors()
        {
            try
            {
                var doctorList = await _doctorService.GetAllDoctors();
                if (doctorList != null && doctorList.Any())
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "All doctors fetched successfully",
                        Data = doctorList,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = true, // Boş liste dönmek bir hata değil
                        Message = "No doctors found",
                        Data = new List<DoctorViewModel>(), // Boş liste dön
                    };
                    return Ok(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching all doctors");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching doctors: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetDoctorById(int id)
        {
            try
            {
                var doctor = await _doctorService.GetDoctorById(id);
                if (doctor != null)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Doctor fetched successfully",
                        Data = doctor,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Doctor not found",
                        Data = null,
                    };
                    return NotFound(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error fetching doctor with ID {id}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching doctor: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpPost("CreateDoctor")]
        public async Task<IActionResult> CreateDoctor(SaveDoctorViewModel doctorViewModel)
        {
            try
            {
                var doctorCreated = await _doctorService.CreateDoctor(doctorViewModel);
                if (doctorCreated)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Doctor created successfully",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to create doctor",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating doctor");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error creating doctor: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateDoctor(int id, SaveDoctorViewModel doctorViewModel)
        {
            try
            {
                var doctorUpdated = await _doctorService.UpdateDoctor(id, doctorViewModel);
                if (doctorUpdated)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Doctor updated successfully",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to update doctor",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating doctor with ID {id}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error updating doctor: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDoctor(int id)
        {
            try
            {
                var doctorDeleted = await _doctorService.DeleteDoctor(id);
                if (doctorDeleted)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Doctor deleted successfully",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to delete doctor",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting doctor with ID {id}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error deleting doctor: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpGet("GetCurrentDoctor")]
        public async Task<IActionResult> GetCurrentDoctor()
        {
            try
            {
                // Kullanıcı kimliğini al
                var userId = User.FindFirst("userId")?.Value;
                var email = User.FindFirst("email")?.Value;
                var fullName = User.FindFirst("fullName")?.Value;
                var role = User.FindFirst("role")?.Value;

                if (string.IsNullOrEmpty(userId) || string.IsNullOrEmpty(email))
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "User information not found in token",
                        Data = null,
                    };
                    return BadRequest(resp);
                }

                // Doktor bilgilerini al
                var doctor = await _doctorService.GetDoctorByEmail(email);
                if (doctor != null)
                {
                    // Doktor rolünü ekle
                    doctor.Role = "doctor";

                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Current doctor fetched successfully",
                        Data = doctor,
                    };
                    return Ok(resp);
                }
                else
                {
                    // Doktor bulunamadıysa, token'dan gelen bilgilerle yeni bir doktor nesnesi oluştur
                    var doctorFromToken = new DoctorViewModel
                    {
                        Id = int.Parse(userId),
                        Email = email,
                        Name = fullName,
                        Role = role ?? "doctor",
                        Specialization = User.FindFirst("specialization")?.Value ?? "Uzman Doktor"
                    };

                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Doctor information created from token",
                        Data = doctorFromToken,
                    };
                    return Ok(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching current doctor");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching current doctor: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }
    }
}
