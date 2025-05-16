﻿namespace FullstackWithFlutter.Core.ViewModels
{
    public class ActivityViewModel
    {
        public int Id { get; set; }
        public string? Type { get; set; }
        public string? Description { get; set; }
        public int? UserId { get; set; }
        public string? UserName { get; set; }
        public DateTime CreatedDate { get; set; }
        public string? Details { get; set; }
        public string? Icon { get; set; }
        public string? Color { get; set; }
    }

    public class SaveActivityViewModel
    {
        public string? Type { get; set; }
        public string? Description { get; set; }
        public int? UserId { get; set; }
        public string? UserName { get; set; }
        public string? Details { get; set; }
        public string? Icon { get; set; }
        public string? Color { get; set; }
    }
}
