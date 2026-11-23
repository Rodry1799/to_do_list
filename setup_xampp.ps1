# ============================================================
#  setup_xampp.ps1
#  Copies PHP API files to XAMPP htdocs and creates DB/table
# ============================================================

$xamppHtdocs  = "C:\xampp\htdocs\to_do_list_APIs"
$phpSourceDir = "$PSScriptRoot\lib\to_do_list_APIs"
$mysqlBin     = "C:\xampp\mysql\bin\mysql.exe"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  To-Do List XAMPP Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Copy PHP files ──────────────────────────────────
Write-Host "[1/3] Copying PHP files to htdocs..." -ForegroundColor Yellow

if (-Not (Test-Path $phpSourceDir)) {
    Write-Host "  ERROR: Source folder not found: $phpSourceDir" -ForegroundColor Red
    exit 1
}

if (-Not (Test-Path $xamppHtdocs)) {
    New-Item -ItemType Directory -Path $xamppHtdocs | Out-Null
    Write-Host "  Created folder: $xamppHtdocs" -ForegroundColor Green
}

Copy-Item "$phpSourceDir\*.php" -Destination $xamppHtdocs -Force
Write-Host "  Done! Files copied to: $xamppHtdocs" -ForegroundColor Green

# ── Step 2: Create database and table ──────────────────────
Write-Host ""
Write-Host "[2/3] Creating MySQL database and table..." -ForegroundColor Yellow

if (-Not (Test-Path $mysqlBin)) {
    Write-Host "  WARNING: MySQL binary not found at $mysqlBin" -ForegroundColor Red
    Write-Host "  Please create the database manually (see instructions below)." -ForegroundColor Red
} else {
    $sqlFile = "c:\Users\HP\.dbclient\storage\1776802532655@@127.0.0.1@3306\create-db-template.sql"
    & $mysqlBin -u root --execute="source $sqlFile"
    Write-Host "  Database 'to_do_list_db' and tables are ready!" -ForegroundColor Green
}

# ── Step 3: Final instructions ──────────────────────────────
Write-Host ""
Write-Host "[3/3] Final Checklist" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Make sure the following are running in XAMPP Control Panel:" -ForegroundColor White
Write-Host "   [x] Apache  (port 80)" -ForegroundColor Green
Write-Host "   [x] MySQL   (port 3306)" -ForegroundColor Green
Write-Host ""
Write-Host "  Test your API by opening in browser:" -ForegroundColor White
Write-Host "   http://localhost/to_do_list_APIs/read.php" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Then run your Flutter app:" -ForegroundColor White
Write-Host "   flutter run -d chrome" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
