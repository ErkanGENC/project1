using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FullstackWithFlutter.Migrations
{
    /// <inheritdoc />
    public partial class AddPatientIdAndDoctorIdToAppointments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DoctorId",
                table: "appointments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "PatientId",
                table: "appointments",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DoctorId",
                table: "appointments");

            migrationBuilder.DropColumn(
                name: "PatientId",
                table: "appointments");
        }
    }
}
