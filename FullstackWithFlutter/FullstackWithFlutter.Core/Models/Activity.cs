﻿namespace FullstackWithFlutter.Core.Models
{
    public class Activity
    {
        public int Id { get; set; }
        public string? Type { get; set; } // UserRegistration, AppointmentCreation, AppointmentStatusChange, DoctorAssignment, etc.
        public string? Description { get; set; }
        public int? UserId { get; set; }
        public string? UserName { get; set; }
        public DateTime CreatedDate { get; set; }
        public string? Details { get; set; } // JSON formatında ek detaylar
        public string? Icon { get; set; } // Frontend'de gösterilecek ikon
        public string? Color { get; set; } // Frontend'de gösterilecek renk
    }
}
