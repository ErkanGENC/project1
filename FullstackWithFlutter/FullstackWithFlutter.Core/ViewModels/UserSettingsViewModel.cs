﻿namespace FullstackWithFlutter.Core.ViewModels
{
    public class UserSettingsViewModel
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
    }
    
    public class SaveUserSettingsViewModel
    {
        public int UserId { get; set; }
        
        // Tema ayarları
        public bool IsDarkMode { get; set; }
        
        // Font ayarları
        public string FontFamily { get; set; } = "Default";
        public double FontSize { get; set; } = 1.0; // 1.0 = normal boyut, 1.2 = %20 daha büyük, vb.
        
        // Dil ayarları
        public string Language { get; set; } = "tr"; // Varsayılan dil Türkçe
    }
}
