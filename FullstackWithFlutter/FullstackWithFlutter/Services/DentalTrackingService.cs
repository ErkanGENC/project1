﻿using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;

namespace FullstackWithFlutter.Services
{
    public class DentalTrackingService : IDentalTrackingService
    {
        private readonly IUnitofWork _unitOfWork;
        private readonly IMapper _mapper;
        private readonly ILogger<DentalTrackingService> _logger;

        public DentalTrackingService(IUnitofWork unitOfWork, IMapper mapper, ILogger<DentalTrackingService> logger)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<List<DentalTrackingViewModel>> GetAllRecords()
        {
            try
            {
                var records = await _unitOfWork.DentalTrackings.GetAll();
                return _mapper.Map<List<DentalTrackingViewModel>>(records);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all dental tracking records");
                return new List<DentalTrackingViewModel>();
            }
        }

        public async Task<List<DentalTrackingViewModel>> GetUserRecords(int userId)
        {
            try
            {
                var records = await _unitOfWork.DentalTrackings.GetByUserId(userId);
                return _mapper.Map<List<DentalTrackingViewModel>>(records);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting dental tracking records for user {userId}");
                return new List<DentalTrackingViewModel>();
            }
        }

        public async Task<DentalTrackingViewModel?> GetUserRecordByDate(int userId, DateTime date)
        {
            try
            {
                var record = await _unitOfWork.DentalTrackings.GetByUserIdAndDate(userId, date);
                return record != null ? _mapper.Map<DentalTrackingViewModel>(record) : null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting dental tracking record for user {userId} on date {date}");
                return null;
            }
        }

        public async Task<List<DentalTrackingViewModel>> GetUserRecordsForDateRange(int userId, DateTime startDate, DateTime endDate)
        {
            try
            {
                var records = await _unitOfWork.DentalTrackings.GetUserRecordsForDateRange(userId, startDate, endDate);
                return _mapper.Map<List<DentalTrackingViewModel>>(records);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting dental tracking records for user {userId} between {startDate} and {endDate}");
                return new List<DentalTrackingViewModel>();
            }
        }

        public async Task<bool> SaveRecord(SaveDentalTrackingViewModel recordViewModel)
        {
            try
            {
                // Önce aynı tarih için kayıt var mı kontrol et
                var existingRecord = await _unitOfWork.DentalTrackings.GetByUserIdAndDate(recordViewModel.UserId, recordViewModel.Date);

                if (existingRecord != null)
                {
                    // Varsa güncelle
                    existingRecord.MorningBrushing = recordViewModel.MorningBrushing;
                    existingRecord.EveningBrushing = recordViewModel.EveningBrushing;
                    existingRecord.UsedFloss = recordViewModel.UsedFloss;
                    existingRecord.UsedMouthwash = recordViewModel.UsedMouthwash;
                    existingRecord.Notes = recordViewModel.Notes;
                    existingRecord.UpdatedDate = DateTime.Now;
                    existingRecord.UpdatedBy = "API";

                    _unitOfWork.DentalTrackings.Update(existingRecord);
                }
                else
                {
                    // Yoksa yeni kayıt oluştur
                    var newRecord = new DentalTracking
                    {
                        UserId = recordViewModel.UserId,
                        Date = recordViewModel.Date.Date, // Sadece tarih kısmını al
                        MorningBrushing = recordViewModel.MorningBrushing,
                        EveningBrushing = recordViewModel.EveningBrushing,
                        UsedFloss = recordViewModel.UsedFloss,
                        UsedMouthwash = recordViewModel.UsedMouthwash,
                        Notes = recordViewModel.Notes,
                        CreatedDate = DateTime.Now,
                        CreatedBy = "API"
                    };

                    await _unitOfWork.DentalTrackings.Add(newRecord);
                }

                _unitOfWork.Complete();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error saving dental tracking record for user {recordViewModel.UserId}");
                return false;
            }
        }

        public async Task<bool> UpdateRecord(int id, SaveDentalTrackingViewModel recordViewModel)
        {
            try
            {
                var existingRecord = await _unitOfWork.DentalTrackings.Get(id);
                if (existingRecord == null)
                {
                    _logger.LogWarning($"Dental tracking record with ID {id} not found");
                    return false;
                }

                existingRecord.MorningBrushing = recordViewModel.MorningBrushing;
                existingRecord.EveningBrushing = recordViewModel.EveningBrushing;
                existingRecord.UsedFloss = recordViewModel.UsedFloss;
                existingRecord.UsedMouthwash = recordViewModel.UsedMouthwash;
                existingRecord.Notes = recordViewModel.Notes;
                existingRecord.UpdatedDate = DateTime.Now;
                existingRecord.UpdatedBy = "API";

                _unitOfWork.DentalTrackings.Update(existingRecord);
                _unitOfWork.Complete();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating dental tracking record with ID {id}");
                return false;
            }
        }

        public async Task<bool> DeleteRecord(int id)
        {
            try
            {
                var record = await _unitOfWork.DentalTrackings.Get(id);
                if (record == null)
                {
                    _logger.LogWarning($"Dental tracking record with ID {id} not found");
                    return false;
                }

                _unitOfWork.DentalTrackings.Delete(record);
                _unitOfWork.Complete();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting dental tracking record with ID {id}");
                return false;
            }
        }

        public async Task<DentalTrackingSummaryViewModel> GetUserSummary(int userId)
        {
            try
            {
                // Son 7 günün kayıtlarını al
                var endDate = DateTime.Now.Date;
                var startDate = endDate.AddDays(-7);
                var records = await _unitOfWork.DentalTrackings.GetUserRecordsForDateRange(userId, startDate, endDate);

                if (!records.Any())
                {
                    return new DentalTrackingSummaryViewModel
                    {
                        BrushingPercentage = 0,
                        FlossPercentage = 0,
                        MouthwashPercentage = 0
                    };
                }

                // Diş fırçalama yüzdesi (toplam fırçalama / (gün sayısı * 2))
                int totalBrushing = records.Sum(r => r.BrushingCount);
                double brushingPercentage = Math.Min(1.0, totalBrushing / (double)(records.Count() * 2));

                // Diş ipi kullanım yüzdesi (kullanılan gün sayısı / toplam gün)
                int flossUsedDays = records.Count(r => r.UsedFloss);
                double flossPercentage = flossUsedDays / (double)records.Count();

                // Gargara kullanım yüzdesi (kullanılan gün sayısı / toplam gün)
                int mouthwashUsedDays = records.Count(r => r.UsedMouthwash);
                double mouthwashPercentage = mouthwashUsedDays / (double)records.Count();

                return new DentalTrackingSummaryViewModel
                {
                    BrushingPercentage = brushingPercentage,
                    FlossPercentage = flossPercentage,
                    MouthwashPercentage = mouthwashPercentage
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting dental tracking summary for user {userId}");
                return new DentalTrackingSummaryViewModel
                {
                    BrushingPercentage = 0,
                    FlossPercentage = 0,
                    MouthwashPercentage = 0
                };
            }
        }

        public async Task<Dictionary<int, List<DentalTrackingViewModel>>> GetRecordsForDoctorPatients(int doctorId)
        {
            try
            {
                // Doktorun hastalarını bul
                var appointments = await _unitOfWork.Appointments.GetAll();
                var doctorAppointments = appointments.Where(a => a.DoctorId == doctorId).ToList();

                // Benzersiz hasta ID'lerini al
                var patientIds = doctorAppointments.Select(a => a.PatientId).Distinct().ToList();

                // Her hasta için diş sağlığı kayıtlarını al
                var result = new Dictionary<int, List<DentalTrackingViewModel>>();

                foreach (var patientId in patientIds)
                {
                    var records = await GetUserRecords(patientId);
                    if (records.Any())
                    {
                        result.Add(patientId, records);
                    }
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting dental tracking records for doctor {doctorId}'s patients");
                return new Dictionary<int, List<DentalTrackingViewModel>>();
            }
        }

        public async Task<Dictionary<int, DentalTrackingSummaryViewModel>> GetSummariesForDoctorPatients(int doctorId)
        {
            try
            {
                // Doktorun hastalarını bul
                var appointments = await _unitOfWork.Appointments.GetAll();
                var doctorAppointments = appointments.Where(a => a.DoctorId == doctorId).ToList();

                // Benzersiz hasta ID'lerini al
                var patientIds = doctorAppointments.Select(a => a.PatientId).Distinct().ToList();

                // Her hasta için özet bilgileri al
                var result = new Dictionary<int, DentalTrackingSummaryViewModel>();

                foreach (var patientId in patientIds)
                {
                    var summary = await GetUserSummary(patientId);
                    result.Add(patientId, summary);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting dental tracking summaries for doctor {doctorId}'s patients");
                return new Dictionary<int, DentalTrackingSummaryViewModel>();
            }
        }

        public async Task<Dictionary<int, DentalTrackingTrendViewModel>> GetTrendsForDoctorPatients(int doctorId, int days)
        {
            try
            {
                // Doktorun hastalarını bul
                var appointments = await _unitOfWork.Appointments.GetAll();
                var doctorAppointments = appointments.Where(a => a.DoctorId == doctorId).ToList();

                // Benzersiz hasta ID'lerini al
                var patientIds = doctorAppointments.Select(a => a.PatientId).Distinct().ToList();

                // Her hasta için trend bilgilerini hesapla
                var result = new Dictionary<int, DentalTrackingTrendViewModel>();

                foreach (var patientId in patientIds)
                {
                    // Son 'days' günün kayıtlarını al
                    var endDate = DateTime.Now.Date;
                    var startDate = endDate.AddDays(-days);
                    var records = await _unitOfWork.DentalTrackings.GetUserRecordsForDateRange(patientId, startDate, endDate);

                    if (!records.Any())
                    {
                        continue;
                    }

                    // Günlük trendleri hesapla
                    var dailyTrends = new List<DailyTrendViewModel>();
                    var recordsList = records.OrderBy(r => r.Date).ToList();

                    foreach (var record in recordsList)
                    {
                        var brushingPercentage = record.BrushingCount / 2.0;
                        var flossPercentage = record.UsedFloss ? 1.0 : 0.0;
                        var mouthwashPercentage = record.UsedMouthwash ? 1.0 : 0.0;
                        var overallPercentage = (brushingPercentage + flossPercentage + mouthwashPercentage) / 3.0;

                        dailyTrends.Add(new DailyTrendViewModel
                        {
                            Date = record.Date,
                            BrushingPercentage = brushingPercentage,
                            FlossPercentage = flossPercentage,
                            MouthwashPercentage = mouthwashPercentage,
                            OverallPercentage = overallPercentage
                        });
                    }

                    // Trend yüzdelerini hesapla (ilk yarı vs. ikinci yarı)
                    if (dailyTrends.Count >= 2)
                    {
                        int midPoint = dailyTrends.Count / 2;
                        var firstHalf = dailyTrends.Take(midPoint).ToList();
                        var secondHalf = dailyTrends.Skip(midPoint).ToList();

                        double firstHalfBrushing = firstHalf.Average(d => d.BrushingPercentage);
                        double secondHalfBrushing = secondHalf.Average(d => d.BrushingPercentage);
                        double brushingTrend = secondHalfBrushing - firstHalfBrushing;

                        double firstHalfFloss = firstHalf.Average(d => d.FlossPercentage);
                        double secondHalfFloss = secondHalf.Average(d => d.FlossPercentage);
                        double flossTrend = secondHalfFloss - firstHalfFloss;

                        double firstHalfMouthwash = firstHalf.Average(d => d.MouthwashPercentage);
                        double secondHalfMouthwash = secondHalf.Average(d => d.MouthwashPercentage);
                        double mouthwashTrend = secondHalfMouthwash - firstHalfMouthwash;

                        double firstHalfOverall = firstHalf.Average(d => d.OverallPercentage);
                        double secondHalfOverall = secondHalf.Average(d => d.OverallPercentage);
                        double overallTrend = secondHalfOverall - firstHalfOverall;

                        result.Add(patientId, new DentalTrackingTrendViewModel
                        {
                            DailyTrends = dailyTrends,
                            BrushingTrendPercentage = brushingTrend,
                            FlossTrendPercentage = flossTrend,
                            MouthwashTrendPercentage = mouthwashTrend,
                            OverallTrendPercentage = overallTrend
                        });
                    }
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error calculating dental tracking trends for doctor {doctorId}'s patients");
                return new Dictionary<int, DentalTrackingTrendViewModel>();
            }
        }

        public async Task<bool> StartTreatment(int patientId, int doctorId, string treatmentType, string notes)
        {
            try
            {
                // Hasta ve doktor bilgilerini al
                var patient = await _unitOfWork.AppUsers.Get(patientId);
                var doctor = await _unitOfWork.Doctors.Get(doctorId);

                if (patient == null || doctor == null)
                {
                    _logger.LogWarning($"Patient ID {patientId} or Doctor ID {doctorId} not found");
                    return false;
                }

                // Yeni randevu oluştur
                var appointment = new Appointment
                {
                    PatientId = patientId,
                    DoctorId = doctorId,
                    PatientName = patient.FullName,
                    DoctorName = doctor.Name,
                    Date = DateTime.Now.Date,
                    Time = DateTime.Now.ToString("HH:mm"),
                    Status = "Tedavi Başlatıldı",
                    Type = treatmentType,
                    CreatedDate = DateTime.Now,
                    CreatedBy = "API"
                };

                await _unitOfWork.Appointments.Add(appointment);
                var result = _unitOfWork.Complete();

                return result > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error starting treatment for patient {patientId} by doctor {doctorId}");
                return false;
            }
        }
    }
}
