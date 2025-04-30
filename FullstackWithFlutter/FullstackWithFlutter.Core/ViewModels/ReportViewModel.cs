﻿using System.Collections.Generic;

namespace FullstackWithFlutter.Core.ViewModels
{
    public class ReportViewModel
    {
        public PatientStatsViewModel PatientStats { get; set; }
        public AppointmentStatsViewModel AppointmentStats { get; set; }
        public RevenueStatsViewModel RevenueStats { get; set; }
    }

    public class PatientStatsViewModel
    {
        public int TotalPatients { get; set; }
        public int NewPatients { get; set; }
        public int ActivePatients { get; set; }
        public int InactivePatients { get; set; }
        public List<AgeGroupViewModel> PatientsByAge { get; set; }
        public List<GenderViewModel> PatientsByGender { get; set; }
    }

    public class AgeGroupViewModel
    {
        public string Age { get; set; }
        public int Count { get; set; }
    }

    public class GenderViewModel
    {
        public string Gender { get; set; }
        public int Count { get; set; }
    }

    public class AppointmentStatsViewModel
    {
        public int TotalAppointments { get; set; }
        public int CompletedAppointments { get; set; }
        public int CancelledAppointments { get; set; }
        public int PendingAppointments { get; set; }
        public List<MonthlyAppointmentViewModel> AppointmentsByMonth { get; set; }
        public List<AppointmentTypeViewModel> AppointmentsByType { get; set; }
    }

    public class MonthlyAppointmentViewModel
    {
        public string Month { get; set; }
        public int Count { get; set; }
    }

    public class AppointmentTypeViewModel
    {
        public string Type { get; set; }
        public int Count { get; set; }
    }

    public class RevenueStatsViewModel
    {
        public decimal TotalRevenue { get; set; }
        public decimal PendingPayments { get; set; }
        public List<MonthlyRevenueViewModel> RevenueByMonth { get; set; }
        public List<ServiceRevenueViewModel> RevenueByService { get; set; }
    }

    public class MonthlyRevenueViewModel
    {
        public string Month { get; set; }
        public decimal Amount { get; set; }
    }

    public class ServiceRevenueViewModel
    {
        public string Service { get; set; }
        public decimal Amount { get; set; }
    }
}
