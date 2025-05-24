using System.Threading.Tasks;

namespace FullstackWithFlutter.Services.Interfaces
{
    public interface ISecurityService
    {
        Task<bool> IsRateLimitExceeded(string email, string ipAddress, string attemptType);
        Task LogAttempt(string email, string ipAddress, string attemptType, bool isSuccessful);
        Task<bool> IsEmailBlocked(string email);
        Task<bool> IsIpBlocked(string ipAddress);
    }
}
