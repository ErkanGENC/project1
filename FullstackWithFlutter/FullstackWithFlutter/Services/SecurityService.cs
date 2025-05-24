using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Infrastructure;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Services
{
    public class SecurityService : ISecurityService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<SecurityService> _logger;

        // Güvenlik limitleri
        private const int MAX_ATTEMPTS_PER_EMAIL_PER_HOUR = 5;
        private const int MAX_ATTEMPTS_PER_IP_PER_HOUR = 10;
        private const int MAX_ATTEMPTS_PER_EMAIL_PER_DAY = 20;
        private const int MAX_ATTEMPTS_PER_IP_PER_DAY = 50;

        public SecurityService(ApplicationDbContext context, ILogger<SecurityService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<bool> IsRateLimitExceeded(string email, string ipAddress, string attemptType)
        {
            // GEÇICI: Rate limiting devre dışı bırakıldı (test için)
            _logger.LogInformation("Rate limiting devre dışı - Email: {Email}, IP: {IpAddress}, Type: {AttemptType}", email, ipAddress, attemptType);
            return await Task.FromResult(false);

            /* ORIJINAL KOD - RATE LIMITING AKTIF ETMEK İÇİN YORUMU KALDIR
            try
            {
                var now = DateTime.Now;
                var oneHourAgo = now.AddHours(-1);
                var oneDayAgo = now.AddDays(-1);

                // E-posta bazlı kontroller
                var emailAttemptsLastHour = await _context.passwordResetAttempts
                    .Where(a => a.Email == email &&
                               a.AttemptType == attemptType &&
                               a.AttemptTime >= oneHourAgo)
                    .CountAsync();

                var emailAttemptsLastDay = await _context.passwordResetAttempts
                    .Where(a => a.Email == email &&
                               a.AttemptType == attemptType &&
                               a.AttemptTime >= oneDayAgo)
                    .CountAsync();

                // IP bazlı kontroller
                var ipAttemptsLastHour = await _context.passwordResetAttempts
                    .Where(a => a.IpAddress == ipAddress &&
                               a.AttemptType == attemptType &&
                               a.AttemptTime >= oneHourAgo)
                    .CountAsync();

                var ipAttemptsLastDay = await _context.passwordResetAttempts
                    .Where(a => a.IpAddress == ipAddress &&
                               a.AttemptType == attemptType &&
                               a.AttemptTime >= oneDayAgo)
                    .CountAsync();

                // Limit kontrolü
                if (emailAttemptsLastHour >= MAX_ATTEMPTS_PER_EMAIL_PER_HOUR ||
                    emailAttemptsLastDay >= MAX_ATTEMPTS_PER_EMAIL_PER_DAY ||
                    ipAttemptsLastHour >= MAX_ATTEMPTS_PER_IP_PER_HOUR ||
                    ipAttemptsLastDay >= MAX_ATTEMPTS_PER_IP_PER_DAY)
                {
                    _logger.LogWarning($"Rate limit exceeded for email: {email}, IP: {ipAddress}, Type: {attemptType}");
                    return true;
                }

                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error checking rate limit: {ex.Message}");
                return false; // Hata durumunda işleme devam et
            }
            */
        }

        public async Task LogAttempt(string email, string ipAddress, string attemptType, bool isSuccessful)
        {
            try
            {
                var attempt = new PasswordResetAttempt
                {
                    Email = email,
                    IpAddress = ipAddress,
                    AttemptType = attemptType,
                    IsSuccessful = isSuccessful,
                    AttemptTime = DateTime.Now
                };

                _context.passwordResetAttempts.Add(attempt);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Logged attempt: Email={email}, IP={ipAddress}, Type={attemptType}, Success={isSuccessful}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error logging attempt: {ex.Message}");
            }
        }

        public async Task<bool> IsEmailBlocked(string email)
        {
            try
            {
                var oneDayAgo = DateTime.Now.AddDays(-1);

                var failedAttempts = await _context.passwordResetAttempts
                    .Where(a => a.Email == email &&
                               !a.IsSuccessful &&
                               a.AttemptTime >= oneDayAgo)
                    .CountAsync();

                return failedAttempts >= MAX_ATTEMPTS_PER_EMAIL_PER_DAY;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error checking if email is blocked: {ex.Message}");
                return false;
            }
        }

        public async Task<bool> IsIpBlocked(string ipAddress)
        {
            try
            {
                var oneDayAgo = DateTime.Now.AddDays(-1);

                var failedAttempts = await _context.passwordResetAttempts
                    .Where(a => a.IpAddress == ipAddress &&
                               !a.IsSuccessful &&
                               a.AttemptTime >= oneDayAgo)
                    .CountAsync();

                return failedAttempts >= MAX_ATTEMPTS_PER_IP_PER_DAY;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error checking if IP is blocked: {ex.Message}");
                return false;
            }
        }
    }
}
