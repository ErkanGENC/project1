# API Dokümantasyonu

Bu dokümantasyon, Ağız ve Diş Sağlığı Takip Uygulaması'nın API endpoint'lerini detaylı bir şekilde açıklar.

## 🔑 Kimlik Doğrulama

### Giriş Yap

```http
POST /api/Auth/Login
```

#### İstek Gövdesi
```json
{
    "email": "string",
    "password": "string"
}
```

#### Başarılı Yanıt (200)
```json
{
    "status": true,
    "message": "Giriş başarılı",
    "data": {
        "token": "string",
        "user": {
            "id": "integer",
            "fullName": "string",
            "email": "string",
            "role": "string"
        }
    }
}
```

### Kayıt Ol

```http
POST /api/Auth/Register
```

#### İstek Gövdesi
```json
{
    "fullName": "string",
    "email": "string",
    "password": "string",
    "confirmPassword": "string"
}
```

#### Başarılı Yanıt (201)
```json
{
    "status": true,
    "message": "Kayıt başarılı",
    "data": {
        "id": "integer",
        "fullName": "string",
        "email": "string"
    }
}
```

## 👤 Kullanıcı İşlemleri

### Mevcut Kullanıcı Bilgilerini Al

```http
GET /api/Users/GetCurrentUser
```

#### Header
```
Authorization: Bearer {token}
```

#### Başarılı Yanıt (200)
```json
{
    "status": true,
    "message": "Kullanıcı bilgileri başarıyla getirildi",
    "data": {
        "id": "integer",
        "fullName": "string",
        "email": "string",
        "role": "string",
        "doctorId": "integer?",
        "lastLoginDate": "datetime"
    }
}
```

## 📅 Randevu İşlemleri

### Randevu Oluştur

```http
POST /api/Appointments/CreateAppointment
```

#### Header
```
Authorization: Bearer {token}
```

#### İstek Gövdesi
```json
{
    "doctorId": "integer",
    "appointmentDate": "datetime",
    "description": "string",
    "type": "string"
}
```

#### Başarılı Yanıt (201)
```json
{
    "status": true,
    "message": "Randevu başarıyla oluşturuldu",
    "data": {
        "id": "integer",
        "doctorId": "integer",
        "patientId": "integer",
        "appointmentDate": "datetime",
        "status": "string",
        "description": "string",
        "type": "string"
    }
}
```

### Randevuları Listele

```http
GET /api/Appointments/GetAllAppointments
```

#### Header
```
Authorization: Bearer {token}
```

#### Query Parametreleri
```
startDate: datetime (optional)
endDate: datetime (optional)
status: string (optional)
```

#### Başarılı Yanıt (200)
```json
{
    "status": true,
    "message": "Randevular başarıyla getirildi",
    "data": [
        {
            "id": "integer",
            "doctorId": "integer",
            "doctorName": "string",
            "patientId": "integer",
            "patientName": "string",
            "appointmentDate": "datetime",
            "status": "string",
            "description": "string",
            "type": "string"
        }
    ]
}
```

## 🦷 Diş Sağlığı Takibi

### Diş Sağlığı Kaydı Ekle

```http
POST /api/DentalTracking
```

#### Header
```
Authorization: Bearer {token}
```

#### İstek Gövdesi
```json
{
    "date": "datetime",
    "brushingCount": "integer",
    "flossingCount": "integer",
    "mouthwashUsed": "boolean",
    "painLevel": "integer",
    "notes": "string"
}
```

#### Başarılı Yanıt (201)
```json
{
    "status": true,
    "message": "Diş sağlığı kaydı başarıyla eklendi",
    "data": {
        "id": "integer",
        "userId": "integer",
        "date": "datetime",
        "brushingCount": "integer",
        "flossingCount": "integer",
        "mouthwashUsed": "boolean",
        "painLevel": "integer",
        "notes": "string"
    }
}
```

## 👨‍⚕️ Doktor İşlemleri

### Hasta Listesi

```http
GET /api/Doctors/GetPatients
```

#### Header
```
Authorization: Bearer {token}
```

#### Başarılı Yanıt (200)
```json
{
    "status": true,
    "message": "Hasta listesi başarıyla getirildi",
    "data": [
        {
            "id": "integer",
            "fullName": "string",
            "email": "string",
            "lastAppointmentDate": "datetime?",
            "nextAppointmentDate": "datetime?",
            "totalAppointments": "integer"
        }
    ]
}
```

## 📊 Raporlama

### Sistem Raporları

```http
GET /api/Reports/GetReportData
```

#### Header
```
Authorization: Bearer {token}
```

#### Query Parametreleri
```
startDate: datetime (optional)
endDate: datetime (optional)
type: string (optional)
```

#### Başarılı Yanıt (200)
```json
{
    "status": true,
    "message": "Rapor verileri başarıyla getirildi",
    "data": {
        "totalPatients": "integer",
        "totalDoctors": "integer",
        "totalAppointments": "integer",
        "completedAppointments": "integer",
        "cancelledAppointments": "integer",
        "averageAppointmentDuration": "integer",
        "mostCommonProcedures": [
            {
                "name": "string",
                "count": "integer"
            }
        ],
        "patientSatisfactionRate": "float"
    }
}
```

## 🔒 Hata Kodları

| Kod | Açıklama |
|-----|-----------|
| 200 | Başarılı |
| 201 | Oluşturuldu |
| 400 | Geçersiz İstek |
| 401 | Yetkisiz Erişim |
| 403 | Erişim Reddedildi |
| 404 | Bulunamadı |
| 500 | Sunucu Hatası |

## 📝 Notlar

1. Tüm istekler JSON formatında olmalıdır
2. Tarih formatı ISO 8601 standardında olmalıdır (örn: "2024-03-15T14:30:00Z")
3. Token'lar JWT formatındadır ve 24 saat geçerlidir
4. Rate limiting: Her IP için dakikada 100 istek
5. Maksimum istek boyutu: 10MB
6. Tüm endpoint'ler HTTPS üzerinden çalışır
7. Başarısız isteklerde detaylı hata mesajları döner 