using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
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

                // JWT token oluştur
                var token = GenerateJwtToken(user);

                return new ApiResponse
                {
                    Status = true,
                    Message = "Giriş başarılı!",
                    Data = new
                    {
                        user = userViewModel,
                        token = token
                    }
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

                // Kullanıcıyı ekle
                await _unitofWork.AppUsers.Add(newUser);
                var result = _unitofWork.Complete();

                if (result > 0)
                {
                    // Kullanıcı başarıyla kaydedildi, şimdi JWT token oluşturalım
                    var token = GenerateJwtToken(newUser);

                    // Kullanıcı bilgilerini döndür
                    var registeredUserViewModel = _mapper.Map<AppUserViewModel>(newUser);

                    // Kullanıcıyı otomatik olarak hasta olarak ekle
                    // Burada kullanıcı zaten AppUser tablosuna eklendiği için
                    // ve AppUser tablosu ile Patient tablosu aynı olduğu için
                    // ek bir işlem yapmaya gerek yok. Kullanıcı zaten hasta olarak kaydedilmiş oluyor.
                    // Eğer ayrı bir Patient tablosu olsaydı, burada ek işlem yapılması gerekirdi.

                    return new ApiResponse
                    {
                        Status = true,
                        Message = "Kayıt başarılı! Kullanıcı otomatik olarak hasta olarak eklendi.",
                        Data = new
                        {
                            user = registeredUserViewModel,
                            token = token
                        }
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

        // JWT Token oluşturma
        private string GenerateJwtToken(AppUser user)
        {
            // Token için güvenlik anahtarı
            var securityKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes("FullstackWithFlutterSecretKey12345678901234567890"));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            // Token içeriğindeki bilgiler (claims)
            var claims = new[]
            {
                new Claim("userId", user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Name, user.FullName ?? ""),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            // Token oluştur
            var token = new JwtSecurityToken(
                issuer: null, // Issuer belirtilmedi
                audience: null, // Audience belirtilmedi
                claims: claims,
                expires: DateTime.Now.AddDays(7), // 7 gün geçerli
                signingCredentials: credentials
            );

            // Token'ı string olarak döndür
            return new JwtSecurityTokenHandler().WriteToken(token);
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
