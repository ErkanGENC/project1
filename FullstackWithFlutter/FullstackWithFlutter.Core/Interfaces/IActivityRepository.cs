﻿using FullstackWithFlutter.Core.Models;

namespace FullstackWithFlutter.Core.Interfaces
{
    public interface IActivityRepository : IGenericRepository<Activity>
    {
        Task<IEnumerable<Activity>> GetRecentActivities(int count);
    }
}
