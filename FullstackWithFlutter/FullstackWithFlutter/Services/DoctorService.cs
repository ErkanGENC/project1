﻿using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;

namespace FullstackWithFlutter.Services
{
    public class DoctorService : IDoctorService
    {
        private readonly IUnitofWork _unitOfWork;
        private readonly IMapper _mapper;

        public DoctorService(IUnitofWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<bool> CreateDoctor(SaveDoctorViewModel doctorViewModel)
        {
            if (doctorViewModel != null)
            {
                var newDoctor = _mapper.Map<Doctor>(doctorViewModel);
                newDoctor.CreatedDate = DateTime.Now;
                newDoctor.CreatedBy = "API";
                await _unitOfWork.Doctors.Add(newDoctor);
                var result = _unitOfWork.Complete();
                return result > 0;
            }
            return false;
        }

        public async Task<bool> DeleteDoctor(int doctorId)
        {
            if (doctorId > 0)
            {
                var doctor = await _unitOfWork.Doctors.Get(doctorId);
                if (doctor != null)
                {
                    _unitOfWork.Doctors.Delete(doctor);
                    var result = _unitOfWork.Complete();
                    return result > 0;
                }
            }
            return false;
        }

        public async Task<List<DoctorViewModel>> GetAllDoctors()
        {
            try
            {
                var doctorList = await _unitOfWork.Doctors.GetAll();
                if (doctorList == null)
                {
                    return new List<DoctorViewModel>();
                }
                var doctorListMap = _mapper.Map<List<DoctorViewModel>>(doctorList);
                return doctorListMap;
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"Error in GetAllDoctors: {ex.Message}");
                throw; // Rethrow to let the controller handle it
            }
        }

        public async Task<DoctorViewModel> GetDoctorById(int doctorId)
        {
            if (doctorId > 0)
            {
                var doctor = await _unitOfWork.Doctors.Get(doctorId);
                if (doctor != null)
                {
                    var doctorResp = _mapper.Map<DoctorViewModel>(doctor);
                    return doctorResp;
                }
            }
            return null;
        }

        public async Task<bool> UpdateDoctor(int doctorId, SaveDoctorViewModel doctorViewModel)
        {
            if (doctorId > 0)
            {
                var doctor = await _unitOfWork.Doctors.Get(doctorId);
                if (doctor != null)
                {
                    doctor.Name = doctorViewModel.Name;
                    doctor.Specialization = doctorViewModel.Specialization;
                    doctor.Email = doctorViewModel.Email;
                    doctor.PhoneNumber = doctorViewModel.PhoneNumber;
                    doctor.IsAvailable = doctorViewModel.IsAvailable;
                    doctor.UpdatedDate = DateTime.Now;
                    doctor.UpdatedBy = "API";
                    _unitOfWork.Doctors.Update(doctor);
                    var result = _unitOfWork.Complete();
                    return result > 0;
                }
            }
            return false;
        }
    }
}
