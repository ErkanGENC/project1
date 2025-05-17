﻿using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using Microsoft.EntityFrameworkCore;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class DentalTrackingRepository : GenericRepository<DentalTracking>, IDentalTrackingRepository
    {
        public DentalTrackingRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<IEnumerable<DentalTracking>> GetByUserId(int userId)
        {
            return await _context.dentalTrackings
                .Where(dt => dt.UserId == userId)
                .OrderByDescending(dt => dt.Date)
                .ToListAsync();
        }

        public async Task<DentalTracking?> GetByUserIdAndDate(int userId, DateTime date)
        {
            return await _context.dentalTrackings
                .Where(dt => dt.UserId == userId && dt.Date.Date == date.Date)
                .FirstOrDefaultAsync();
        }

        public async Task<IEnumerable<DentalTracking>> GetUserRecordsForDateRange(int userId, DateTime startDate, DateTime endDate)
        {
            return await _context.dentalTrackings
                .Where(dt => dt.UserId == userId && dt.Date.Date >= startDate.Date && dt.Date.Date <= endDate.Date)
                .OrderBy(dt => dt.Date)
                .ToListAsync();
        }
    }
}
