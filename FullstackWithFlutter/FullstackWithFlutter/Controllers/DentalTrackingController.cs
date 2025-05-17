﻿using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DentalTrackingController : ControllerBase
    {
        private readonly IDentalTrackingService _dentalTrackingService;
        private readonly ILogger<DentalTrackingController> _logger;

        public DentalTrackingController(
            IDentalTrackingService dentalTrackingService,
            ILogger<DentalTrackingController> logger)
        {
            _dentalTrackingService = dentalTrackingService;
            _logger = logger;
        }

        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetAllRecords()
        {
            try
            {
                var records = await _dentalTrackingService.GetAllRecords();
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "Dental tracking records fetched successfully",
                    Data = records
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching all dental tracking records");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching dental tracking records: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpGet("user/{userId}")]
        [Authorize]
        public async Task<IActionResult> GetUserRecords(int userId)
        {
            try
            {
                var records = await _dentalTrackingService.GetUserRecords(userId);
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "User dental tracking records fetched successfully",
                    Data = records
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error fetching dental tracking records for user {userId}");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching user dental tracking records: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpGet("user/{userId}/date")]
        [Authorize]
        public async Task<IActionResult> GetUserRecordByDate(int userId, [FromQuery] DateTime date)
        {
            try
            {
                var record = await _dentalTrackingService.GetUserRecordByDate(userId, date);
                if (record == null)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "No dental tracking record found for the specified date",
                        Data = null
                    });
                }

                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "User dental tracking record fetched successfully",
                    Data = record
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error fetching dental tracking record for user {userId} on date {date}");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching user dental tracking record: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpGet("user/{userId}/range")]
        [Authorize]
        public async Task<IActionResult> GetUserRecordsForDateRange(
            int userId,
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate)
        {
            try
            {
                var records = await _dentalTrackingService.GetUserRecordsForDateRange(userId, startDate, endDate);
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "User dental tracking records fetched successfully",
                    Data = records
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error fetching dental tracking records for user {userId} between {startDate} and {endDate}");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching user dental tracking records: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> SaveRecord(SaveDentalTrackingViewModel recordViewModel)
        {
            try
            {
                var result = await _dentalTrackingService.SaveRecord(recordViewModel);
                if (result)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Dental tracking record saved successfully",
                        Data = null
                    });
                }
                else
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Failed to save dental tracking record",
                        Data = null
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving dental tracking record");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error saving dental tracking record: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateRecord(int id, SaveDentalTrackingViewModel recordViewModel)
        {
            try
            {
                var result = await _dentalTrackingService.UpdateRecord(id, recordViewModel);
                if (result)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Dental tracking record updated successfully",
                        Data = null
                    });
                }
                else
                {
                    return NotFound(new ApiResponse
                    {
                        Status = false,
                        Message = "Dental tracking record not found",
                        Data = null
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating dental tracking record with ID {id}");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error updating dental tracking record: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteRecord(int id)
        {
            try
            {
                var result = await _dentalTrackingService.DeleteRecord(id);
                if (result)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Dental tracking record deleted successfully",
                        Data = null
                    });
                }
                else
                {
                    return NotFound(new ApiResponse
                    {
                        Status = false,
                        Message = "Dental tracking record not found",
                        Data = null
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting dental tracking record with ID {id}");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error deleting dental tracking record: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpGet("user/{userId}/summary")]
        [Authorize]
        public async Task<IActionResult> GetUserSummary(int userId)
        {
            try
            {
                var summary = await _dentalTrackingService.GetUserSummary(userId);
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "User dental tracking summary fetched successfully",
                    Data = summary
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error fetching dental tracking summary for user {userId}");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching user dental tracking summary: " + ex.Message,
                    Data = null
                });
            }
        }
    }
}
