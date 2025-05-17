using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface IUserService
    {
        Task<bool> CreateNewUser(SaveAppUserViewModel userViewModel);

        Task<List<AppUserViewModel>> GetAllUsers();

        Task<AppUserViewModel> GetUserById(int userId);

        Task<bool> UpdateUser(int userId, SaveAppUserViewModel userViewModel);

        Task<bool> DeleteUser(int userId);

        // Admin kullanıcısı oluşturma
        Task<Core.ViewModels.ApiResponse> CreateAdminUser(SaveAppUserViewModel adminViewModel);
    }
}
