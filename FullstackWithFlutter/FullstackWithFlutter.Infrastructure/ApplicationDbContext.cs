using FullstackWithFlutter.Core.Models;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Infrastructure
{
    public class ApplicationDbContext: DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> dbContextOptions) : base(dbContextOptions)
        {

        }
        public DbSet<AppUser> appUsers { get; set; }
        public DbSet<Doctor> doctors { get; set; }
        public DbSet<Appointment> appointments { get; set; }
        public DbSet<PasswordResetToken> passwordResetTokens { get; set; }
        public DbSet<Activity> activities { get; set; }
        public DbSet<DentalTracking> dentalTrackings { get; set; }
        public DbSet<UserSettings> userSettings { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // PasswordResetToken tablosu için konfigürasyon
            modelBuilder.Entity<PasswordResetToken>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Email).IsRequired().HasMaxLength(100);
                entity.Property(e => e.Token).IsRequired().HasMaxLength(10);
                entity.Property(e => e.ExpiryDate).IsRequired();
                entity.Property(e => e.IsUsed).IsRequired();
                entity.Property(e => e.CreatedDate).IsRequired();
            });
        }
    }
}
