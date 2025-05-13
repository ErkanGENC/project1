using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class PasswordResetTokenRepository : GenericRepository<PasswordResetToken>, IPasswordResetTokenRepository
    {
        public PasswordResetTokenRepository(ApplicationDbContext context) : base(context)
        {
        }

        public async Task<PasswordResetToken> GetValidTokenByEmail(string email)
        {
            return await _context.Set<PasswordResetToken>()
                .Where(t => t.Email == email && t.ExpiryDate > DateTime.Now && !t.IsUsed)
                .OrderByDescending(t => t.CreatedDate)
                .FirstOrDefaultAsync();
        }

        public async Task<PasswordResetToken> GetTokenByEmailAndCode(string email, string token)
        {
            return await _context.Set<PasswordResetToken>()
                .Where(t => t.Email == email && t.Token == token && t.ExpiryDate > DateTime.Now && !t.IsUsed)
                .FirstOrDefaultAsync();
        }
    }
}
