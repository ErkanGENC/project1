﻿using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class AppointmentRepository : GenericRepository<Appointment>, IAppointmentRepository
    {
        public AppointmentRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }
    }
}
