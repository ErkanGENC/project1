﻿using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using Microsoft.EntityFrameworkCore;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class UserSettingsRepository : GenericRepository<UserSettings>, IUserSettingsRepository
    {
        public UserSettingsRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<UserSettings> GetByUserId(int userId)
        {
            return await _context.userSettings
                .Where(s => s.UserId == userId)
                .FirstOrDefaultAsync();
        }
    }
}
