using FullstackWithFlutter.Core.ViewModels;
using FullstackWithFlutter.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Infrastructure;

namespace FullstackWithFlutter.Controllers
{
    [ApiController]
    [Route("api/Users")]
    public class UserController : ControllerBase
    {
        public readonly IUserService _userService;
        private readonly ILogger<UserController> _logger;

        public UserController(IUserService userService, ILogger<UserController> logger)
        {
            _userService = userService;
            _logger = logger;
        }

        [HttpGet("TestConnection")]
        public IActionResult TestConnection()
        {
            try
            {
                _logger.LogInformation("Testing database connection");
                return Ok(new ApiResponse
                {
                    Status = true,
                    Message = "API is working correctly",
                    Data = null
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error testing connection");
                return BadRequest(new ApiResponse
                {
                    Status = false,
                    Message = "Error: " + ex.Message,
                    Data = null
                });
            }
        }

        [HttpGet("GetAllUsers")]
        public async Task<IActionResult> Get()
        {
            try
            {
                var userList = await _userService.GetAllUsers();
                if (userList != null && userList.Any())
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "All users fetched successfully",
                        Data = userList,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = true, // Boş liste dönmek bir hata değil
                        Message = "No users found",
                        Data = new List<AppUserViewModel>(), // Boş liste dön
                    };
                    return Ok(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching all users");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching users: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> Get(int userId)
        {
            try
            {
                var user = await _userService.GetUserById(userId);
                if (user != null)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "User details fetched successfully", // Typo düzeltildi: "fected" -> "fetched"
                        Data = user,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "User details not found!",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error fetching user with ID {userId}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error fetching user: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpPost("CreateNewUser")]
        public async Task<IActionResult> Post(SaveAppUserViewModel userViewModel)
        {
            try
            {
                var userCreated = await _userService.CreateNewUser(userViewModel);
                if (userCreated)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "User Created Successfully!",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to create user details!",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error creating user: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        [HttpPut("{userId}")]
        public async Task<IActionResult> Put(int userId, SaveAppUserViewModel userViewModel)
        {
            try
            {
                var userUpdated = await _userService.updateUser(userId, userViewModel);
                if (userUpdated)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "User updated Successfully!",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Unable to update user details!",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating user with ID {userId}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error updating user: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        // Flutter uygulaması için ek endpoint
        [HttpPut("UpdateUser/{userId}")]
        public async Task<IActionResult> UpdateUser(int userId, SaveAppUserViewModel userViewModel)
        {
            return await Put(userId, userViewModel);
        }

        [HttpDelete("{userId}")]
        public async Task<IActionResult> Delete(int userId)
        {
            try
            {
                var userDeleted = await _userService.DeleteUser(userId);
                if (userDeleted)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "User deleted Successfully!",
                        Data = null,
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false, // Burada Status değeri false olmalı
                        Message = "Unable to delete user details!",
                        Data = null,
                    };
                    return BadRequest(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting user with ID {userId}");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Error deleting user: " + ex.Message,
                    Data = null,
                };
                return BadRequest(resp);
            }
        }

        // Flutter uygulaması için ek endpoint
        [HttpDelete("DeleteUser/{userId}")]
        public async Task<IActionResult> DeleteUser(int userId)
        {
            return await Delete(userId);
        }

        // Mevcut kullanıcı bilgilerini getir
        [HttpGet("GetCurrentUser")]
        public async Task<IActionResult> GetCurrentUser()
        {
            try
            {
                // Kullanıcı kimliğini al (JWT token'dan)
                var userId = GetUserIdFromToken();

                if (userId <= 0)
                {
                    return Unauthorized(new ApiResponse
                    {
                        Status = false,
                        Message = "Oturum açılmamış",
                        Data = null
                    });
                }

                var user = await _userService.GetUserById(userId);
                if (user != null)
                {
                    var resp = new ApiResponse
                    {
                        Status = true,
                        Message = "Kullanıcı bilgileri başarıyla alındı",
                        Data = user
                    };
                    return Ok(resp);
                }
                else
                {
                    var resp = new ApiResponse
                    {
                        Status = false,
                        Message = "Kullanıcı bilgileri bulunamadı",
                        Data = null
                    };
                    return NotFound(resp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kullanıcı bilgileri alınırken hata oluştu");
                var resp = new ApiResponse
                {
                    Status = false,
                    Message = "Hata: " + ex.Message,
                    Data = null
                };
                return BadRequest(resp);
            }
        }

        // JWT token'dan kullanıcı ID'sini al
        private int GetUserIdFromToken()
        {
            try
            {
                // Kullanıcı kimliğini al
                var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == "userId");
                if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
                {
                    return userId;
                }
                return 0;
            }
            catch
            {
                return 0;
            }
        }
    }
}
