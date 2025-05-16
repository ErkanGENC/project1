﻿namespace FullstackWithFlutter.Core.Models
{
    public class Doctor
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Specialization { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public bool IsAvailable { get; set; }
        public string? Password { get; set; } // Doktor şifresi

        public DateTime CreatedDate { get; set; }
        public string? CreatedBy { get; set; }
        public DateTime? UpdatedDate { get; set; }
        public string? UpdatedBy { get; set; }
    }
}
