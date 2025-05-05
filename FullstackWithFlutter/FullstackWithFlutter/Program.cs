using FluentAssertions.Common;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Infrastructure.DIExtensions;
using FullstackWithFlutter.Services;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Net.Http.Headers;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Text;

public class Program
{
    private static async Task Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);


        builder.Services.AddCors(options =>
        {
            options.AddPolicy(
                "AllowAll",
                builder =>
                {
                    builder
                        .AllowAnyOrigin()
                        .AllowAnyMethod()
                        .AllowAnyHeader()
                        .WithExposedHeaders("Content-Disposition"); // Flutter'da dosya indirme işlemleri için gerekli olabilir
                }
            );
        });

        // Add services to the container.
        builder.Services.AddControllers();
        builder.Services.AddRepositories(builder.Configuration);
        builder.Services.AddAutoMapper(typeof(Program));

        // JWT Authentication yapılandırması
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = false,
                    ValidateAudience = false,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes("FullstackWithFlutterSecretKey12345678901234567890"))
                };
            });

        builder.Services.AddScoped<IUserService, UserService>();
        builder.Services.AddScoped<IAuthService, AuthService>();
        builder.Services.AddScoped<IDoctorService, DoctorService>();
        builder.Services.AddScoped<IAppointmentService, AppointmentService>();
        builder.Services.AddScoped<IReportService, ReportService>();
        builder.Services.AddEndpointsApiExplorer();

        // Add logging
        builder.Logging.ClearProviders();
        builder.Logging.AddConsole();
        builder.Logging.AddDebug();

        // Configure Swagger/OpenAPI
        builder.Services.AddSwaggerGen(options =>
        {
            options.SwaggerDoc(
                "v1",
                new OpenApiInfo
                {
                    Title = "FullstackWithFlutter API",
                    Version = "v1",
                    Description = "API Documentation for FullstackWithFlutter",
                }
            );
        });

        var app = builder.Build();

        // Seed database data
        using (var scope = app.Services.CreateScope())
        {
            var services = scope.ServiceProvider;

            try
            {
                var dbInit = services.GetRequiredService<IDatabaseInitializer>();
                await dbInit.SeedSampData();
            }
            catch (Exception ex)
            {
                var msg = ex.Message;
                // Hata loglaması burada yapılabilir
            }
        }

        // Configure the HTTP request pipeline.
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        // HTTPS yönlendirmesini tekrar etkinleştiriyoruz
        app.UseHttpsRedirection();
        app.UseCors("AllowAll"); // Specify the policy name here

        // JWT Authentication ve Authorization middleware'lerini ekle
        app.UseAuthentication();
        app.UseAuthorization();

        app.MapControllers();

        app.Run();
    }
}
