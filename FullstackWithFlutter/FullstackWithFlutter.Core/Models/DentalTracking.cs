﻿namespace FullstackWithFlutter.Core.Models
{
    public class DentalTracking
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public DateTime Date { get; set; }
        
        // Diş fırçalama takibi
        public bool MorningBrushing { get; set; }
        public bool EveningBrushing { get; set; }
        
        // Diş ipi kullanımı
        public bool UsedFloss { get; set; }
        
        // Ağız gargarası kullanımı
        public bool UsedMouthwash { get; set; }
        
        // Notlar
        public string? Notes { get; set; }
        
        // Oluşturma ve güncelleme tarihleri
        public DateTime CreatedDate { get; set; }
        public string? CreatedBy { get; set; }
        public DateTime? UpdatedDate { get; set; }
        public string? UpdatedBy { get; set; }

        // Diş fırçalama sayısını hesapla
        public int BrushingCount => (MorningBrushing ? 1 : 0) + (EveningBrushing ? 1 : 0);
    }
}
