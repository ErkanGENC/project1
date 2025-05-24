using System;

namespace FullstackWithFlutter.Core.Models
{
    public class PasswordResetAttempt
    {
        public int Id { get; set; }
        public string Email { get; set; }
        public string IpAddress { get; set; }
        public DateTime AttemptTime { get; set; }
        public bool IsSuccessful { get; set; }
        public string AttemptType { get; set; } // "SendCode", "VerifyCode", "ResetPassword"
    }
}
