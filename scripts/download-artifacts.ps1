#Requires -Version 5.1
<#
.SYNOPSIS
    Telecharge et extrait le plus recent artifact FXServer (Windows) dans ./server
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$ServerDir = Join-Path $Root "server"
$ArtifactsIndex = "https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/"
$TempDir = Join-Path $env:TEMP ("fivem-artifacts-" + (Get-Random))

Write-Host ""
Write-Host "=== Download artifacts FXServer ===" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $ServerDir, $TempDir | Out-Null

Write-Host "Lecture de l'index artifacts..." -ForegroundColor DarkGray
$page = Invoke-WebRequest -Uri $ArtifactsIndex -UseBasicParsing

$matches = [regex]::Matches($page.Content, 'href="\./([0-9]+)-([a-f0-9]+)/server\.7z"')
if ($matches.Count -eq 0) {
    $matches = [regex]::Matches($page.Content, 'href="([0-9]+)-([a-f0-9]+)/server\.7z"')
}

if ($matches.Count -eq 0) {
    throw "Impossible de trouver server.7z - telecharge manuellement depuis l'index artifacts."
}

$best = $null
$bestNum = -1
foreach ($m in $matches) {
    $num = [int]$m.Groups[1].Value
    if ($num -gt $bestNum) {
        $bestNum = $num
        $best = $m
    }
}

$relative = $best.Groups[1].Value + "-" + $best.Groups[2].Value + "/server.7z"
$downloadUrl = $ArtifactsIndex.TrimEnd('/') + '/' + $relative
$archivePath = Join-Path $TempDir "server.7z"

Write-Host ("Build selectionne: " + $bestNum + " (le plus recent)") -ForegroundColor Green
Write-Host ("URL: " + $downloadUrl) -ForegroundColor DarkGray
Write-Host "Telechargement en cours..." -ForegroundColor Yellow

Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing

$sevenZip = @(
    "${env:ProgramFiles}\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $sevenZip) {
    Write-Host ("7-Zip introuvable. Archive: " + $archivePath) -ForegroundColor Yellow
    Write-Host ("Extrais manuellement dans: " + $ServerDir) -ForegroundColor Yellow
    exit 1
}

Write-Host ("Extraction vers " + $ServerDir + " ...") -ForegroundColor Yellow
Get-ChildItem $ServerDir -Force | Where-Object { $_.Name -ne ".gitkeep" } | Remove-Item -Recurse -Force
& $sevenZip x $archivePath ("-o" + $ServerDir) -y | Out-Null

$fx = Join-Path $ServerDir "FXServer.exe"
if (-not (Test-Path $fx)) {
    throw ("Extraction OK mais FXServer.exe introuvable dans " + $ServerDir)
}

Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host ("Artifacts installes: " + $fx) -ForegroundColor Green
Write-Host "Lance: .\scripts\start-server.ps1" -ForegroundColor Cyan
Write-Host ""
