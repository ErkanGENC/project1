﻿using AutoMapper;
using FullstackWithFlutter.Core.Interfaces;
using FullstackWithFlutter.Core.Models;
using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;

namespace FullstackWithFlutter.Services
{
    public class AppointmentService : IAppointmentService
    {
        private readonly IUnitofWork _unitOfWork;
        private readonly IMapper _mapper;

        public AppointmentService(IUnitofWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<bool> CreateAppointment(SaveAppointmentViewModel appointmentViewModel)
        {
            if (appointmentViewModel != null)
            {
                var newAppointment = _mapper.Map<Appointment>(appointmentViewModel);
                newAppointment.CreatedDate = DateTime.Now;
                newAppointment.CreatedBy = "API";
                await _unitOfWork.Appointments.Add(newAppointment);
                var result = _unitOfWork.Complete();
                return result > 0;
            }
            return false;
        }

        public async Task<bool> DeleteAppointment(int appointmentId)
        {
            if (appointmentId > 0)
            {
                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment != null)
                {
                    _unitOfWork.Appointments.Delete(appointment);
                    var result = _unitOfWork.Complete();
                    return result > 0;
                }
            }
            return false;
        }

        public async Task<List<AppointmentViewModel>> GetAllAppointments()
        {
            try
            {
                var appointmentList = await _unitOfWork.Appointments.GetAll();
                if (appointmentList == null)
                {
                    return new List<AppointmentViewModel>();
                }
                var appointmentListMap = _mapper.Map<List<AppointmentViewModel>>(appointmentList);
                return appointmentListMap;
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"Error in GetAllAppointments: {ex.Message}");
                throw; // Rethrow to let the controller handle it
            }
        }

        public async Task<AppointmentViewModel> GetAppointmentById(int appointmentId)
        {
            if (appointmentId > 0)
            {
                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment != null)
                {
                    var appointmentResp = _mapper.Map<AppointmentViewModel>(appointment);
                    return appointmentResp;
                }
            }
            return null;
        }

        public async Task<bool> UpdateAppointment(int appointmentId, SaveAppointmentViewModel appointmentViewModel)
        {
            if (appointmentId > 0)
            {
                var appointment = await _unitOfWork.Appointments.Get(appointmentId);
                if (appointment != null)
                {
                    appointment.PatientName = appointmentViewModel.PatientName;
                    appointment.DoctorName = appointmentViewModel.DoctorName;
                    appointment.Date = appointmentViewModel.Date;
                    appointment.Time = appointmentViewModel.Time;
                    appointment.Status = appointmentViewModel.Status;
                    appointment.Type = appointmentViewModel.Type;
                    appointment.UpdatedDate = DateTime.Now;
                    appointment.UpdatedBy = "API";
                    _unitOfWork.Appointments.Update(appointment);
                    var result = _unitOfWork.Complete();
                    return result > 0;
                }
            }
            return false;
        }
    }
}
