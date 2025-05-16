using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

namespace FullstackWithFlutter.Infrastructure.DIExtensions
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddRepositories(this IServiceCollection services,IConfiguration configuration)
        {
            services.AddScoped<IAppUserRepository, AppUserRepository>();
            services.AddScoped<IDoctorRepository, DoctorRepository>();
            services.AddScoped<IAppointmentRepository, AppointmentRepository>();
            services.AddScoped<IPasswordResetTokenRepository, PasswordResetTokenRepository>();
            services.AddScoped<IActivityRepository, ActivityRepository>();
            services.AddScoped<IUnitofWork, UnitofWork>();
            services.AddScoped<IDatabaseInitializer, DatabaseInitializer>();

            services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(configuration["ConnectionStrings:DefaultConnection"],
        b => b.MigrationsAssembly("FullstackWithFlutter")));
            return services;
        }
    }
}
