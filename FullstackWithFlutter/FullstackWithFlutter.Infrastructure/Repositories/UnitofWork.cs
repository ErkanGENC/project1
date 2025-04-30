using FullstackWithFlutter.Core.Interfaces;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class UnitofWork:IUnitofWork
    {
        private readonly ApplicationDbContext _dbContext;
       

        public IAppUserRepository AppUsers { get; }

        

        public UnitofWork(ApplicationDbContext applicationDbContext,IAppUserRepository appUserRepository)
        {
            _dbContext = applicationDbContext;
            AppUsers = appUserRepository;
        }

        public int Complete()
        {
            return _dbContext.SaveChanges();
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (disposing)
            {
                _dbContext.Dispose();
            }
        }
    }
}
