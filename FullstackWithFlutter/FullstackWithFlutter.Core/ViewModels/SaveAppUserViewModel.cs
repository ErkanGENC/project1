namespace FullstackWithFlutter.Core.ViewModels
{
    public class SaveAppUserViewModel
    {
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Password { get; set; }
        public string? MobileNumber { get; set; }
        public DateTime? BirthDate { get; set; }

        // Kullanıcı rolü: user, doctor, admin
        public string? Role { get; set; }
    }
}
