using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Core.Interfaces
{
    public interface IUnitofWork:IDisposable
    {
        IAppUserRepository AppUsers { get; }
        IDoctorRepository Doctors { get; }
        IAppointmentRepository Appointments { get; }
        IPasswordResetTokenRepository PasswordResetTokens { get; }
        IActivityRepository Activities { get; }
        IDentalTrackingRepository DentalTrackings { get; }
        IUserSettingsRepository userSettings { get; }
        int Complete();
    }
}
