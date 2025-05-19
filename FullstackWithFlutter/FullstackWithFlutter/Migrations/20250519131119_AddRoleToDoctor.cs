using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FullstackWithFlutter.Migrations
{
    /// <inheritdoc />
    public partial class AddRoleToDoctor : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Role",
                table: "doctors",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Role",
                table: "doctors");
        }
    }
}
