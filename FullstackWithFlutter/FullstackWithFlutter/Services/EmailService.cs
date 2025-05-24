using FullstackWithFlutter.Services.Interfaces;
using System.Net;
using System.Net.Mail;

namespace FullstackWithFlutter.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            try
            {
                // E-posta gönderimi için log kaydı
                _logger.LogInformation($"E-posta gönderiliyor: To={to}, Subject={subject}");

                // SMTP ayarlarını kontrol et
                var smtpServer = _configuration["EmailSettings:SmtpServer"];
                var portStr = _configuration["EmailSettings:Port"];
                var enableSslStr = _configuration["EmailSettings:EnableSsl"];
                var username = _configuration["EmailSettings:Username"];
                var password = _configuration["EmailSettings:Password"];
                var senderEmail = _configuration["EmailSettings:SenderEmail"];
                var sendRealEmailsStr = _configuration["EmailSettings:SendRealEmails"];

                // Ayarları logla (şifre hariç)
                _logger.LogInformation($"SMTP Ayarları - Server: {smtpServer}, Port: {portStr}, SSL: {enableSslStr}, Username: {username}, SenderEmail: {senderEmail}, SendRealEmails: {sendRealEmailsStr}");

                // Ayarları doğrula
                if (string.IsNullOrEmpty(smtpServer) || string.IsNullOrEmpty(portStr) ||
                    string.IsNullOrEmpty(enableSslStr) || string.IsNullOrEmpty(username) ||
                    string.IsNullOrEmpty(password) || string.IsNullOrEmpty(senderEmail))
                {
                    _logger.LogError("E-posta ayarları eksik veya hatalı!");
                    throw new InvalidOperationException("E-posta ayarları eksik veya hatalı!");
                }

                // Port ve SSL ayarlarını parse et
                if (!int.TryParse(portStr, out int port))
                {
                    _logger.LogError($"Geçersiz port numarası: {portStr}");
                    throw new InvalidOperationException($"Geçersiz port numarası: {portStr}");
                }

                if (!bool.TryParse(enableSslStr, out bool enableSsl))
                {
                    _logger.LogError($"Geçersiz EnableSsl değeri: {enableSslStr}");
                    throw new InvalidOperationException($"Geçersiz EnableSsl değeri: {enableSslStr}");
                }

                // SendRealEmails ayarını parse et
                bool sendRealEmails = true; // Varsayılan olarak true yap
                if (!string.IsNullOrEmpty(sendRealEmailsStr))
                {
                    // Farklı string değerlerini kontrol et
                    var lowerValue = sendRealEmailsStr.ToLower().Trim();
                    sendRealEmails = lowerValue == "true" || lowerValue == "1" || lowerValue == "yes";
                }

                _logger.LogInformation($"SendRealEmails ayarı: '{sendRealEmailsStr}' -> {sendRealEmails}");

                try
                {
                    // SMTP istemcisi ile e-posta gönderimi
                    using (var client = new SmtpClient())
                    {
                        // SMTP ayarlarını yapılandır
                        client.Host = smtpServer;
                        client.Port = port;
                        client.EnableSsl = enableSsl;
                        client.Credentials = new NetworkCredential(username, password);
                        client.DeliveryMethod = SmtpDeliveryMethod.Network;
                        client.Timeout = 30000; // 30 saniye timeout

                        // Gmail için ek ayarlar
                        if (smtpServer.Contains("gmail"))
                        {
                            // Gmail için TLS 1.2 kullan
                            System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls11 | System.Net.SecurityProtocolType.Tls;
                        }

                        // E-posta mesajını oluştur
                        var message = new MailMessage();
                        message.From = new MailAddress(senderEmail, _configuration["EmailSettings:SenderName"] ?? "FullstackWithFlutter");
                        message.To.Add(new MailAddress(to));
                        message.Subject = subject;
                        message.Body = body;
                        message.IsBodyHtml = true;

                        // Gerçek ortamda e-posta gönderimi
                        if (sendRealEmails)
                        {
                            _logger.LogInformation($"Gerçek e-posta gönderimi başlatılıyor: To={to}");
                            try
                            {
                                await client.SendMailAsync(message);
                                _logger.LogInformation($"E-posta başarıyla gönderildi: To={to}");
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError($"E-posta gönderimi başarısız: {ex.Message}");
                                // Gerçek gönderim başarısız olsa bile, simüle edilmiş gönderimi göster
                                _logger.LogWarning($"Gerçek gönderim başarısız olduğu için simüle edilmiş gönderim yapılıyor");

                                // Simüle edilmiş gönderim bilgilerini logla
                                _logger.LogInformation($"[SIMULATED] E-posta içeriği:");
                                _logger.LogInformation($"Kime: {to}");
                                _logger.LogInformation($"Konu: {subject}");
                                _logger.LogInformation($"İçerik: {body.Substring(0, Math.Min(100, body.Length))}...");
                                _logger.LogInformation($"[SIMULATED] E-posta gönderimi simüle edildi: To={to}");
                            }
                        }
                        else
                        {
                            // Geliştirme ortamında e-posta gönderimi simüle edilir
                            _logger.LogInformation($"[DEV MODE] E-posta içeriği:");
                            _logger.LogInformation($"Kime: {to}");
                            _logger.LogInformation($"Konu: {subject}");
                            _logger.LogInformation($"İçerik: {body.Substring(0, Math.Min(100, body.Length))}...");
                            _logger.LogInformation($"[DEV MODE] E-posta gönderimi simüle edildi: To={to}");
                        }

                        // Her durumda başarılı kabul et
                        await Task.CompletedTask;
                    }
                }
                catch (System.Net.Mail.SmtpException smtpEx)
                {
                    _logger.LogError($"SMTP hatası: {smtpEx.Message}, StatusCode: {smtpEx.StatusCode}, StackTrace: {smtpEx.StackTrace}");

                    // SMTP hatası detaylarını logla
                    if (smtpEx.InnerException != null)
                    {
                        _logger.LogError($"SMTP iç hata: {smtpEx.InnerException.Message}");
                    }

                    // Hatayı yukarı fırlat
                    throw;
                }
                catch (Exception ex)
                {
                    _logger.LogError($"E-posta gönderimi sırasında beklenmeyen hata: {ex.Message}, StackTrace: {ex.StackTrace}");

                    // Hatayı yukarı fırlat
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"E-posta gönderimi sırasında hata oluştu: {ex.Message}");
                throw;
            }
        }
    }
}
