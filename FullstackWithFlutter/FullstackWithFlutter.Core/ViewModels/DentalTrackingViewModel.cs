﻿namespace FullstackWithFlutter.Core.ViewModels
{
    public class DentalTrackingViewModel
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public DateTime Date { get; set; }
        public bool MorningBrushing { get; set; }
        public bool EveningBrushing { get; set; }
        public bool UsedFloss { get; set; }
        public bool UsedMouthwash { get; set; }
        public string? Notes { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime? UpdatedDate { get; set; }
        
        // Hesaplanan alanlar
        public int BrushingCount => (MorningBrushing ? 1 : 0) + (EveningBrushing ? 1 : 0);
        public double BrushingPercentage => BrushingCount / 2.0;
        public double FlossPercentage => UsedFloss ? 1.0 : 0.0;
        public double MouthwashPercentage => UsedMouthwash ? 1.0 : 0.0;
    }

    public class SaveDentalTrackingViewModel
    {
        public int UserId { get; set; }
        public DateTime Date { get; set; }
        public bool MorningBrushing { get; set; }
        public bool EveningBrushing { get; set; }
        public bool UsedFloss { get; set; }
        public bool UsedMouthwash { get; set; }
        public string? Notes { get; set; }
    }

    public class DentalTrackingSummaryViewModel
    {
        public double BrushingPercentage { get; set; }
        public double FlossPercentage { get; set; }
        public double MouthwashPercentage { get; set; }
    }
}
