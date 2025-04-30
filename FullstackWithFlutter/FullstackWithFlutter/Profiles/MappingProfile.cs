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
        }
    }
}
