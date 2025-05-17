﻿using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FullstackWithFlutter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserSettingsController : ControllerBase
    {
        private readonly IUserSettingsService _userSettingsService;
        private readonly ILogger<UserSettingsController> _logger;

        public UserSettingsController(IUserSettingsService userSettingsService, ILogger<UserSettingsController> logger)
        {
            _userSettingsService = userSettingsService;
            _logger = logger;
        }

        [HttpGet("GetUserSettings")]
        [Authorize]
        public async Task<IActionResult> GetUserSettings()
        {
            try
            {
                // Token'dan kullanıcı ID'sini al
                var userId = GetUserIdFromToken();

                if (userId <= 0)
                {
                    return Unauthorized(new ApiResponse
                    {
                        Status = false,
                        Message = "Oturum açılmamış",
                        Data = null
                    });
                }

                var settings = await _userSettingsService.GetUserSettingsByUserId(userId);
                
                if (settings != null)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Kullanıcı ayarları başarıyla alındı",
                        Data = settings
                    });
                }
                else
                {
                    // Kullanıcının ayarları yoksa varsayılan ayarları döndür
                    var defaultSettings = new UserSettingsViewModel
                    {
                        UserId = userId,
                        IsDarkMode = false,
                        FontFamily = "Default",
                        FontSize = 1.0,
                        Language = "tr"
                    };

                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Varsayılan kullanıcı ayarları",
                        Data = defaultSettings
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user settings");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Kullanıcı ayarları alınırken bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpPost("SaveUserSettings")]
        [Authorize]
        public async Task<IActionResult> SaveUserSettings(SaveUserSettingsViewModel settingsViewModel)
        {
            try
            {
                // Token'dan kullanıcı ID'sini al
                var userId = GetUserIdFromToken();

                if (userId <= 0)
                {
                    return Unauthorized(new ApiResponse
                    {
                        Status = false,
                        Message = "Oturum açılmamış",
                        Data = null
                    });
                }

                // Kullanıcı ID'sini ayarla
                settingsViewModel.UserId = userId;

                // Ayarları kaydet
                var result = await _userSettingsService.CreateUserSettings(settingsViewModel);

                if (result)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Kullanıcı ayarları başarıyla kaydedildi",
                        Data = null
                    });
                }
                else
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Kullanıcı ayarları kaydedilemedi",
                        Data = null
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving user settings");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Kullanıcı ayarları kaydedilirken bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpPut("UpdateUserSettings")]
        [Authorize]
        public async Task<IActionResult> UpdateUserSettings(SaveUserSettingsViewModel settingsViewModel)
        {
            try
            {
                // Token'dan kullanıcı ID'sini al
                var userId = GetUserIdFromToken();

                if (userId <= 0)
                {
                    return Unauthorized(new ApiResponse
                    {
                        Status = false,
                        Message = "Oturum açılmamış",
                        Data = null
                    });
                }

                // Ayarları güncelle
                var result = await _userSettingsService.UpdateUserSettings(userId, settingsViewModel);

                if (result)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "Kullanıcı ayarları başarıyla güncellendi",
                        Data = null
                    });
                }
                else
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Kullanıcı ayarları güncellenemedi",
                        Data = null
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user settings");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Kullanıcı ayarları güncellenirken bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // Kullanıcı ID'sini token'dan al
        private int GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("userId");
            if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
            {
                return userId;
            }
            return 0;
        }
    }
}
