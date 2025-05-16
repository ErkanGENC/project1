-- Mevcut randevuları güncelle
-- Önce tüm kullanıcıları ve doktorları listeleyelim
SELECT * FROM appUsers;
SELECT * FROM doctors;

-- Örnek olarak, ilk kullanıcıyı ve ilk doktoru kullanarak randevuları güncelleyelim
-- Gerçek uygulamada, doğru kullanıcı ve doktor ID'lerini kullanmalısınız
DECLARE @FirstUserId INT;
DECLARE @FirstDoctorId INT;

-- İlk kullanıcının ID'sini al
SELECT TOP 1 @FirstUserId = Id FROM appUsers;

-- İlk doktorun ID'sini al
SELECT TOP 1 @FirstDoctorId = Id FROM doctors;

-- Tüm randevuları güncelle
UPDATE appointments
SET PatientId = @FirstUserId, DoctorId = @FirstDoctorId
WHERE PatientId = 0 OR DoctorId = 0;

-- Güncellenen randevuları kontrol et
SELECT * FROM appointments;
