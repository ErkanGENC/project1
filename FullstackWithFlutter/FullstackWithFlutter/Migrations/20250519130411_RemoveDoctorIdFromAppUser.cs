using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FullstackWithFlutter.Migrations
{
    /// <inheritdoc />
    public partial class RemoveDoctorIdFromAppUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DoctorId",
                table: "appUsers");

            migrationBuilder.DropColumn(
                name: "DoctorName",
                table: "appUsers");

            migrationBuilder.DropColumn(
                name: "Specialization",
                table: "appUsers");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DoctorId",
                table: "appUsers",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DoctorName",
                table: "appUsers",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Specialization",
                table: "appUsers",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
