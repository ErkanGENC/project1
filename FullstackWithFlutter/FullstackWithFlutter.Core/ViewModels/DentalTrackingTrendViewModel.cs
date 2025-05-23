﻿namespace FullstackWithFlutter.Core.ViewModels
{
    public class DentalTrackingTrendViewModel
    {
        public List<DailyTrendViewModel> DailyTrends { get; set; } = new List<DailyTrendViewModel>();
        public double BrushingTrendPercentage { get; set; } // Pozitif değer iyileşme, negatif değer kötüleşme
        public double FlossTrendPercentage { get; set; }
        public double MouthwashTrendPercentage { get; set; }
        public double OverallTrendPercentage { get; set; }
    }

    public class DailyTrendViewModel
    {
        public DateTime Date { get; set; }
        public double BrushingPercentage { get; set; }
        public double FlossPercentage { get; set; }
        public double MouthwashPercentage { get; set; }
        public double OverallPercentage { get; set; }
    }
}
