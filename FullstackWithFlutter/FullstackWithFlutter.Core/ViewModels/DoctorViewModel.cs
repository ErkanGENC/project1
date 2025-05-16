﻿namespace FullstackWithFlutter.Core.ViewModels
{
    public class DoctorViewModel
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Specialization { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public bool IsAvailable { get; set; }
        public string? Role { get; set; }
    }
}
