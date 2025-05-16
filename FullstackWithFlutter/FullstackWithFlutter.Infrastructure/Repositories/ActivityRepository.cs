﻿using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using Microsoft.EntityFrameworkCore;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class ActivityRepository : GenericRepository<Activity>, IActivityRepository
    {
        public ActivityRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<IEnumerable<Activity>> GetRecentActivities(int count)
        {
            return await _context.activities
                .OrderByDescending(a => a.CreatedDate)
                .Take(count)
                .ToListAsync();
        }
    }
}
