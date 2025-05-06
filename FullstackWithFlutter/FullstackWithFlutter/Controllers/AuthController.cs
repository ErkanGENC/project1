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
    }
}
