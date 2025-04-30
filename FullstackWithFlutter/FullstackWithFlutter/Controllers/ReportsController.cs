﻿using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/Reports")]
    public class ReportsController : ControllerBase
    {
        private readonly IReportService _reportService;
        private readonly ILogger<ReportsController> _logger;

        public ReportsController(IReportService reportService, ILogger<ReportsController> logger)
        {
            _reportService = reportService;
            _logger = logger;
        }

        [HttpGet("GetReportData")]
        public async Task<IActionResult> GetReportData()
        {
            try
            {
                var reportData = await _reportService.GetReportData();
                if (reportData != null)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Report data fetched successfully",
                        Data = reportData,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "No report data found",
                        Data = null,
                    };
                    return NotFound(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching report data");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching report data: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }
    }
}
