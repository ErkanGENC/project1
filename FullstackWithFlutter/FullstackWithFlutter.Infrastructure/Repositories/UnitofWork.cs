using FullstackWithFlutter.Core.Interfaces;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class UnitofWork:IUnitofWork
    {
        private readonly ApplicationDbContext _dbContext;

        public IAppUserRepository AppUsers { get; }
        public IDoctorRepository Doctors { get; }
        public IAppointmentRepository Appointments { get; }
        public IPasswordResetTokenRepository PasswordResetTokens { get; }
        public IActivityRepository Activities { get; }
        public IDentalTrackingRepository DentalTrackings { get; }
        public IUserSettingsRepository userSettings { get; }

        public UnitofWork(
            ApplicationDbContext applicationDbContext,
            IAppUserRepository appUserRepository,
            IDoctorRepository doctorRepository,
            IAppointmentRepository appointmentRepository,
            IPasswordResetTokenRepository passwordResetTokenRepository,
            IActivityRepository activityRepository,
            IDentalTrackingRepository dentalTrackingRepository,
            IUserSettingsRepository userSettingsRepository)
        {
            _dbContext = applicationDbContext;
            AppUsers = appUserRepository;
            Doctors = doctorRepository;
            Appointments = appointmentRepository;
            PasswordResetTokens = passwordResetTokenRepository;
            Activities = activityRepository;
            DentalTrackings = dentalTrackingRepository;
            userSettings = userSettingsRepository;
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
