﻿using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ActivityController : ControllerBase
    {
        private readonly IActivityService _activityService;
        private readonly ILogger<ActivityController> _logger;

        public ActivityController(IActivityService activityService, ILogger<ActivityController> logger)
        {
            _activityService = activityService;
            _logger = logger;
        }

        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetAllActivities()
        {
            try
            {
                var activities = await _activityService.GetAllActivities();
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "Activities fetched successfully",
                    Data = activities
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching activities");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching activities: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpGet("recent/{count}")]
        [Authorize]
        public async Task<IActionResult> GetRecentActivities(int count)
        {
            try
            {
                var activities = await _activityService.GetRecentActivities(count);
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "Recent activities fetched successfully",
                    Data = activities
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching recent activities");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching recent activities: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetActivityById(int id)
        {
            try
            {
                var activity = await _activityService.GetActivityById(id);
                if (activity == null)
                {
                    return NotFound(new ApiResponse
                    {
                        Status = false,
                        Message = "Activity not found",
                        Data = null
                    });
                }

                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "Activity fetched successfully",
                    Data = activity
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching activity by id");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching activity: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> AddActivity(SaveActivityViewModel activityViewModel)
        {
            try
            {
                var activity = await _activityService.AddActivity(activityViewModel);
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "Activity added successfully",
                    Data = activity
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding activity");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error adding activity: " + ex.Message,
                    Data = null
                });
            }
        }
    }
}
