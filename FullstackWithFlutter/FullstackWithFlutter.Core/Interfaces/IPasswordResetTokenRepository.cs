using FullstackWithFlutter.Core.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Core.Interfaces
{
    public interface IPasswordResetTokenRepository : IGenericRepository<PasswordResetToken>
    {
        Task<PasswordResetToken> GetValidTokenByEmail(string email);
        Task<PasswordResetToken> GetTokenByEmailAndCode(string email, string token);
    }
}
