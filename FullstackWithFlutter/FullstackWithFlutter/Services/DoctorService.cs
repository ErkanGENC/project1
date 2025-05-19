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
        private readonly ILogger<DoctorService> _logger;

        public DoctorService(IUnitofWork unitOfWork, IMapper mapper, ILogger<DoctorService> logger)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
            _logger = logger;
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

                // Doktor rolünü ayarla
                newDoctor.Role = "doctor";

                newDoctor.CreatedDate = DateTime.Now;
                newDoctor.CreatedBy = "API";
                await _unitOfWork.Doctors.Add(newDoctor);
                var result = _unitOfWork.Complete();

                // Doktor başarıyla oluşturuldu
                if (result > 0)
                {
                    // NOT: Doktor kullanıcıları sadece Doctors tablosunda tutulmalı,
                    // AppUsers tablosundan silme işlemi kaldırıldı.
                    // Böylece doktor kullanıcıları doğru şekilde tanımlanabilir.

                    _logger.LogInformation($"Doktor başarıyla oluşturuldu: {doctorViewModel.Name}, ID: {newDoctor.Id}");
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
                    // Önce AppUser tablosundaki ilişkili kaydı bul (sadece email ile)
                    var existingUsers = await _unitOfWork.AppUsers.Find(u => u.Email == doctor.Email);

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

                    // Doktor rolünü kontrol et ve ayarla
                    if (string.IsNullOrEmpty(doctor.Role))
                    {
                        doctor.Role = "doctor";
                    }

                    doctor.UpdatedDate = DateTime.Now;
                    doctor.UpdatedBy = "API";
                    _unitOfWork.Doctors.Update(doctor);
                    var result = _unitOfWork.Complete();

                    if (result > 0)
                    {
                        // Doktor başarıyla güncellendi
                        // Eğer AppUsers tablosunda bu doktora ait bir kullanıcı varsa, silelim (sadece email ile)
                        var existingUsers = await _unitOfWork.AppUsers.Find(u => u.Email == doctor.Email);

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

        /// <summary>
        /// AppUsers tablosundaki tüm doktor kullanıcılarını temizler.
        /// Bu metod, doktor kullanıcılarının sadece doctors tablosunda tutulmasını sağlar.
        /// </summary>
        /// <returns>Temizlenen kullanıcı sayısı</returns>
        // Tüm doktorların Role alanını güncelleme
        public async Task<int> UpdateAllDoctorRoles()
        {
            try
            {
                _logger.LogInformation("Tüm doktorların Role alanı güncelleniyor...");

                // Tüm doktorları al
                var doctors = await _unitOfWork.Doctors.GetAll();
                if (doctors == null || !doctors.Any())
                {
                    _logger.LogInformation("Güncellenecek doktor bulunamadı.");
                    return 0;
                }

                int updatedCount = 0;

                // Her doktorun Role alanını kontrol et ve güncelle
                foreach (var doctor in doctors)
                {
                    if (string.IsNullOrEmpty(doctor.Role))
                    {
                        doctor.Role = "doctor";
                        _unitOfWork.Doctors.Update(doctor);
                        updatedCount++;
                    }
                }

                if (updatedCount > 0)
                {
                    _unitOfWork.Complete();
                    _logger.LogInformation($"{updatedCount} doktorun Role alanı güncellendi.");
                }
                else
                {
                    _logger.LogInformation("Güncellenecek doktor bulunamadı.");
                }

                return updatedCount;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Doktor rollerini güncelleme sırasında bir hata oluştu.");
                return -1;
            }
        }

        public async Task<int> CleanupDoctorUsersFromAppUsers()
        {
            try
            {
                _logger.LogInformation("Doktor kullanıcılarını AppUsers tablosundan temizleme işlemi başlatılıyor...");

                // Tüm doktorları al
                var doctors = await _unitOfWork.Doctors.GetAll();
                if (doctors == null || !doctors.Any())
                {
                    _logger.LogInformation("Temizlenecek doktor bulunamadı.");
                    return 0;
                }

                // Doktor e-posta adreslerini topla
                var doctorEmails = doctors.Select(d => d.Email).ToList();

                // AppUsers tablosunda bu e-posta adreslerine sahip kullanıcıları bul
                var usersToDelete = new List<AppUser>();
                foreach (var email in doctorEmails)
                {
                    if (!string.IsNullOrEmpty(email))
                    {
                        var users = await _unitOfWork.AppUsers.Find(u => u.Email == email);
                        usersToDelete.AddRange(users);
                    }
                }

                // Not: DoctorId alanı artık AppUser modelinde bulunmuyor
                // Bu nedenle sadece email ile eşleşen kullanıcıları siliyoruz

                // Tekrarlanan kullanıcıları kaldır
                usersToDelete = usersToDelete.Distinct().ToList();

                if (!usersToDelete.Any())
                {
                    _logger.LogInformation("AppUsers tablosunda temizlenecek doktor kullanıcısı bulunamadı.");
                    return 0;
                }

                _logger.LogInformation($"AppUsers tablosundan {usersToDelete.Count} doktor kullanıcısı temizlenecek.");

                // Kullanıcıları sil
                foreach (var user in usersToDelete)
                {
                    _unitOfWork.AppUsers.Delete(user);
                }

                // Değişiklikleri kaydet
                var result = _unitOfWork.Complete();

                _logger.LogInformation($"Temizleme işlemi tamamlandı. {result} kayıt silindi.");
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Doktor kullanıcılarını temizleme sırasında bir hata oluştu.");
                return -1;
            }
        }
    }
}
