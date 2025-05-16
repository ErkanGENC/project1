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
                // Yeni doktor oluştur
                var newDoctor = _mapper.Map<Doctor>(doctorViewModel);

                // Şifre varsa hashle
                if (!string.IsNullOrEmpty(doctorViewModel.Password))
                {
                    newDoctor.Password = HashPassword(doctorViewModel.Password);
                }
                else
                {
                    // Varsayılan şifre (gerçek uygulamada rastgele şifre oluşturulup e-posta ile gönderilmelidir)
                    newDoctor.Password = HashPassword("Doctor123");
                }

                newDoctor.CreatedDate = DateTime.Now;
                newDoctor.CreatedBy = "API";
                await _unitOfWork.Doctors.Add(newDoctor);
                var result = _unitOfWork.Complete();

                // Doktor başarıyla oluşturuldu
                if (result > 0)
                {
                    // Eğer AppUsers tablosunda aynı e-posta adresine sahip bir kullanıcı varsa,
                    // bu kullanıcıyı AppUsers tablosundan silelim
                    var existingUsers = await _unitOfWork.AppUsers.Find(u => u.Email == doctorViewModel.Email);
                    var existingUser = existingUsers.FirstOrDefault();

                    if (existingUser != null)
                    {
                        // Kullanıcıyı AppUsers tablosundan sil
                        _unitOfWork.AppUsers.Delete(existingUser);
                        _unitOfWork.Complete();
                    }

                    return true;
                }

                return result > 0;
            }
            return false;
        }

        // Şifre hashleme (AuthService'den kopyalandı)
        private string HashPassword(string password)
        {
            if (string.IsNullOrEmpty(password))
                return string.Empty;

            using (var sha256 = System.Security.Cryptography.SHA256.Create())
            {
                var hashedBytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(hashedBytes);
            }
        }

        public async Task<bool> DeleteDoctor(int doctorId)
        {
            if (doctorId > 0)
            {
                var doctor = await _unitOfWork.Doctors.Get(doctorId);
                if (doctor != null)
                {
                    // Önce AppUser tablosundaki ilişkili kaydı bul
                    var existingUsers = await _unitOfWork.AppUsers.Find(u => u.DoctorId == doctorId || u.Email == doctor.Email);

                    // Tüm ilişkili kullanıcıları sil
                    foreach (var existingUser in existingUsers)
                    {
                        _unitOfWork.AppUsers.Delete(existingUser);
                    }

                    if (existingUsers.Any())
                    {
                        _unitOfWork.Complete();
                    }

                    // Doktoru sil
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

        public async Task<DoctorViewModel> GetDoctorByEmail(string email)
        {
            if (!string.IsNullOrEmpty(email))
            {
                var doctors = await _unitOfWork.Doctors.Find(d => d.Email == email);
                var doctor = doctors.FirstOrDefault();
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
                    // Doktor bilgilerini güncelle
                    doctor.Name = doctorViewModel.Name;
                    doctor.Specialization = doctorViewModel.Specialization;
                    doctor.Email = doctorViewModel.Email;
                    doctor.PhoneNumber = doctorViewModel.PhoneNumber;
                    doctor.IsAvailable = doctorViewModel.IsAvailable;
                    doctor.UpdatedDate = DateTime.Now;
                    doctor.UpdatedBy = "API";
                    _unitOfWork.Doctors.Update(doctor);
                    var result = _unitOfWork.Complete();

                    if (result > 0)
                    {
                        // Doktor başarıyla güncellendi
                        // Eğer AppUsers tablosunda bu doktora ait bir kullanıcı varsa, silelim
                        var existingUsers = await _unitOfWork.AppUsers.Find(u => u.Email == doctor.Email || u.DoctorId == doctorId);

                        foreach (var existingUser in existingUsers)
                        {
                            // Kullanıcıyı AppUsers tablosundan sil
                            _unitOfWork.AppUsers.Delete(existingUser);
                        }

                        if (existingUsers.Any())
                        {
                            _unitOfWork.Complete();
                        }

                        return true;
                    }

                    return result > 0;
                }
            }
            return false;
        }
    }
}
