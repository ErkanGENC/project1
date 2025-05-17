using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/Auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        [HttpPost("Register")]
        public async Task<IActionResult> Register(SaveAppUserViewModel userViewModel)
        {
            if (userViewModel == null || string.IsNullOrEmpty(userViewModel.Email) || string.IsNullOrEmpty(userViewModel.Password))
            {
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Email ve şifre gereklidir!",
                    Data = null
                });
            }

            var result = await _authService.Register(userViewModel);
            if (result.Status)
            {
                return Ok(result);
            }
            else
            {
                return BadRequest(result);
            }
        }

        [HttpPost("Login")]
        public async Task<IActionResult> Login(LoginViewModel loginViewModel)
        {
            if (loginViewModel == null || string.IsNullOrEmpty(loginViewModel.Email) || string.IsNullOrEmpty(loginViewModel.Password))
            {
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Email ve şifre gereklidir!",
                    Data = null
                });
            }

            var result = await _authService.Login(loginViewModel);
            if (result.Status)
            {
                return Ok(result);
            }
            else
            {
                return BadRequest(result);
            }
        }

        [HttpPost("ChangePassword")]
        [Authorize] // Kullanıcının oturum açmış olması gerekiyor
        public async Task<IActionResult> ChangePassword(ChangePasswordViewModel model)
        {
            try
            {
                _logger.LogInformation("ChangePassword endpoint called");

                if (model == null || string.IsNullOrEmpty(model.CurrentPassword) || string.IsNullOrEmpty(model.NewPassword))
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Mevcut şifre ve yeni şifre gereklidir!",
                        Data = null
                    });
                }

                // Token'dan kullanıcı ID'sini al
                var userIdClaim = User.FindFirst("userId");
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    return Unauthorized(new ApiResponse
                    {
                        Status = false,
                        Message = "Kullanıcı kimliği doğrulanamadı!",
                        Data = null
                    });
                }

                var result = await _authService.ChangePassword(userId, model.CurrentPassword, model.NewPassword);
                if (result.Status)
                {
                    return Ok(result);
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing password");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Şifre değiştirme sırasında bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // Kullanıcı ID'sini token'dan al
        private int GetUserIdFromToken()
        {
            var userIdClaim = User.FindFirst("userId");
            if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
            {
                return userId;
            }
            return 0;
        }

        // Eski ForgotPassword metodu, uyumluluk için korundu
        [HttpPost("ForgotPassword")]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordViewModel model)
        {
            try
            {
                _logger.LogInformation("ForgotPassword endpoint called");

                if (model == null || string.IsNullOrEmpty(model.Email))
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Email adresi gereklidir!",
                        Data = null
                    });
                }

                var result = await _authService.ForgotPassword(model.Email);
                if (result.Status)
                {
                    return Ok(result);
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in forgot password");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Şifre sıfırlama isteği sırasında bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // Eski ResetPassword metodu, uyumluluk için korundu
        [HttpPost("ResetPassword")]
        public async Task<IActionResult> ResetPassword(ResetPasswordViewModel model)
        {
            try
            {
                _logger.LogInformation("ResetPassword endpoint called");

                if (model == null || string.IsNullOrEmpty(model.Email) || string.IsNullOrEmpty(model.NewPassword))
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Email ve yeni şifre gereklidir!",
                        Data = null
                    });
                }

                var result = await _authService.ResetPassword(model.Email, model.NewPassword);
                if (result.Status)
                {
                    return Ok(result);
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resetting password");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Şifre sıfırlama sırasında bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // Yeni şifre sıfırlama e-postası gönderme metodu
        [HttpPost("SendPasswordResetEmail")]
        public async Task<IActionResult> SendPasswordResetEmail(SendPasswordResetEmailViewModel model)
        {
            try
            {
                _logger.LogInformation("SendPasswordResetEmail endpoint called for email: {Email}", model?.Email ?? "null");

                if (model == null || string.IsNullOrEmpty(model.Email))
                {
                    _logger.LogWarning("SendPasswordResetEmail called with null or empty email");
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Email adresi gereklidir!",
                        Data = null
                    });
                }

                // E-posta formatını doğrula
                if (!IsValidEmail(model.Email))
                {
                    _logger.LogWarning("SendPasswordResetEmail called with invalid email format: {Email}", model.Email);
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Geçerli bir e-posta adresi giriniz!",
                        Data = null
                    });
                }

                _logger.LogInformation("Calling AuthService.SendPasswordResetEmail for email: {Email}", model.Email);
                var result = await _authService.SendPasswordResetEmail(model.Email);

                _logger.LogInformation("AuthService.SendPasswordResetEmail result: Status={Status}, Message={Message}",
                    result.Status, result.Message);

                if (result.Status)
                {
                    return Ok(result);
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending password reset email: {ErrorMessage}", ex.Message);

                // İç hata varsa onu da logla
                if (ex.InnerException != null)
                {
                    _logger.LogError("Inner exception: {InnerErrorMessage}", ex.InnerException.Message);
                }

                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Şifre sıfırlama e-postası gönderimi sırasında bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // E-posta formatını doğrulama
        private bool IsValidEmail(string email)
        {
            try
            {
                var addr = new System.Net.Mail.MailAddress(email);
                return addr.Address == email;
            }
            catch
            {
                return false;
            }
        }

        // Şifre sıfırlama kodunu doğrulama metodu
        [HttpPost("VerifyResetCode")]
        public async Task<IActionResult> VerifyResetCode(VerifyResetCodeViewModel model)
        {
            try
            {
                _logger.LogInformation("VerifyResetCode endpoint called");

                if (model == null || string.IsNullOrEmpty(model.Email) || string.IsNullOrEmpty(model.ResetCode))
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Email adresi ve onay kodu gereklidir!",
                        Data = null
                    });
                }

                var result = await _authService.VerifyResetCode(model.Email, model.ResetCode);
                if (result.Status)
                {
                    return Ok(result);
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying reset code");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Onay kodu doğrulama sırasında bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // Token ile şifre sıfırlama metodu
        [HttpPost("ResetPasswordWithToken")]
        public async Task<IActionResult> ResetPasswordWithToken(ResetPasswordWithTokenViewModel model)
        {
            try
            {
                _logger.LogInformation("ResetPasswordWithToken endpoint called");

                if (model == null || string.IsNullOrEmpty(model.Email) ||
                    string.IsNullOrEmpty(model.ResetCode) || string.IsNullOrEmpty(model.NewPassword))
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Email adresi, onay kodu ve yeni şifre gereklidir!",
                        Data = null
                    });
                }

                var result = await _authService.ResetPasswordWithToken(model.Email, model.ResetCode, model.NewPassword);
                if (result.Status)
                {
                    return Ok(result);
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resetting password with token");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Şifre sıfırlama sırasında bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // Admin kullanıcısı oluşturma metodu
        [HttpPost("CreateAdminUser")]
        [Authorize(Roles = "admin")] // Sadece admin kullanıcıları bu endpoint'i kullanabilir
        public async Task<IActionResult> CreateAdminUser(SaveAppUserViewModel adminViewModel)
        {
            try
            {
                _logger.LogInformation("CreateAdminUser endpoint called");

                if (adminViewModel == null || string.IsNullOrEmpty(adminViewModel.Email) || string.IsNullOrEmpty(adminViewModel.Password))
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Email ve şifre gereklidir!",
                        Data = null
                    });
                }

                // Role bilgisini admin olarak ayarla
                adminViewModel.Role = "admin";

                // Admin kullanıcısı oluştur
                var result = await _authService.Register(adminViewModel);

                if (result.Status)
                {
                    return Ok(result);
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating admin user");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Admin kullanıcısı oluşturulurken bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }

        // İlk admin kullanıcısı oluşturma metodu (sadece geliştirme aşamasında kullanılacak)
        [HttpPost("CreateFirstAdmin")]
        [AllowAnonymous] // Herkes bu endpoint'i kullanabilir (sadece geliştirme aşamasında)
        public async Task<IActionResult> CreateFirstAdmin(SaveAppUserViewModel adminViewModel)
        {
            try
            {
                _logger.LogInformation("CreateFirstAdmin endpoint called");

                // Mevcut admin kullanıcısı var mı kontrol et
                var existingAdmins = await _authService.GetUsersByRole("admin");
                if (existingAdmins != null && existingAdmins.Count > 0)
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Sistemde zaten admin kullanıcısı bulunmaktadır!",
                        Data = null
                    });
                }

                if (adminViewModel == null || string.IsNullOrEmpty(adminViewModel.Email) || string.IsNullOrEmpty(adminViewModel.Password))
                {
                    return BadRequest(new ApiResponse
                    {
                        Status = false,
                        Message = "Email ve şifre gereklidir!",
                        Data = null
                    });
                }

                // Role bilgisini admin olarak ayarla
                adminViewModel.Role = "admin";

                // Admin kullanıcısı oluştur
                var result = await _authService.Register(adminViewModel);

                if (result.Status)
                {
                    return Ok(new ApiResponse
                    {
                        Status = true,
                        Message = "İlk admin kullanıcısı başarıyla oluşturuldu!",
                        Data = result.Data
                    });
                }
                else
                {
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating first admin user");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "İlk admin kullanıcısı oluşturulurken bir hata oluştu: " + ex.Message,
                    Data = null
                });
            }
        }
    }
}
