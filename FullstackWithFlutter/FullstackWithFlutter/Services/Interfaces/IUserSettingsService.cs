﻿using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IUserSettingsService
    {
        Task<UserSettingsViewModel> GetUserSettingsByUserId(int userId);
        Task<bool> CreateUserSettings(SaveUserSettingsViewModel settingsViewModel);
        Task<bool> UpdateUserSettings(int userId, SaveUserSettingsViewModel settingsViewModel);
    }
}
