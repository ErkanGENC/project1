using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FullstackWithFlutter.Migrations
{
    /// <inheritdoc />
    public partial class AddPasswordToDoctorTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Password",
                table: "doctors",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Password",
                table: "doctors");
        }
    }
}
