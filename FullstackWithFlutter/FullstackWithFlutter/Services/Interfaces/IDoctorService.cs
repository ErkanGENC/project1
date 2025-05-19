﻿using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IDoctorService
    {
        Task<bool> CreateDoctor(SaveDoctorViewModel doctorViewModel);
        Task<List<DoctorViewModel>> GetAllDoctors();
        Task<DoctorViewModel> GetDoctorById(int doctorId);
        Task<DoctorViewModel> GetDoctorByEmail(string email);
        Task<bool> UpdateDoctor(int doctorId, SaveDoctorViewModel doctorViewModel);
        Task<bool> DeleteDoctor(int doctorId);
        Task<int> CleanupDoctorUsersFromAppUsers();
        Task<int> UpdateAllDoctorRoles();
    }
}
