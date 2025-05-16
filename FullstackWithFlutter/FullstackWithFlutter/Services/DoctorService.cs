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
                newDoctor.CreatedDate = DateTime.Now;
                newDoctor.CreatedBy = "API";
                await _unitOfWork.Doctors.Add(newDoctor);
                var result = _unitOfWork.Complete();

                if (result > 0)
                {
                    // Doktor başarıyla oluşturuldu, şimdi AppUser tablosunda da bir kayıt oluşturalım
                    // veya mevcut kaydı güncelleyelim

                    // Önce e-posta adresine göre kullanıcıyı kontrol et
                    var existingUsers = await _unitOfWork.AppUsers.Find(u => u.Email == doctorViewModel.Email);
                    var existingUser = existingUsers.FirstOrDefault();

                    if (existingUser != null)
                    {
                        // Kullanıcı zaten var, doktor bilgilerini güncelle
                        existingUser.Role = "doctor";
                        existingUser.DoctorId = newDoctor.Id; // Yeni oluşturulan doktorun ID'si
                        existingUser.DoctorName = newDoctor.Name;
                        existingUser.Specialization = newDoctor.Specialization;
                        existingUser.UpdatedDate = DateTime.Now;
                        existingUser.UpdatedBy = "API";

                        _unitOfWork.AppUsers.Update(existingUser);
                    }
                    else
                    {
                        // Kullanıcı yok, yeni bir kullanıcı oluştur
                        var newUser = new Core.Models.AppUser
                        {
                            FullName = newDoctor.Name,
                            Email = newDoctor.Email,
                            MobileNumber = newDoctor.PhoneNumber,
                            Role = "doctor",
                            DoctorId = newDoctor.Id,
                            DoctorName = newDoctor.Name,
                            Specialization = newDoctor.Specialization,
                            CreatedDate = DateTime.Now,
                            CreatedBy = "API",
                            // Varsayılan şifre (gerçek uygulamada rastgele şifre oluşturulup e-posta ile gönderilmelidir)
                            Password = HashPassword("Doctor123")
                        };

                        await _unitOfWork.AppUsers.Add(newUser);
                    }

                    // Değişiklikleri kaydet
                    var userResult = _unitOfWork.Complete();
                    return userResult > 0;
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
                    var existingUsers = await _unitOfWork.AppUsers.Find(u => u.DoctorId == doctorId);
                    var existingUser = existingUsers.FirstOrDefault();

                    if (existingUser != null)
                    {
                        // Kullanıcıyı silmek yerine, doktor bilgilerini temizle ve rolü "user" olarak güncelle
                        existingUser.Role = "user";
                        existingUser.DoctorId = null;
                        existingUser.DoctorName = null;
                        existingUser.Specialization = null;
                        existingUser.UpdatedDate = DateTime.Now;
                        existingUser.UpdatedBy = "API";

                        _unitOfWork.AppUsers.Update(existingUser);
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
                        // Doktor başarıyla güncellendi, şimdi AppUser tablosundaki kaydı da güncelleyelim

                        // DoctorId'ye göre kullanıcıyı bul
                        var existingUsers = await _unitOfWork.AppUsers.Find(u => u.DoctorId == doctorId);
                        var existingUser = existingUsers.FirstOrDefault();

                        if (existingUser != null)
                        {
                            // Kullanıcı bulundu, bilgilerini güncelle
                            existingUser.FullName = doctor.Name;
                            existingUser.Email = doctor.Email;
                            existingUser.MobileNumber = doctor.PhoneNumber;
                            existingUser.DoctorName = doctor.Name;
                            existingUser.Specialization = doctor.Specialization;
                            existingUser.UpdatedDate = DateTime.Now;
                            existingUser.UpdatedBy = "API";

                            _unitOfWork.AppUsers.Update(existingUser);
                            var userResult = _unitOfWork.Complete();
                            return userResult > 0;
                        }
                        else
                        {
                            // Kullanıcı bulunamadı, e-posta adresine göre ara
                            var usersByEmail = await _unitOfWork.AppUsers.Find(u => u.Email == doctor.Email);
                            var userByEmail = usersByEmail.FirstOrDefault();

                            if (userByEmail != null)
                            {
                                // E-posta adresine göre kullanıcı bulundu, doktor bilgilerini güncelle
                                userByEmail.Role = "doctor";
                                userByEmail.DoctorId = doctorId;
                                userByEmail.DoctorName = doctor.Name;
                                userByEmail.Specialization = doctor.Specialization;
                                userByEmail.UpdatedDate = DateTime.Now;
                                userByEmail.UpdatedBy = "API";

                                _unitOfWork.AppUsers.Update(userByEmail);
                                var userResult = _unitOfWork.Complete();
                                return userResult > 0;
                            }
                            else
                            {
                                // Kullanıcı yok, yeni bir kullanıcı oluştur
                                var newUser = new Core.Models.AppUser
                                {
                                    FullName = doctor.Name,
                                    Email = doctor.Email,
                                    MobileNumber = doctor.PhoneNumber,
                                    Role = "doctor",
                                    DoctorId = doctorId,
                                    DoctorName = doctor.Name,
                                    Specialization = doctor.Specialization,
                                    CreatedDate = DateTime.Now,
                                    CreatedBy = "API",
                                    // Varsayılan şifre
                                    Password = HashPassword("Doctor123")
                                };

                                await _unitOfWork.AppUsers.Add(newUser);
                                var userResult = _unitOfWork.Complete();
                                return userResult > 0;
                            }
                        }
                    }

                    return result > 0;
                }
            }
            return false;
        }
    }
}
