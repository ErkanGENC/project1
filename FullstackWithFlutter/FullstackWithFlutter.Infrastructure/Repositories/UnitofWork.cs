using FullstackWithFlutter.Core.Interfaces;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class UnitofWork:IUnitofWork
    {
        private readonly ApplicationDbContext _dbContext;

        public IAppUserRepository AppUsers { get; }
        public IDoctorRepository Doctors { get; }
        public IAppointmentRepository Appointments { get; }

        public UnitofWork(
            ApplicationDbContext applicationDbContext,
            IAppUserRepository appUserRepository,
            IDoctorRepository doctorRepository,
            IAppointmentRepository appointmentRepository)
        {
            _dbContext = applicationDbContext;
            AppUsers = appUserRepository;
            Doctors = doctorRepository;
            Appointments = appointmentRepository;
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
