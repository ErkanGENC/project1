﻿using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.Extensions.Logging;

namespace FullstackWithFlutter.Services
{
    public class UserSettingsService : IUserSettingsService
    {
        private readonly IUnitofWork _unitofWork;
        private readonly IMapper _mapper;
        private readonly ILogger<UserSettingsService> _logger;

        public UserSettingsService(IUnitofWork unitofWork, IMapper mapper, ILogger<UserSettingsService> logger)
        {
            _unitofWork = unitofWork;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<UserSettingsViewModel> GetUserSettingsByUserId(int userId)
        {
            try
            {
                // Kullanıcı ID'sine göre ayarları bul
                var settings = (await _unitofWork.userSettings.Find(s => s.UserId == userId)).FirstOrDefault();

                // Eğer ayarlar bulunamazsa null döndür
                if (settings == null)
                {
                    return null;
                }

                // Ayarları ViewModel'e dönüştür ve döndür
                return _mapper.Map<UserSettingsViewModel>(settings);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting user settings for user ID {userId}");
                return null;
            }
        }

        public async Task<bool> CreateUserSettings(SaveUserSettingsViewModel settingsViewModel)
        {
            try
            {
                // Kullanıcının mevcut ayarlarını kontrol et
                var existingSettings = (await _unitofWork.userSettings.Find(s => s.UserId == settingsViewModel.UserId)).FirstOrDefault();

                // Eğer ayarlar zaten varsa, güncelleme yap
                if (existingSettings != null)
                {
                    return await UpdateUserSettings(settingsViewModel.UserId, settingsViewModel);
                }

                // Yeni ayarlar oluştur
                var newSettings = _mapper.Map<UserSettings>(settingsViewModel);
                newSettings.CreatedDate = DateTime.Now;
                newSettings.CreatedBy = "API";

                // Veritabanına ekle
                await _unitofWork.userSettings.Add(newSettings);
                var result = _unitofWork.Complete();

                return result > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating user settings for user ID {settingsViewModel.UserId}");
                return false;
            }
        }

        public async Task<bool> UpdateUserSettings(int userId, SaveUserSettingsViewModel settingsViewModel)
        {
            try
            {
                // Kullanıcının mevcut ayarlarını bul
                var existingSettings = (await _unitofWork.userSettings.Find(s => s.UserId == userId)).FirstOrDefault();

                // Eğer ayarlar bulunamazsa, yeni ayarlar oluştur
                if (existingSettings == null)
                {
                    return await CreateUserSettings(settingsViewModel);
                }

                // Ayarları güncelle
                existingSettings.IsDarkMode = settingsViewModel.IsDarkMode;
                existingSettings.FontFamily = settingsViewModel.FontFamily;
                existingSettings.FontSize = settingsViewModel.FontSize;
                existingSettings.Language = settingsViewModel.Language;
                existingSettings.UpdatedDate = DateTime.Now;
                existingSettings.UpdatedBy = "API";

                // Veritabanını güncelle
                _unitofWork.userSettings.Update(existingSettings);
                var result = _unitofWork.Complete();

                return result > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating user settings for user ID {userId}");
                return false;
            }
        }
    }
}
