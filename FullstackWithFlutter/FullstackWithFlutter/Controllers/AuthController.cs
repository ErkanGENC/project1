using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/Auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
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
    }
}
