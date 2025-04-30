using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using System.Security.Cryptography;
using System.Text;

namespace FullstackWithFlutter.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUnitofWork _unitofWork;
        private readonly IMapper _mapper;

        public AuthService(IUnitofWork unitofWork, IMapper mapper)
        {
            _unitofWork = unitofWork;
            _mapper = mapper;
        }

        public async Task<ApiResponse> Login(LoginViewModel loginViewModel)
        {
            try
            {
                // Kullanıcıyı email'e göre bul
                var users = await _unitofWork.AppUsers.Find(u => u.Email == loginViewModel.Email);
                var user = users.FirstOrDefault();

                if (user == null)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Kullanıcı bulunamadı!",
                        Data = null
                    };
                }

                // Şifreyi doğrula
                if (!VerifyPassword(loginViewModel.Password, user.Password))
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Hatalı şifre!",
                        Data = null
                    };
                }

                // Kullanıcı bilgilerini döndür
                var userViewModel = _mapper.Map<AppUserViewModel>(user);

                return new ApiResponse
                {
                    Status = true,
                    Message = "Giriş başarılı!",
                    Data = userViewModel
                };
            }
            catch (Exception ex)
            {
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Giriş sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        public async Task<ApiResponse> Register(SaveAppUserViewModel userViewModel)
        {
            try
            {
                // Email kontrolü
                var existingUsers = await _unitofWork.AppUsers.Find(u => u.Email == userViewModel.Email);
                if (existingUsers.Any())
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Bu email adresi zaten kullanılıyor!",
                        Data = null
                    };
                }

                // Yeni kullanıcı oluştur
                var newUser = _mapper.Map<AppUser>(userViewModel);
                newUser.CreatedDate = DateTime.Now;
                newUser.CreatedBy = "API";

                // Şifreyi hashle
                newUser.Password = HashPassword(userViewModel.Password);

                await _unitofWork.AppUsers.Add(newUser);
                var result = _unitofWork.Complete();

                if (result > 0)
                {
                    return new ApiResponse
                    {
                        Status = true,
                        Message = "Kayıt başarılı!",
                        Data = null
                    };
                }
                else
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Kayıt sırasında bir hata oluştu!",
                        Data = null
                    };
                }
            }
            catch (Exception ex)
            {
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Kayıt sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Şifre hashleme
        private string HashPassword(string password)
        {
            if (string.IsNullOrEmpty(password))
                return string.Empty;

            using (var sha256 = SHA256.Create())
            {
                var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(hashedBytes);
            }
        }

        // Şifre doğrulama
        private bool VerifyPassword(string password, string hashedPassword)
        {
            if (string.IsNullOrEmpty(password) || string.IsNullOrEmpty(hashedPassword))
                return false;

            var hashedInput = HashPassword(password);
            return hashedInput == hashedPassword;
        }
    }
}
