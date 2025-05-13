using System.ComponentModel.DataAnnotations;

namespace FullstackWithFlutter.Core.ViewModels
{
    public class SendPasswordResetEmailViewModel
    {
        [Required(ErrorMessage = "Email adresi gereklidir")]
        [EmailAddress(ErrorMessage = "Geçerli bir email adresi giriniz")]
        public string Email { get; set; }
    }
}
