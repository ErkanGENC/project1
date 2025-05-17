﻿using FullstackWithFlutter.Core.Models;

namespace FullstackWithFlutter.Core.Interfaces
{
    public interface IUserSettingsRepository : IGenericRepository<UserSettings>
    {
        Task<UserSettings> GetByUserId(int userId);
    }
}
