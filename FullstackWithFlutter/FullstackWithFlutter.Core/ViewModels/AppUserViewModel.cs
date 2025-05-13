namespace FullstackWithFlutter.Core.ViewModels
{
    public class AppUserViewModel
    {
        public int Id { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? MobileNumber { get; set; }
        public string? Password { get; set; } 

        // Doktor bilgileri
        public int? DoctorId { get; set; }
        public string? DoctorName { get; set; }
        public string? Specialization { get; set; }
    }
}
