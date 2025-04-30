﻿namespace FullstackWithFlutter.Core.ViewModels
{
    public class SaveAppointmentViewModel
    {
        public string? PatientName { get; set; }
        public string? DoctorName { get; set; }
        public DateTime Date { get; set; }
        public string? Time { get; set; }
        public string? Status { get; set; }
        public string? Type { get; set; }
    }
}
