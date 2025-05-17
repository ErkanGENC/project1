﻿using FullstackWithFlutter.Core.Models;

namespace FullstackWithFlutter.Core.Interfaces
{
    public interface IDentalTrackingRepository : IGenericRepository<DentalTracking>
    {
        Task<IEnumerable<DentalTracking>> GetByUserId(int userId);
        Task<DentalTracking?> GetByUserIdAndDate(int userId, DateTime date);
        Task<IEnumerable<DentalTracking>> GetUserRecordsForDateRange(int userId, DateTime startDate, DateTime endDate);
    }
}
