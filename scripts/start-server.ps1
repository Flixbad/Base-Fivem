#Requires -Version 5.1
<#
.SYNOPSIS
    Demarre FXServer / txAdmin pour la base locale.
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Fx = Join-Path $Root "server\FXServer.exe"
$Data = Join-Path $Root "server-data"

if (-not (Test-Path $Fx)) {
    Write-Host "FXServer.exe introuvable." -ForegroundColor Red
    Write-Host "Lance d'abord: .\scripts\download-artifacts.ps1" -ForegroundColor Yellow
    exit 1
}

New-Item -ItemType Directory -Force -Path $Data | Out-Null

Write-Host ""
Write-Host "=== Demarrage FXServer / txAdmin ===" -ForegroundColor Cyan
Write-Host ("Binaire : " + $Fx)
Write-Host ("Data    : " + $Data)
Write-Host ""
Write-Host "Au premier lancement:" -ForegroundColor Yellow
Write-Host "  1. Ouvre l'URL txAdmin affichee dans la console (souvent :40120)"
Write-Host "  2. Lie ton compte Cfx.re"
Write-Host "  3. Popular Recipes -> QBox Framework"
Write-Host ("  4. Pointe le dossier data vers: " + $Data)
Write-Host "  5. Remplis licence + MariaDB, lance la recipe"
Write-Host ""

Set-Location (Join-Path $Root "server")
& $Fx "+set" "txAdminPort" "40120"
