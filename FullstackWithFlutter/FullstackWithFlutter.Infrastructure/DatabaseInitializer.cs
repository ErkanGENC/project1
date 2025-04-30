using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
namespace FullstackWithFlutter.Infrastructure
{
    public class DatabaseInitializer:IDatabaseInitializer
    {
        private readonly ApplicationDbContext _dbContext;

        public DatabaseInitializer(ApplicationDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task SeedSampData()
        {
            await _dbContext.Database.EnsureCreatedAsync().ConfigureAwait(false);

            if (!_dbContext.appUsers.Any())
            {
                var testUser1 = new AppUser()
                {
                    FullName = "Test User 1",
                    MobileNumber = "+9000001",
                    CreatedDate = DateTime.Now,
                    CreatedBy = "SeedSampData",
                    UpdatedBy="SeedSampData"
                };
                var testUser2 = new AppUser()
                {
                    FullName = "Test User 2",
                    MobileNumber = "+9000002",
                    CreatedDate = DateTime.Now,
                    CreatedBy = "SeedSampData",
                    UpdatedBy="SeedSampData"
                };
                _dbContext.appUsers.Add(testUser1);
                _dbContext.appUsers.Add(testUser2);

                await _dbContext.SaveChangesAsync();
            }
        }
    }
}
