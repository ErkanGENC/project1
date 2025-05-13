using System.ComponentModel.DataAnnotations;

namespace FullstackWithFlutter.Core.ViewModels
{
    public class VerifyResetCodeViewModel
    {
        [Required(ErrorMessage = "Email adresi gereklidir")]
        [EmailAddress(ErrorMessage = "Geçerli bir email adresi giriniz")]
        public string Email { get; set; }

        [Required(ErrorMessage = "Onay kodu gereklidir")]
        public string ResetCode { get; set; }
    }
}
