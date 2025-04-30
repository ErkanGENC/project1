﻿using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IReportService
    {
        Task<ReportViewModel> GetReportData();
    }
}
