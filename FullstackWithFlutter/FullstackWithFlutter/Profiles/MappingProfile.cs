using AutoMapper;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;

namespace FullstackWithFlutter.Profiles
{
    public class MappingProfile:Profile
    {
        public MappingProfile()
        {
            CreateMap<AppUser, SaveAppUserViewModel>().ReverseMap();
            CreateMap<AppUser, AppUserViewModel>().ReverseMap();

            CreateMap<Doctor, SaveDoctorViewModel>().ReverseMap();
            CreateMap<Doctor, DoctorViewModel>().ReverseMap();

            CreateMap<Appointment, SaveAppointmentViewModel>().ReverseMap();
            CreateMap<Appointment, AppointmentViewModel>().ReverseMap();

            CreateMap<DentalTracking, SaveDentalTrackingViewModel>().ReverseMap();
            CreateMap<DentalTracking, DentalTrackingViewModel>().ReverseMap();

            CreateMap<UserSettings, SaveUserSettingsViewModel>().ReverseMap();
            CreateMap<UserSettings, UserSettingsViewModel>().ReverseMap();
        }
    }
}
