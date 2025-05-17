﻿using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IDentalTrackingService
    {
        Task<List<DentalTrackingViewModel>> GetAllRecords();
        Task<List<DentalTrackingViewModel>> GetUserRecords(int userId);
        Task<DentalTrackingViewModel?> GetUserRecordByDate(int userId, DateTime date);
        Task<List<DentalTrackingViewModel>> GetUserRecordsForDateRange(int userId, DateTime startDate, DateTime endDate);
        Task<bool> SaveRecord(SaveDentalTrackingViewModel recordViewModel);
        Task<bool> UpdateRecord(int id, SaveDentalTrackingViewModel recordViewModel);
        Task<bool> DeleteRecord(int id);
        Task<DentalTrackingSummaryViewModel> GetUserSummary(int userId);
    }
}
