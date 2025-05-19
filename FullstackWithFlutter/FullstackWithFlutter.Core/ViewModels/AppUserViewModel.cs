namespace FullstackWithFlutter.Core.ViewModels
{
    public class AppUserViewModel
    {
        public int Id { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? MobileNumber { get; set; }
        public string? Password { get; set; }

        // Kullanıcı rolü: user, doctor, admin
        public string? Role { get; set; }
    }
}
