using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.Sqlite;
using System.Data;
using Dapper;

namespace FullstackWithFlutter.Infrastructure
{
    public class DatabaseInitializer:IDatabaseInitializer
    {
        private readonly ApplicationDbContext _dbContext;
        private readonly string _connectionString;

        public DatabaseInitializer(ApplicationDbContext dbContext)
        {
            _dbContext = dbContext;
            _connectionString = dbContext.Database.GetConnectionString();
        }

        public async Task InitializeDatabase()
        {
            // Veritabanı bağlantısını oluştur
            using (var connection = new SqliteConnection(_connectionString))
            {
                await connection.OpenAsync();

                // Kullanıcı tablosunu oluştur
                await connection.ExecuteAsync(@"
                    CREATE TABLE IF NOT EXISTS appUsers (
                        Id INTEGER PRIMARY KEY AUTOINCREMENT,
                        FullName TEXT NOT NULL,
                        Email TEXT,
                        Password TEXT,
                        MobileNumber TEXT,
                        PhoneNumber TEXT,
                        DoctorId INTEGER,
                        DoctorName TEXT,
                        CreatedDate TEXT,
                        CreatedBy TEXT,
                        UpdatedDate TEXT,
                        UpdatedBy TEXT
                    );
                ");

                // Doktor tablosunu oluştur
                await connection.ExecuteAsync(@"
                    CREATE TABLE IF NOT EXISTS doctors (
                        Id INTEGER PRIMARY KEY AUTOINCREMENT,
                        FullName TEXT NOT NULL,
                        Email TEXT,
                        Password TEXT,
                        PhoneNumber TEXT,
                        Specialty TEXT,
                        CreatedDate TEXT,
                        CreatedBy TEXT,
                        UpdatedDate TEXT,
                        UpdatedBy TEXT
                    );
                ");

                // Randevu tablosunu oluştur
                await connection.ExecuteAsync(@"
                    CREATE TABLE IF NOT EXISTS appointments (
                        Id INTEGER PRIMARY KEY AUTOINCREMENT,
                        PatientId INTEGER,
                        PatientName TEXT NOT NULL,
                        DoctorId INTEGER,
                        DoctorName TEXT NOT NULL,
                        Date TEXT NOT NULL,
                        Time TEXT NOT NULL,
                        Status TEXT NOT NULL,
                        Notes TEXT,
                        CreatedDate TEXT,
                        CreatedBy TEXT,
                        UpdatedDate TEXT,
                        UpdatedBy TEXT,
                        FOREIGN KEY (PatientId) REFERENCES appUsers(Id),
                        FOREIGN KEY (DoctorId) REFERENCES doctors(Id)
                    );
                ");

                // Şifre sıfırlama token tablosunu oluştur
                await connection.ExecuteAsync(@"
                    CREATE TABLE IF NOT EXISTS passwordResetTokens (
                        Id INTEGER PRIMARY KEY AUTOINCREMENT,
                        UserId INTEGER NOT NULL,
                        Token TEXT NOT NULL,
                        ExpiryDate TEXT NOT NULL,
                        IsUsed INTEGER NOT NULL DEFAULT 0,
                        CreatedDate TEXT NOT NULL,
                        FOREIGN KEY (UserId) REFERENCES appUsers(Id)
                    );
                ");

                // Aktivite tablosunu oluştur
                await connection.ExecuteAsync(@"
                    CREATE TABLE IF NOT EXISTS activities (
                        Id INTEGER PRIMARY KEY AUTOINCREMENT,
                        UserId INTEGER,
                        ActivityType TEXT NOT NULL,
                        Description TEXT NOT NULL,
                        CreatedDate TEXT NOT NULL,
                        FOREIGN KEY (UserId) REFERENCES appUsers(Id)
                    );
                ");

                // Diş sağlığı takip tablosunu oluştur
                await connection.ExecuteAsync(@"
                    CREATE TABLE IF NOT EXISTS dentalTrackings (
                        Id INTEGER PRIMARY KEY AUTOINCREMENT,
                        UserId INTEGER NOT NULL,
                        Date TEXT NOT NULL,
                        MorningBrushing INTEGER NOT NULL DEFAULT 0,
                        EveningBrushing INTEGER NOT NULL DEFAULT 0,
                        UsedFloss INTEGER NOT NULL DEFAULT 0,
                        UsedMouthwash INTEGER NOT NULL DEFAULT 0,
                        Notes TEXT,
                        CreatedDate TEXT NOT NULL,
                        CreatedBy TEXT,
                        UpdatedDate TEXT,
                        UpdatedBy TEXT,
                        FOREIGN KEY (UserId) REFERENCES appUsers(Id)
                    );
                ");
            }
        }

        public async Task SeedSampData()
        {
            await InitializeDatabase();
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
