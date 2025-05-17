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
        private readonly IEmailService _emailService;
        private readonly ILogger<AuthService> _logger;
        private readonly IActivityService _activityService;

        public AuthService(IUnitofWork unitofWork, IMapper mapper, IEmailService emailService, ILogger<AuthService> logger, IActivityService activityService)
        {
            _unitofWork = unitofWork;
            _mapper = mapper;
            _emailService = emailService;
            _logger = logger;
            _activityService = activityService;
        }

        public async Task<ApiResponse> Login(LoginViewModel loginViewModel)
        {
            try
            {
                // Önce Doctors tablosunda ara (doktor kullanıcıları için)
                var doctors = await _unitofWork.Doctors.Find(d => d.Email == loginViewModel.Email);
                var doctor = doctors.FirstOrDefault();

                if (doctor != null)
                {
                    // Doktor için şifre kontrolü
                    if (!string.IsNullOrEmpty(doctor.Password) && !VerifyPassword(loginViewModel.Password, doctor.Password))
                    {
                        return new ApiResponse
                        {
                            Status = false,
                            Message = "Hatalı şifre!",
                            Data = null
                        };
                    }

                    // Doktor için geçici bir AppUser nesnesi oluştur (sadece token oluşturmak için)
                    var doctorUser = new AppUser
                    {
                        Id = doctor.Id,
                        FullName = doctor.Name,
                        Email = doctor.Email,
                        MobileNumber = doctor.PhoneNumber,
                        Role = "doctor", // Doktor rolünü belirt
                        DoctorId = doctor.Id,
                        DoctorName = doctor.Name,
                        Specialization = doctor.Specialization,
                        CreatedDate = doctor.CreatedDate,
                        CreatedBy = doctor.CreatedBy,
                        UpdatedDate = doctor.UpdatedDate,
                        UpdatedBy = doctor.UpdatedBy
                    };

                    // Doktor bilgilerini döndür
                    var doctorViewModel = _mapper.Map<AppUserViewModel>(doctorUser);

                    // JWT token oluştur
                    var token = GenerateJwtToken(doctorUser);

                    // Aktivite kaydı
                    await _activityService.LogDoctorActivity(
                        type: "DoctorLogin",
                        description: $"{doctor.Name} doktoru giriş yaptı",
                        userId: doctor.Id,
                        userName: doctor.Name,
                        doctorId: doctor.Id
                    );

                    return new ApiResponse
                    {
                        Status = true,
                        Message = "Doktor girişi başarılı!",
                        Data = new
                        {
                            user = doctorViewModel,
                            token = token
                        }
                    };
                }
                else
                {
                    // Doctors tablosunda bulunamadıysa, AppUsers tablosunda ara (normal kullanıcılar için)
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

                    // Aktivite kaydı
                    await _activityService.LogUserActivity(
                        type: "UserLogin",
                        description: $"{user.FullName} kullanıcısı giriş yaptı",
                        userId: user.Id,
                        userName: user.FullName
                    );

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

                // Doğum tarihi kontrolü
                if (userViewModel.BirthDate.HasValue)
                {
                    newUser.BirthDate = userViewModel.BirthDate;
                }

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

                    // Aktivite kaydı
                    await _activityService.LogUserActivity(
                        type: "UserRegistration",
                        description: $"Yeni kullanıcı kaydı: {newUser.FullName}",
                        userId: newUser.Id,
                        userName: newUser.FullName
                    );

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
            var claims = new List<Claim>
            {
                new Claim("userId", user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim("email", user.Email ?? ""),
                new Claim(ClaimTypes.Name, user.FullName ?? ""),
                new Claim("name", user.FullName ?? ""),
                new Claim("fullName", user.FullName ?? ""),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            // Rol bilgisini ekle
            if (!string.IsNullOrEmpty(user.Role))
            {
                claims.Add(new Claim(ClaimTypes.Role, user.Role));
                claims.Add(new Claim("role", user.Role));
            }

            // Doktor ID'si varsa ekle
            if (user.DoctorId.HasValue)
            {
                claims.Add(new Claim("doctorId", user.DoctorId.Value.ToString()));
            }

            // Doktor adı ve uzmanlık alanı varsa ekle
            if (!string.IsNullOrEmpty(user.DoctorName))
            {
                claims.Add(new Claim("doctorName", user.DoctorName));
            }

            if (!string.IsNullOrEmpty(user.Specialization))
            {
                claims.Add(new Claim("specialization", user.Specialization));
            }

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

        // Şifre değiştirme
        public async Task<ApiResponse> ChangePassword(int userId, string currentPassword, string newPassword)
        {
            try
            {
                // Kullanıcıyı ID'ye göre bul
                var user = await _unitofWork.AppUsers.Get(userId);
                if (user == null)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Kullanıcı bulunamadı!",
                        Data = null
                    };
                }

                // Mevcut şifreyi doğrula
                if (!VerifyPassword(currentPassword, user.Password))
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Mevcut şifre hatalı!",
                        Data = null
                    };
                }

                // Yeni şifreyi hashle ve kaydet
                user.Password = HashPassword(newPassword);
                user.UpdatedDate = DateTime.Now;
                user.UpdatedBy = "API";

                // Değişiklikleri kaydet
                var result = _unitofWork.Complete();

                if (result > 0)
                {
                    return new ApiResponse
                    {
                        Status = true,
                        Message = "Şifre başarıyla değiştirildi!",
                        Data = null
                    };
                }
                else
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Şifre değiştirilemedi!",
                        Data = null
                    };
                }
            }
            catch (Exception ex)
            {
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Şifre değiştirme sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Şifre sıfırlama isteği
        public async Task<ApiResponse> ForgotPassword(string email)
        {
            try
            {
                // Kullanıcıyı email'e göre bul
                var users = await _unitofWork.AppUsers.Find(u => u.Email == email);
                var user = users.FirstOrDefault();

                if (user == null)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Bu email adresine sahip kullanıcı bulunamadı!",
                        Data = null
                    };
                }

                // Kullanıcı bulundu, başarılı yanıt döndür
                return new ApiResponse
                {
                    Status = true,
                    Message = "Kullanıcı bulundu. Şifre sıfırlama işlemi için yeni şifre belirleyebilirsiniz.",
                    Data = new
                    {
                        email = user.Email,
                        userId = user.Id
                    }
                };
            }
            catch (Exception ex)
            {
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Şifre sıfırlama isteği sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Şifre sıfırlama (yeni şifre ile) - Eski metod, uyumluluk için korundu
        public async Task<ApiResponse> ResetPassword(string email, string newPassword)
        {
            try
            {
                // Kullanıcıyı email'e göre bul
                var users = await _unitofWork.AppUsers.Find(u => u.Email == email);
                var user = users.FirstOrDefault();

                if (user == null)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Bu email adresine sahip kullanıcı bulunamadı!",
                        Data = null
                    };
                }

                // Yeni şifreyi hashle ve kaydet
                user.Password = HashPassword(newPassword);
                user.UpdatedDate = DateTime.Now;
                user.UpdatedBy = "API";

                // Değişiklikleri kaydet
                var result = _unitofWork.Complete();

                if (result > 0)
                {
                    return new ApiResponse
                    {
                        Status = true,
                        Message = "Şifre başarıyla sıfırlandı!",
                        Data = null
                    };
                }
                else
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Şifre sıfırlanamadı!",
                        Data = null
                    };
                }
            }
            catch (Exception ex)
            {
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Şifre sıfırlama sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Şifre sıfırlama e-postası gönder
        public async Task<ApiResponse> SendPasswordResetEmail(string email)
        {
            try
            {
                // Kullanıcıyı email'e göre bul
                var users = await _unitofWork.AppUsers.Find(u => u.Email == email);
                var user = users.FirstOrDefault();

                if (user == null)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Bu email adresine sahip kullanıcı bulunamadı!",
                        Data = null
                    };
                }

                // Rastgele 6 haneli kod oluştur
                var resetCode = GenerateRandomCode(6);

                // Mevcut aktif token'ı kontrol et
                var existingToken = await _unitofWork.PasswordResetTokens.GetValidTokenByEmail(email);
                if (existingToken != null)
                {
                    // Mevcut token'ı kullanılmış olarak işaretle
                    existingToken.IsUsed = true;
                    _unitofWork.PasswordResetTokens.Update(existingToken);
                }

                // Yeni token oluştur
                var token = new PasswordResetToken
                {
                    Email = email,
                    Token = resetCode,
                    ExpiryDate = DateTime.Now.AddHours(1), // 1 saat geçerli
                    IsUsed = false,
                    CreatedDate = DateTime.Now
                };

                // Token'ı kaydet
                await _unitofWork.PasswordResetTokens.Add(token);
                var result = _unitofWork.Complete();

                if (result <= 0)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Şifre sıfırlama kodu oluşturulamadı!",
                        Data = null
                    };
                }

                // E-posta gönder
                var subject = "Şifre Sıfırlama Kodu";
                var body = $@"
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .header {{ background-color: #4CAF50; color: white; padding: 10px; text-align: center; }}
                        .content {{ padding: 20px; border: 1px solid #ddd; }}
                        .code {{ font-size: 24px; font-weight: bold; text-align: center; margin: 20px 0; color: #4CAF50; }}
                        .footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #777; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h2>Şifre Sıfırlama</h2>
                        </div>
                        <div class='content'>
                            <p>Merhaba {user.FullName},</p>
                            <p>Şifre sıfırlama talebiniz için onay kodunuz aşağıdadır:</p>
                            <div class='code'>{resetCode}</div>
                            <p>Bu kod 1 saat boyunca geçerlidir. Eğer bu talebi siz yapmadıysanız, lütfen bu e-postayı dikkate almayınız.</p>
                        </div>
                        <div class='footer'>
                            <p>Bu e-posta otomatik olarak gönderilmiştir, lütfen yanıtlamayınız.</p>
                        </div>
                    </div>
                </body>
                </html>";

                try
                {
                    _logger.LogInformation($"E-posta gönderiliyor: To={email}, ResetCode={resetCode}");
                    await _emailService.SendEmailAsync(email, subject, body);
                    _logger.LogInformation($"E-posta gönderildi: To={email}");

                    // Geliştirme ortamında, konsola doğrulama kodunu yazdır
                    _logger.LogWarning($"DOĞRULAMA KODU: {resetCode} (Bu sadece geliştirme ortamında görünür)");
                }
                catch (System.Net.Mail.SmtpException smtpEx)
                {
                    _logger.LogError($"SMTP hatası ile e-posta gönderimi başarısız: {smtpEx.Message}, Status: {smtpEx.StatusCode}");
                    if (smtpEx.InnerException != null)
                    {
                        _logger.LogError($"SMTP iç hata: {smtpEx.InnerException.Message}");
                    }

                    // Hatayı kullanıcıya bildir
                    return new ApiResponse
                    {
                        Status = false,
                        Message = $"E-posta gönderimi başarısız oldu. Lütfen daha sonra tekrar deneyin.",
                        Data = null
                    };
                }
                catch (Exception ex)
                {
                    _logger.LogError($"E-posta gönderimi sırasında hata: {ex.Message}");

                    // Hatayı kullanıcıya bildir
                    return new ApiResponse
                    {
                        Status = false,
                        Message = $"E-posta gönderimi sırasında bir hata oluştu. Lütfen daha sonra tekrar deneyin.",
                        Data = null
                    };
                }

                return new ApiResponse
                {
                    Status = true,
                    Message = "Şifre sıfırlama kodu e-posta adresinize gönderildi. Lütfen e-postanızı kontrol ediniz.",
                    Data = null
                };
            }
            catch (Exception ex)
            {
                _logger.LogError($"Şifre sıfırlama e-postası gönderimi sırasında hata: {ex.Message}");
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Şifre sıfırlama e-postası gönderimi sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Şifre sıfırlama kodunu doğrula
        public async Task<ApiResponse> VerifyResetCode(string email, string resetCode)
        {
            try
            {
                // Token'ı kontrol et
                var token = await _unitofWork.PasswordResetTokens.GetTokenByEmailAndCode(email, resetCode);

                if (token == null)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Geçersiz veya süresi dolmuş kod!",
                        Data = null
                    };
                }

                return new ApiResponse
                {
                    Status = true,
                    Message = "Kod doğrulandı. Şimdi yeni şifrenizi belirleyebilirsiniz.",
                    Data = null
                };
            }
            catch (Exception ex)
            {
                _logger.LogError($"Kod doğrulama sırasında hata: {ex.Message}");
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Kod doğrulama sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Token ile şifre sıfırlama
        public async Task<ApiResponse> ResetPasswordWithToken(string email, string resetCode, string newPassword)
        {
            try
            {
                // Token'ı kontrol et
                var token = await _unitofWork.PasswordResetTokens.GetTokenByEmailAndCode(email, resetCode);

                if (token == null)
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Geçersiz veya süresi dolmuş kod!",
                        Data = null
                    };
                }

                // Kullanıcıyı bul
                var users = await _unitofWork.AppUsers.Find(u => u.Email == email);
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

                // Şifreyi güncelle
                user.Password = HashPassword(newPassword);
                user.UpdatedDate = DateTime.Now;
                user.UpdatedBy = "API";

                // Token'ı kullanılmış olarak işaretle
                token.IsUsed = true;
                _unitofWork.PasswordResetTokens.Update(token);

                // Değişiklikleri kaydet
                var result = _unitofWork.Complete();

                if (result > 0)
                {
                    return new ApiResponse
                    {
                        Status = true,
                        Message = "Şifre başarıyla sıfırlandı!",
                        Data = null
                    };
                }
                else
                {
                    return new ApiResponse
                    {
                        Status = false,
                        Message = "Şifre sıfırlanamadı!",
                        Data = null
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Token ile şifre sıfırlama sırasında hata: {ex.Message}");
                return new ApiResponse
                {
                    Status = false,
                    Message = $"Şifre sıfırlama sırasında bir hata oluştu: {ex.Message}",
                    Data = null
                };
            }
        }

        // Rastgele kod oluşturma
        private string GenerateRandomCode(int length)
        {
            const string chars = "0123456789";
            var random = new Random();
            return new string(Enumerable.Repeat(chars, length)
                .Select(s => s[random.Next(s.Length)]).ToArray());
        }

        // Rol bazlı kullanıcı sorgulama
        public async Task<List<AppUserViewModel>> GetUsersByRole(string role)
        {
            try
            {
                // Belirli role sahip kullanıcıları bul
                var users = await _unitofWork.AppUsers.Find(u => u.Role == role);

                // Kullanıcıları ViewModel'e dönüştür
                var userViewModels = _mapper.Map<List<AppUserViewModel>>(users);

                return userViewModels;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting users by role: {Role}", role);
                return new List<AppUserViewModel>();
            }
        }
    }
}
