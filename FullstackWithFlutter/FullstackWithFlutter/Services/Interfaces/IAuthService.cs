using FullstackWithFlutter.Core.ViewModels;
using System.Collections.Generic;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IAuthService
    {
        Task<ApiResponse> Register(SaveAppUserViewModel userViewModel);
        Task<ApiResponse> Login(LoginViewModel loginViewModel);
        Task<ApiResponse> ChangePassword(int userId, string currentPassword, string newPassword);
        Task<ApiResponse> ForgotPassword(string email);
        Task<ApiResponse> ResetPassword(string email, string newPassword);

        // Yeni eklenen metodlar
        Task<ApiResponse> SendPasswordResetEmail(string email, string ipAddress = "unknown");
        Task<ApiResponse> VerifyResetCode(string email, string resetCode);
        Task<ApiResponse> ResetPasswordWithToken(string email, string resetCode, string newPassword);

        // Rol bazlı kullanıcı sorgulama
        Task<List<AppUserViewModel>> GetUsersByRole(string role);

        // Geliştirme için
        Task<ApiResponse> GetActiveResetCodes();
    }
}
