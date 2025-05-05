using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;

namespace FullstackWithFlutter.Services
{
    public class UserService : IUserService
    {

        public IUnitofWork _unitofWork;
        private readonly IMapper _mapper;

        public UserService(IUnitofWork unitofWork, IMapper mapper)
        {
            _unitofWork = unitofWork;
            _mapper = mapper;
        }

        public async Task<bool> CreateNewUser(SaveAppUserViewModel userViewModel)
        {
            if (userViewModel != null)
            {
                var newUser = _mapper.Map<AppUser>(userViewModel);
                newUser.CreatedDate = DateTime.Now;
                newUser.CreatedBy = "API";
                await _unitofWork.AppUsers.Add(newUser);
                var result = _unitofWork.Complete();
                if (result > 0)
                    return true;
                else
                    return false;
            }
            return false;
        }

        public async Task<bool> DeleteUser(int userId)
        {
            if (userId > 0)
            {
                var user = await _unitofWork.AppUsers.Get(userId);
                if (user != null)
                {
                    _unitofWork.AppUsers.Delete(user);
                    var result = _unitofWork.Complete();
                    if (result > 0)
                        return true;
                    else
                        return false;
                }
            }
            return false;
        }

        public async Task<List<AppUserViewModel>> GetAllUsers()
        {
            try
            {
                var userList = await _unitofWork.AppUsers.GetAll();
                if (userList == null)
                {
                    return new List<AppUserViewModel>();
                }
                var userListMap = _mapper.Map<List<AppUserViewModel>>(userList);
                return userListMap;
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"Error in GetAllUsers: {ex.Message}");
                throw; // Rethrow to let the controller handle it
            }
        }

        public async Task<AppUserViewModel> GetUserById(int userId)
        {
            if (userId > 0)
            {
                var user = await _unitofWork.AppUsers.Get(userId);
                if (user != null)
                {
                    var userResp = _mapper.Map<AppUserViewModel>(user);
                    return userResp;
                }
            }
            return null;
        }

        public async Task<bool> updateUser(int userId, SaveAppUserViewModel userViewModel)
        {
            if (userId > 0)
            {
                var user = await _unitofWork.AppUsers.Get(userId);
                if (user != null)
                {
                    user.FullName = userViewModel.FullName;
                    user.Email = userViewModel.Email;
                    user.MobileNumber = userViewModel.MobileNumber;

                    // Doktor bilgilerini güncelle
                    if (userViewModel.DoctorId.HasValue)
                    {
                        user.DoctorId = userViewModel.DoctorId;
                        user.DoctorName = userViewModel.DoctorName;
                        user.Specialization = userViewModel.Specialization;
                    }

                    user.UpdatedDate = DateTime.Now;
                    user.UpdatedBy = "API";
                    _unitofWork.AppUsers.Update(user);
                    var result = _unitofWork.Complete();
                    if (result > 0)
                        return true;
                    else
                        return false;
                }
            }
            return false;
        }
    }
}
