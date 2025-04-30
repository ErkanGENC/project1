using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class AppUserRepository: GenericRepository<AppUser>,IAppUserRepository
    {
        public AppUserRepository(ApplicationDbContext dbContext) : base(dbContext)
        {

        }
    }
}
