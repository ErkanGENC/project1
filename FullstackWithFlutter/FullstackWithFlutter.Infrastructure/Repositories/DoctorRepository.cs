﻿using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;

namespace FullstackWithFlutter.Infrastructure.Repositories
{
    public class DoctorRepository : GenericRepository<Doctor>, IDoctorRepository
    {
        public DoctorRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }
    }
}
