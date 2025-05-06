using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IAuthService
    {
        Task<ApiResponse> Register(SaveAppUserViewModel userViewModel);
        Task<ApiResponse> Login(LoginViewModel loginViewModel);
        Task<ApiResponse> ChangePassword(int userId, string currentPassword, string newPassword);
    }
}
