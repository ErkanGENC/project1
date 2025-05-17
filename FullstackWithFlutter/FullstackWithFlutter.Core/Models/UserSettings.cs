namespace FullstackWithFlutter.Core.Models
{
    public class UserSettings
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        
        // Tema ayarları
        public bool IsDarkMode { get; set; }
        
        // Font ayarları
        public string FontFamily { get; set; } = "Default";
        public double FontSize { get; set; } = 1.0; // 1.0 = normal boyut, 1.2 = %20 daha büyük, vb.
        
        // Dil ayarları
        public string Language { get; set; } = "tr"; // Varsayılan dil Türkçe
        
        // Oluşturma ve güncelleme bilgileri
        public DateTime CreatedDate { get; set; }
        public string? CreatedBy { get; set; }
        public DateTime? UpdatedDate { get; set; }
        public string? UpdatedBy { get; set; }
    }
}
