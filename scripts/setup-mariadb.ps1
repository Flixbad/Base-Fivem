#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise MariaDB (data + service Windows) et cree la DB qbox.
    A lancer en Administrateur si le service n'existe pas encore.
#>
$ErrorActionPreference = "Stop"
$bin = "C:\Program Files\MariaDB 12.3\bin"
$data = "C:\Program Files\MariaDB 12.3\data"
$rootPass = "rootfivem"
$userPass = "change_me"

if (-not (Test-Path "$bin\mysqld.exe")) {
    throw "MariaDB introuvable dans Program Files. Installe MariaDB.Server via winget."
}

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Host "Elevation admin requise..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath
    ) -Wait
    exit $LASTEXITCODE
}

Write-Host "=== Setup MariaDB pour Qbox ===" -ForegroundColor Cyan

$svc = Get-Service MariaDB -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Host "Installation service + data dir..."
    if (-not (Test-Path "$data\mysql")) {
        & "$bin\mysql_install_db.exe" --datadir="$data" --service=MariaDB --password=$rootPass
    } else {
        & "$bin\mysqld.exe" --install MariaDB --datadir="$data"
    }
}

$svc = Get-Service MariaDB -ErrorAction SilentlyContinue
if (-not $svc) {
    throw "Service MariaDB non cree. Verifie les logs d'installation."
}

if ($svc.Status -ne "Running") {
    Start-Service MariaDB
    Start-Sleep 4
}

# Si le root n'a pas de mot de passe (install alternative)
$connected = $false
foreach ($args in @(
    @("-u", "root", "-p$rootPass"),
    @("-u", "root")
)) {
    try {
        & "$bin\mysql.exe" @args -e "SELECT 1;" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $mysqlArgs = $args
            $connected = $true
            break
        }
    } catch { }
}

if (-not $connected) {
    throw "Impossible de se connecter a MariaDB en root. Definis le mot de passe manuellement."
}

$sql = @"
CREATE DATABASE IF NOT EXISTS qbox CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'fivem'@'localhost' IDENTIFIED BY '$userPass';
GRANT ALL PRIVILEGES ON qbox.* TO 'fivem'@'localhost';
FLUSH PRIVILEGES;
SHOW DATABASES;
"@

& "$bin\mysql.exe" @mysqlArgs -e $sql

Write-Host ""
Write-Host "MariaDB OK." -ForegroundColor Green
Write-Host ("Root password: " + $rootPass)
Write-Host ("User fivem / DB qbox password: " + $userPass)
Write-Host "Connection string:"
Write-Host "mysql://fivem:change_me@127.0.0.1/qbox?charset=utf8mb4"
Write-Host ""
