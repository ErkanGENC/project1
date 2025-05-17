using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.Extensions.Logging;

namespace FullstackWithFlutter.Services
{
    public class UserService : IUserService
    {
        public IUnitofWork _unitofWork;
        private readonly IMapper _mapper;
        private readonly ILogger<UserService> _logger;

        public UserService(IUnitofWork unitofWork, IMapper mapper, ILogger<UserService> logger)
        {
            _unitofWork = unitofWork;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<bool> CreateNewUser(SaveAppUserViewModel userViewModel)
        {
            if (userViewModel != null)
            {
                var newUser = _mapper.Map<AppUser>(userViewModel);
                newUser.CreatedDate = DateTime.Now;
                newUser.CreatedBy = "API";
                await _unitofWork.AppUsers.Add(newUser);
                var result = _unitofWork.Complete();
                if (result > 0)
                    return true;
                else
                    return false;
            }
            return false;
        }

        public async Task<bool> DeleteUser(int userId)
        {
            if (userId > 0)
            {
                var user = await _unitofWork.AppUsers.Get(userId);
                if (user != null)
                {
                    _unitofWork.AppUsers.Delete(user);
                    var result = _unitofWork.Complete();
                    if (result > 0)
                        return true;
                    else
                        return false;
                }
            }
            return false;
        }

        public async Task<Core.ViewModels.ApiResponse> CreateAdminUser(SaveAppUserViewModel adminViewModel)
        {
            try
            {
                _logger.LogInformation("Creating admin user with email: {Email}", adminViewModel.Email);

                // Email kontrolü
                var existingUsers = await _unitofWork.AppUsers.Find(u => u.Email == adminViewModel.Email);
                if (existingUsers.Any())
                {
                    _logger.LogWarning("Admin user creation failed: Email already exists: {Email}", adminViewModel.Email);
                    return new Core.ViewModels.ApiResponse
                    {
                        Status = false,
                        Message = "Bu email adresi zaten kullanılıyor!",
                        Data = null
                    };
                }

                // Yeni admin kullanıcısı oluştur
                var newAdmin = _mapper.Map<AppUser>(adminViewModel);
                newAdmin.CreatedDate = DateTime.Now;
                newAdmin.CreatedBy = "API";
                newAdmin.Role = "admin"; // Admin rolünü belirt

                // Şifreyi hashle (şifre hash fonksiyonunu AuthService'den alıyoruz)
                newAdmin.Password = HashPassword(adminViewModel.Password);

                // Admin kullanıcısını ekle
                await _unitofWork.AppUsers.Add(newAdmin);
                var result = _unitofWork.Complete();

                if (result > 0)
                {
                    _logger.LogInformation("Admin user created successfully: {Email}", adminViewModel.Email);

                    // Admin kullanıcısı bilgilerini döndür
                    var adminUserViewModel = _mapper.Map<AppUserViewModel>(newAdmin);

                    return new Core.ViewModels.ApiResponse
                    {
                        Status = true,
                        Message = "Admin kullanıcısı başarıyla oluşturuldu!",
                        Data = adminUserViewModel
                    };
                }
                else
                {
                    _logger.LogWarning("Admin user creation failed: Database operation failed");
                    return new Core.ViewModels.ApiResponse
                    {
                        Status = false,
                        Message = "Admin kullanıcısı oluşturulurken bir hata oluştu!",
                        Data = null
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating admin user");
                return new Core.ViewModels.ApiResponse
                {
                    Status = false,
                    Message = $"Admin kullanıcısı oluşturulurken bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Şifre hashleme (AuthService'den kopyalandı)
        private string HashPassword(string password)
        {
            if (string.IsNullOrEmpty(password))
                return string.Empty;

            // Basit bir hash algoritması (gerçek uygulamada daha güvenli bir yöntem kullanılmalıdır)
            using (var sha256 = System.Security.Cryptography.SHA256.Create())
            {
                var hashedBytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(password));
                return BitConverter.ToString(hashedBytes).Replace("-", "").ToLower();
            }
        }

        public async Task<List<AppUserViewModel>> GetAllUsers()
        {
            try
            {
                var userList = await _unitofWork.AppUsers.GetAll();
                if (userList == null)
                {
                    return new List<AppUserViewModel>();
                }
                var userListMap = _mapper.Map<List<AppUserViewModel>>(userList);
                return userListMap;
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"Error in GetAllUsers: {ex.Message}");
                throw; // Rethrow to let the controller handle it
            }
        }

        public async Task<AppUserViewModel> GetUserById(int userId)
        {
            if (userId > 0)
            {
                var user = await _unitofWork.AppUsers.Get(userId);
                if (user != null)
                {
                    var userResp = _mapper.Map<AppUserViewModel>(user);
                    return userResp;
                }
            }
            return null;
        }

        public async Task<bool> UpdateUser(int userId, SaveAppUserViewModel userViewModel)
        {
            if (userId > 0)
            {
                var user = await _unitofWork.AppUsers.Get(userId);
                if (user != null)
                {
                    user.FullName = userViewModel.FullName;
                    user.Email = userViewModel.Email;
                    user.MobileNumber = userViewModel.MobileNumber;

                    // Doktor bilgilerini güncelle
                    if (userViewModel.DoctorId.HasValue)
                    {
                        user.DoctorId = userViewModel.DoctorId;
                        user.DoctorName = userViewModel.DoctorName;
                        user.Specialization = userViewModel.Specialization;
                    }

                    user.UpdatedDate = DateTime.Now;
                    user.UpdatedBy = "API";
                    _unitofWork.AppUsers.Update(user);
                    var result = _unitofWork.Complete();
                    if (result > 0)
                        return true;
                    else
                        return false;
                }
            }
            return false;
        }
    }
}
